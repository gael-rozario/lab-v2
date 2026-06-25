resource "null_resource" "arc_rbac" {
  depends_on = [helm_release.arc_controller]

  triggers = {
    namespace = var.arc_namespace
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.arc_namespace
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: arc-gha-rs-controller-rbac-manager
      rules:
        - apiGroups: ["rbac.authorization.k8s.io"]
          resources: ["roles", "rolebindings"]
          verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
      ---
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRoleBinding
      metadata:
        name: arc-gha-rs-controller-rbac-manager
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: ClusterRole
        name: arc-gha-rs-controller-rbac-manager
      subjects:
        - kind: ServiceAccount
          name: arc-gha-rs-controller
          namespace: $NAMESPACE
      EOF
    EOT
  }
}

resource "null_resource" "arc_vso_resources" {
  triggers = {
    namespace = var.arc_namespace
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.arc_namespace
    }
    command = <<-EOT
      kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: arc
        namespace: $NAMESPACE
      ---
      apiVersion: secrets.hashicorp.com/v1beta1
      kind: VaultAuth
      metadata:
        name: arc
        namespace: $NAMESPACE
      spec:
        method: kubernetes
        mount: kubernetes
        kubernetes:
          role: arc
          serviceAccount: arc
      ---
      apiVersion: secrets.hashicorp.com/v1beta1
      kind: VaultStaticSecret
      metadata:
        name: arc-github
        namespace: $NAMESPACE
      spec:
        type: kv-v2
        mount: ${var.vault_secret_mount}
        path: ${var.vault_secret_path}
        destination:
          name: arc-github-secret
          create: true
        vaultAuthRef: arc
      EOF
    EOT
  }
}

resource "null_resource" "wait_for_arc_secret" {
  depends_on = [null_resource.arc_vso_resources]

  provisioner "local-exec" {
    command = "until kubectl get secret arc-github-secret -n ${var.arc_namespace} 2>/dev/null; do sleep 5; done"
  }
}

resource "null_resource" "arc_deploy_rbac" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl create namespace portfolio --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f - <<EOF
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: arc-deployer
        namespace: portfolio
      rules:
        - apiGroups: ["", "apps"]
          resources: ["deployments", "services", "pods", "replicasets", "serviceaccounts", "secrets"]
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
        - apiGroups: ["gateway.networking.k8s.io"]
          resources: ["httproutes"]
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
      ---
      apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: arc-deployer
        namespace: portfolio
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: Role
        name: arc-deployer
      subjects:
        - kind: ServiceAccount
          name: arc-runner-portfolio-gha-rs-no-permission
          namespace: ${var.arc_namespace}
      EOF
    EOT
  }
}

resource "null_resource" "arc_blog_deploy_rbac" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl create namespace blog --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f - <<EOF
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: arc-deployer
        namespace: blog
      rules:
        - apiGroups: ["", "apps"]
          resources: ["deployments", "services", "pods", "replicasets", "serviceaccounts", "secrets"]
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
        - apiGroups: ["gateway.networking.k8s.io"]
          resources: ["httproutes"]
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
      ---
      apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: arc-deployer
        namespace: blog
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: Role
        name: arc-deployer
      subjects:
        - kind: ServiceAccount
          name: arc-runner-blog-gha-rs-no-permission
          namespace: ${var.arc_namespace}
      EOF
    EOT
  }
}

resource "helm_release" "arc_controller" {
  depends_on = [null_resource.wait_for_arc_secret]

  name             = "arc"
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set-controller"
  version          = var.arc_controller_chart_version
  namespace        = var.arc_namespace
  create_namespace = true
  wait             = true
  timeout          = 300
}

resource "helm_release" "arc_runner" {
  for_each = var.repos

  depends_on = [helm_release.arc_controller]

  name             = "arc-runner-${each.key}"
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set"
  version          = var.arc_runner_chart_version
  namespace        = var.arc_namespace
  create_namespace = true
  wait             = true
  timeout          = 300

  values = [<<-YAML
    githubConfigUrl: ${each.value}
    githubConfigSecret: arc-github-secret
    minRunners: ${var.min_runners}
    maxRunners: ${var.max_runners}
    controllerServiceAccount:
      namespace: ${var.arc_namespace}
      name: arc-gha-runner-scale-set-controller
    containerMode:
      type: dind
  YAML
  ]
}
