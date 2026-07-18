locals {
  vault_hostname = "vault.${var.domain}"
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

data "cloudflare_zone" "this" {
  name = var.domain
}

resource "cloudflare_record" "vault" {
  zone_id = data.cloudflare_zone.this.id
  name    = "vault"
  value   = var.vault_ip
  type    = "A"
  ttl     = 300
  proxied = false
}

resource "null_resource" "vault_certificate" {
  triggers = {
    namespace      = var.vault_namespace
    hostname       = local.vault_hostname
    cluster_issuer = var.cluster_issuer
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE      = var.vault_namespace
      HOSTNAME       = local.vault_hostname
      CLUSTER_ISSUER = var.cluster_issuer
    }
    command = <<-EOT
      kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f - <<EOF
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: vault-tls
        namespace: $NAMESPACE
      spec:
        secretName: vault-tls
        issuerRef:
          name: $CLUSTER_ISSUER
          kind: ClusterIssuer
        dnsNames:
          - "$HOSTNAME"
      EOF
    EOT
  }
}

resource "null_resource" "wait_for_vault_cert" {
  depends_on = [null_resource.vault_certificate]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready certificate/vault-tls -n ${var.vault_namespace} --timeout=300s"
  }
}

resource "helm_release" "vault" {
  depends_on = [null_resource.wait_for_vault_cert]

  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = var.vault_chart_version
  namespace        = var.vault_namespace
  create_namespace = true
  wait             = false
  timeout          = 300

  values = [<<-YAML
    global:
      enabled: true
      tlsDisable: false

    server:
      # Pod anti-affinity (chart default) keeps replicas off each other's
      # nodes. With only 4 nodes and master now tainted by default, the 3rd
      # replica has nowhere left to go unless it can use the GPU worker.
      tolerations:
        - key: dedicated
          operator: Equal
          value: ai
          effect: NoSchedule

      ha:
        enabled: true
        replicas: ${var.replica_count}
        raft:
          enabled: true
          setNodeId: true
          config: |
            ui = true

            listener "tcp" {
              tls_disable     = 0
              address         = "[::]:8200"
              cluster_address = "[::]:8201"
              tls_cert_file   = "/vault/userconfig/vault-tls/tls.crt"
              tls_key_file    = "/vault/userconfig/vault-tls/tls.key"
              tls_min_version = "tls12"
            }

            storage "raft" {
              path = "/vault/data"

              retry_join {
                leader_api_addr       = "https://vault-0.vault-internal:8200"
                leader_tls_servername = "${local.vault_hostname}"
              }
              retry_join {
                leader_api_addr       = "https://vault-1.vault-internal:8200"
                leader_tls_servername = "${local.vault_hostname}"
              }
              retry_join {
                leader_api_addr       = "https://vault-2.vault-internal:8200"
                leader_tls_servername = "${local.vault_hostname}"
              }
            }

            service_registration "kubernetes" {}

      extraEnvironmentVars:
        VAULT_ADDR: https://vault.${var.domain}

      volumes:
        - name: vault-tls
          secret:
            secretName: vault-tls

      volumeMounts:
        - name: vault-tls
          mountPath: /vault/userconfig/vault-tls
          readOnly: true

      dataStorage:
        enabled: true
        size: ${var.storage_size}
        storageClass: longhorn

      service:
        type: LoadBalancer
        port: 443
        targetPort: 8200
        annotations:
          metallb.universe.tf/loadBalancerIPs: "${var.vault_ip}"

    ui:
      enabled: true
      serviceType: ClusterIP
  YAML
  ]
}
