resource "kubernetes_namespace_v1" "arc_runners" {
  metadata {
    name = "arc-runners"
  }
}

resource "kubernetes_secret_v1" "github_auth" {
  metadata {
    name      = "github-auth"
    namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
  }

  type = "Opaque"
  data = {
    github_app_id              = data.aws_ssm_parameter.github_app_id.value
    github_app_installation_id = data.aws_ssm_parameter.github_app_installation_id.value
    github_app_private_key     = base64decode(data.aws_ssm_parameter.github_app_key.value)
  }
}

resource "helm_release" "arc" {
  name             = "arc"
  namespace        = "arc-systems"
  create_namespace = true

  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = var.arc_version

  values = [
    yamlencode({
      metrics = {
        controllerManagerAddr = ":8080"
        listenerAddr          = ":8080"
        listenerEndpoint      = "/metrics"
      }

      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "8080"
        "prometheus.io/path"   = "/metrics"
      }
    })
  ]
}

resource "helm_release" "arc_runner_set" {
  name      = "arc-runner-set"
  namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name

  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = var.arc_version

  values = [
    yamlencode({
      githubConfigUrl    = var.github_config_url
      githubConfigSecret = kubernetes_secret_v1.github_auth.metadata[0].name

      runnerScaleSetName = "arc-runner-set"

      containerMode = { type = "dind" }

      template = {
        spec = {
          nodeSelector = {
            "kubernetes.io/arch" = "amd64"
          }

          containers = [{
            name = "runner"

            image = "815756779189.dkr.ecr.us-east-1.amazonaws.com/arc-runner-set:2.0.0"

            imagePullPolicy = "IfNotPresent"
            command         = ["/home/runner/run.sh"]
          }]
        }
      }

      listenerTemplate = {
        metadata = {
          annotations = {
            "prometheus.io/scrape" = "true"
            "prometheus.io/port"   = "8080"
            "prometheus.io/path"   = "/metrics"
          }
        }

        spec = {
          containers = [
            {
              name = "listener"
            }
          ]
        }
      }

      minRunners = var.min_runners
      maxRunners = var.max_runners
    })
  ]

  depends_on = [helm_release.arc]
}
