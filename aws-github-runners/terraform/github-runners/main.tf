locals {
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  private_subnets = data.terraform_remote_state.network.outputs.private_subnets
  runner_version  = "v7.11.0"
}

resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

module "download_lambda" {
  source  = "github-aws-runners/github-runner/aws//modules/download-lambda"
  version = "v7.11.0"

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

module "github_runner" {
  source  = "github-aws-runners/github-runner/aws"
  version = "v7.11.0"

  aws_region = "us-east-1"
  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  prefix = var.prefix

  github_app = {
    key_base64     = data.aws_ssm_parameter.github_app_key_base64.value
    id             = data.aws_ssm_parameter.github_app_id.value
    webhook_secret = data.aws_ssm_parameter.github_app_webhook_secret.value
  }

  webhook_lambda_zip                = "${path.module}/../download-lambda/webhook.zip"
  runners_lambda_zip                = "${path.module}/../download-lambda/runners.zip"
  runner_binaries_syncer_lambda_zip = "${path.module}/../download-lambda/runner-binaries-syncer.zip"

  enable_ephemeral_runners                = true
  scale_up_reserved_concurrent_executions = -1

  instance_types                = var.instance_types
  instance_target_capacity_type = "spot"

  ami = {
    filter = {
      name  = ["github-runner-otel-1790755551"]
      state = ["available"]
    }
    owners = ["self"]
  }

  enable_runner_on_demand_failover_for_errors = ["InsufficientInstanceCapacity"]
  runner_extra_labels                         = var.runner_extra_labels
  enable_ssm_on_runners                       = true

  logging_retention_in_days = 3
  log_level                 = "info"

  runner_iam_role_managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
}
