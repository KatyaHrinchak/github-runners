variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "gh-ci"
}

variable "instance_types" {
  description = "EC2 instance types for runners"
  type        = list(string)
  default     = ["t3.small"]
}

variable "runner_extra_labels" {
  description = "Extra labels for the runner"
  type        = list(string)
  default     = ["aws", "linux", "x64"]
}
