terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  runner_version = "v7.0.0"
}

module "download_lambda" {
  source  = "github-aws-runners/github-runner/aws//modules/download-lambda"
  version = "~> 7.0"

  lambdas = [
    {
      name = "webhook"
      tag  = local.runner_version
    },
    {
      name = "runners"
      tag  = local.runner_version
    },
    {
      name = "runner-binaries-syncer"
      tag  = local.runner_version
    }
  ]
}
