variable "github_config_url" {
  type    = string
  default = "https://github.com/KatyaHrinchak/otel-splunk-task"
}

variable "kubeconfig_path" {
  type    = string
  default = "/Users/khrync/.kube/config-ec2"
}

variable "kubeconfig_context" {
  type    = string
  default = "kubernetes-admin@kubernetes"
}

variable "min_runners" {
  type    = number
  default = 0
}

variable "max_runners" {
  type    = number
  default = 3
}

variable "arc_version" {
  type    = string
  default = "0.15.0"
}
