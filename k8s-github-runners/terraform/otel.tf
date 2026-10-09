data "aws_iam_instance_profile" "k8s" {
  name = "k8s-ec2-instance-profile"
}

resource "aws_iam_role_policy" "otel" {
  name = "arc-otel-cloudwatch"
  role = data.aws_iam_instance_profile.k8s.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "cloudwatch:PutMetricData"
      Resource = "*"
    }]
  })
}

resource "kubernetes_role_v1" "otel" {
  metadata {
    name      = "otel-arc"
    namespace = helm_release.arc.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [helm_release.arc]
}

resource "kubernetes_role_binding_v1" "otel" {
  metadata {
    name      = "otel-arc"
    namespace = helm_release.arc.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.otel.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "otel-arc"
    namespace = helm_release.arc.namespace
  }
}

resource "helm_release" "otel" {
  name       = "otel-arc"
  namespace  = helm_release.arc.namespace
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.175.0"

  values = [
    yamlencode({
      mode        = "deployment"
      hostNetwork = true
      dnsPolicy   = "ClusterFirstWithHostNet"

      image = {
        repository = "ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib"
        tag        = "0.161.0"
      }

      command = {
        name = "otelcol-contrib"
      }

      serviceAccount = {
        create = true
        name   = "otel-arc"
      }

      service = {
        enabled = false
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          memory = "256Mi"
        }
      }

      config = {
        receivers = {
          otlp   = null
          jaeger = null
          zipkin = null

          prometheus = {
            config = {
              scrape_configs = [{
                job_name        = "arc"
                scrape_interval = "30s"

                kubernetes_sd_configs = [{
                  role = "pod"

                  namespaces = {
                    names = [helm_release.arc.namespace]
                  }
                }]

                relabel_configs = [
                  {
                    source_labels = [
                      "__meta_kubernetes_pod_annotation_prometheus_io_scrape"
                    ]
                    action = "keep"
                    regex  = "true"
                  },
                  {
                    source_labels = ["__meta_kubernetes_pod_phase"]
                    action        = "keep"
                    regex         = "Running"
                  },
                  {
                    source_labels = [
                      "__meta_kubernetes_pod_annotation_prometheus_io_path"
                    ]
                    target_label = "__metrics_path__"
                    regex        = "(.+)"
                  },
                  {
                    source_labels = [
                      "__meta_kubernetes_pod_ip",
                      "__meta_kubernetes_pod_annotation_prometheus_io_port"
                    ]
                    target_label = "__address__"
                    regex        = "(.+);([0-9]+)"
                    replacement  = "$$1:$$2"
                  }
                ]

                metric_relabel_configs = [{
                  source_labels = ["__name__"]
                  action        = "keep"
                  regex         = "gha_.*"
                }]
              }]
            }
          }
        }

        processors = {
          memory_limiter = {
            check_interval         = "5s"
            limit_percentage       = 75
            spike_limit_percentage = 20
          }

          batch = {
            timeout             = "10s"
            send_batch_size     = 200
            send_batch_max_size = 200
          }
        }

        exporters = {
          debug = null

          "otlphttp/cloudwatch" = {
            metrics_endpoint = "https://monitoring.us-east-1.amazonaws.com/v1/metrics"

            auth = {
              authenticator = "sigv4auth"
            }
          }
        }

        extensions = {
          health_check = {
            endpoint = "0.0.0.0:13133"
          }

          sigv4auth = {
            region  = "us-east-1"
            service = "monitoring"
          }
        }

        service = {
          extensions = ["health_check", "sigv4auth"]

          pipelines = {
            logs   = null
            traces = null

            metrics = {
              receivers  = ["prometheus"]
              processors = ["memory_limiter", "batch"]
              exporters  = ["otlphttp/cloudwatch"]
            }
          }
        }
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy.otel,
    kubernetes_role_binding_v1.otel
  ]
}
