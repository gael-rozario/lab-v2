locals {
  internal_domain = "${var.internal_subdomain}.${var.domain}"
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

data "cloudflare_zone" "this" {
  name = var.domain
}

# Wildcard DNS for internal services -> the pinned internal gateway IP.
# proxied=false because it's a private LAN address.
resource "cloudflare_record" "internal_wildcard" {
  zone_id = data.cloudflare_zone.this.id
  name    = "*.${var.internal_subdomain}"
  value   = var.internal_gateway_ip
  type    = "A"
  ttl     = 300
  proxied = false
}

resource "helm_release" "envoy_gateway" {
  name             = "eg"
  chart            = "oci://docker.io/envoyproxy/gateway-helm"
  version          = var.envoy_gateway_chart_version
  namespace        = var.envoy_gateway_namespace
  create_namespace = true
  wait             = true
  timeout          = 300
}

resource "null_resource" "wildcard_cert" {
  depends_on = [helm_release.envoy_gateway]

  triggers = {
    domain         = var.domain
    namespace      = var.envoy_gateway_namespace
    cluster_issuer = var.cluster_issuer
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE      = var.envoy_gateway_namespace
      DOMAIN         = var.domain
      CLUSTER_ISSUER = var.cluster_issuer
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: wildcard-tls
        namespace: $NAMESPACE
      spec:
        secretName: wildcard-tls
        issuerRef:
          name: $CLUSTER_ISSUER
          kind: ClusterIssuer
        dnsNames:
          - "$DOMAIN"
          - "*.$DOMAIN"
      EOF
    EOT
  }
}

resource "null_resource" "wait_for_wildcard_cert" {
  depends_on = [null_resource.wildcard_cert]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready certificate/wildcard-tls -n ${var.envoy_gateway_namespace} --timeout=300s"
  }
}

resource "null_resource" "gateway" {
  depends_on = [null_resource.wait_for_wildcard_cert]

  triggers = {
    namespace = var.envoy_gateway_namespace
    domain    = var.domain
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.envoy_gateway_namespace
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: gateway.networking.k8s.io/v1
      kind: GatewayClass
      metadata:
        name: eg
      spec:
        controllerName: gateway.envoyproxy.io/gatewayclass-controller
      ---
      apiVersion: gateway.networking.k8s.io/v1
      kind: Gateway
      metadata:
        name: eg
        namespace: $NAMESPACE
      spec:
        gatewayClassName: eg
        listeners:
          - name: http
            protocol: HTTP
            port: 80
            allowedRoutes:
              namespaces:
                from: All
          - name: https
            protocol: HTTPS
            port: 443
            tls:
              mode: Terminate
              certificateRefs:
                - name: wildcard-tls
                  namespace: $NAMESPACE
            allowedRoutes:
              namespaces:
                from: All
      EOF
    EOT
  }
}

# ---------------------------------------------------------------------------
# Internal gateway — a second Gateway on the same "eg" GatewayClass/controller
# for internal-only apps. Envoy Gateway gives it its own Envoy proxy +
# LoadBalancer service, so MetalLB auto-assigns it a separate IP.
# ---------------------------------------------------------------------------

# Wildcard TLS for *.int.<domain> — issued via Cloudflare DNS-01, so it works
# even though the internal hostnames resolve to a private MetalLB IP.
resource "null_resource" "internal_wildcard_cert" {
  depends_on = [helm_release.envoy_gateway]

  triggers = {
    domain         = local.internal_domain
    namespace      = var.envoy_gateway_namespace
    cluster_issuer = var.cluster_issuer
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE      = var.envoy_gateway_namespace
      DOMAIN         = local.internal_domain
      CLUSTER_ISSUER = var.cluster_issuer
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: wildcard-internal-tls
        namespace: $NAMESPACE
      spec:
        secretName: wildcard-internal-tls
        issuerRef:
          name: $CLUSTER_ISSUER
          kind: ClusterIssuer
        dnsNames:
          - "$DOMAIN"
          - "*.$DOMAIN"
      EOF
    EOT
  }
}

resource "null_resource" "wait_for_internal_wildcard_cert" {
  depends_on = [null_resource.internal_wildcard_cert]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready certificate/wildcard-internal-tls -n ${var.envoy_gateway_namespace} --timeout=300s"
  }
}

resource "null_resource" "internal_gateway" {
  depends_on = [null_resource.wait_for_internal_wildcard_cert, null_resource.gateway]

  triggers = {
    namespace = var.envoy_gateway_namespace
    domain    = local.internal_domain
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE           = var.envoy_gateway_namespace
      INTERNAL_GATEWAY_IP = var.internal_gateway_ip
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: gateway.envoyproxy.io/v1alpha1
      kind: EnvoyProxy
      metadata:
        name: eg-internal
        namespace: $NAMESPACE
      spec:
        provider:
          type: Kubernetes
          kubernetes:
            envoyService:
              annotations:
                metallb.universe.tf/loadBalancerIPs: "$INTERNAL_GATEWAY_IP"
      ---
      apiVersion: gateway.networking.k8s.io/v1
      kind: Gateway
      metadata:
        name: eg-internal
        namespace: $NAMESPACE
      spec:
        gatewayClassName: eg
        infrastructure:
          parametersRef:
            group: gateway.envoyproxy.io
            kind: EnvoyProxy
            name: eg-internal
        listeners:
          - name: http
            protocol: HTTP
            port: 80
            allowedRoutes:
              namespaces:
                from: All
          - name: https
            protocol: HTTPS
            port: 443
            tls:
              mode: Terminate
              certificateRefs:
                - name: wildcard-internal-tls
                  namespace: $NAMESPACE
            allowedRoutes:
              namespaces:
                from: All
      EOF
    EOT
  }
}
