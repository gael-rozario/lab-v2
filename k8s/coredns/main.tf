# Replaces k3s's built-in coredns Addon (disabled via --disable coredns in
# infra/kube-master/main.tf) with an IaC-managed release that tolerates the
# control-plane taint and runs replicas spread across nodes, so a single
# node failure — master or worker — doesn't take out cluster DNS.
#
# Apply only after the old k3s-Addon-owned coredns Deployment/Service/
# ConfigMap/ServiceAccount/ClusterRole(Binding) are deleted from kube-system
# — Helm can't adopt resources it didn't create, and this chart reuses the
# same names (coredns / kube-dns) k3s used.
resource "helm_release" "coredns" {
  name             = "coredns"
  repository       = "https://coredns.github.io/helm"
  chart            = "coredns"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false
  wait             = true
  timeout          = 300

  values = [<<-YAML
    replicaCount: ${var.replica_count}

    # Adopt the legacy "k8s-app: kube-dns" selector label so this matches
    # what kubelet/other tooling expect from a kube-dns install.
    k8sAppLabelOverride: "kube-dns"

    service:
      name: "kube-dns"
      # Must match kubelet's --cluster-dns on every node exactly, or every
      # pod's /etc/resolv.conf points at a dead IP.
      clusterIP: "${var.cluster_dns_ip}"

    serviceAccount:
      create: true

    # Untainted by default in k3s (unlike kubeadm) — master carries an
    # explicit NoSchedule taint (infra/kube-master/main.tf) that CoreDNS
    # must tolerate to remain eligible there.
    tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule

    # Hard-require replicas land on different nodes so it takes master AND
    # a worker (or two different workers) failing together to lose DNS,
    # not any single node.
    topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: coredns
            app.kubernetes.io/instance: coredns
        topologyKey: kubernetes.io/hostname
        maxSkew: 1
        whenUnsatisfiable: DoNotSchedule
  YAML
  ]
}
