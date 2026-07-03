locals {
  grafana_host = "${var.grafana_host_prefix}.${var.internal_subdomain}.${var.domain}"
}

# Prometheus + Grafana (+ operator, node-exporter, kube-state-metrics).
# Alertmanager disabled (no alerting yet). serviceMonitorSelectorNil...=false so
# Prometheus discovers ServiceMonitors from ALL namespaces (dcgm, litellm).
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kps_chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = false
  timeout          = 600

  values = [<<-YAML
    alertmanager:
      enabled: false

    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
        podMonitorSelectorNilUsesHelmValues: false
        ruleSelectorNilUsesHelmValues: false
        retention: 15d
        # Durable storage so the TSDB survives reschedule onto worker2/3.
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: ${var.storage_class}
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: ${var.prometheus_storage_size}

    grafana:
      adminPassword: ${var.grafana_admin_password}
      # Persist dashboards/state across reschedule (no GPU node, so PVC on Longhorn).
      persistence:
        enabled: true
        type: pvc
        storageClassName: ${var.storage_class}
        accessModes: ["ReadWriteOnce"]
        size: ${var.grafana_storage_size}
      # RWO Longhorn volume can only attach to one node — Recreate kills the old
      # pod (releasing the volume) before the new one starts, avoiding the
      # Multi-Attach deadlock a RollingUpdate causes when the pod moves nodes.
      deploymentStrategy:
        type: Recreate
      service:
        type: ClusterIP
      ingress:
        enabled: false
      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
            - name: default
              orgId: 1
              type: file
              disableDeletion: false
              editable: true
              options:
                path: /var/lib/grafana/dashboards/default
      dashboards:
        default:
          nvidia-dcgm:
            gnetId: ${var.dcgm_dashboard_gnet_id}
            revision: ${var.dcgm_dashboard_revision}
            datasource: Prometheus
  YAML
  ]
}

# NVIDIA DCGM exporter — GPU metrics, pinned to the GPU node, runs under the
# nvidia runtime, and ships a ServiceMonitor for Prometheus to scrape.
resource "helm_release" "dcgm_exporter" {
  depends_on = [helm_release.kube_prometheus_stack]

  name             = "dcgm-exporter"
  repository       = "https://nvidia.github.io/dcgm-exporter/helm-charts"
  chart            = "dcgm-exporter"
  version          = var.dcgm_chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = false
  timeout          = 300

  values = [<<-YAML
    runtimeClassName: ${var.runtime_class}
    nodeSelector:
      ${var.gpu_node_label}: "true"
    # DCGM scrapes the GPU, so it must run ON the tainted GPU node.
    tolerations:
      - key: ${var.gpu_taint.key}
        operator: Equal
        value: ${var.gpu_taint.value}
        effect: ${var.gpu_taint.effect}
    serviceMonitor:
      enabled: true
  YAML
  ]
}

# Scrape LiteLLM's /metrics (token usage, latency, errors per model/key).
# Lives here because this module installs the prometheus-operator (ServiceMonitor CRD).
resource "null_resource" "litellm_servicemonitor" {
  depends_on = [helm_release.kube_prometheus_stack]

  triggers = {
    namespace = var.namespace
    path      = "/metrics/"
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.namespace
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: monitoring.coreos.com/v1
      kind: ServiceMonitor
      metadata:
        name: litellm
        namespace: $NAMESPACE
      spec:
        namespaceSelector:
          matchNames:
            - litellm
        selector:
          matchLabels:
            app: litellm
        endpoints:
          - port: http
            path: /metrics/
            interval: 30s
      EOF
    EOT
  }
}

# LiteLLM Grafana dashboard — a ConfigMap labeled grafana_dashboard=1, which the
# kube-prometheus-stack Grafana sidecar auto-imports.
resource "null_resource" "litellm_dashboard" {
  depends_on = [helm_release.kube_prometheus_stack]

  triggers = {
    namespace = var.namespace
    dashboard = filemd5("${path.module}/dashboards/litellm.json")
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.namespace
    }
    command = <<-EOT
      kubectl create configmap litellm-dashboard -n "$NAMESPACE" \
        --from-file=litellm.json=${path.module}/dashboards/litellm.json \
        --dry-run=client -o yaml | kubectl apply -f -
      kubectl -n "$NAMESPACE" label configmap litellm-dashboard grafana_dashboard=1 --overwrite
    EOT
  }
}

# Expose Grafana on the internal gateway.
resource "null_resource" "grafana_route" {
  depends_on = [helm_release.kube_prometheus_stack]

  triggers = {
    namespace = var.namespace
    host      = local.grafana_host
    gateway   = "${var.gateway_namespace}/${var.gateway_name}"
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.namespace
      HOST      = local.grafana_host
      GW_NAME   = var.gateway_name
      GW_NS     = var.gateway_namespace
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: grafana
        namespace: $NAMESPACE
      spec:
        parentRefs:
          - name: $GW_NAME
            namespace: $GW_NS
        hostnames:
          - "$HOST"
        rules:
          - matches:
              - path:
                  type: PathPrefix
                  value: /
            backendRefs:
              - name: kube-prometheus-stack-grafana
                port: 80
      EOF
    EOT
  }
}
