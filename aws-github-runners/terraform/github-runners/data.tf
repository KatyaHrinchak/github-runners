data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "terraform-backend-815756779189"
    key    = "network/aws-github-runners/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ssm_parameter" "github_app_id" {
  name            = "/gh-ci/github-app/id"
  with_decryption = true
}

data "aws_ssm_parameter" "github_app_key_base64" {
  name            = "/gh-ci/github-app/key-base64"
  with_decryption = true
}

data "aws_ssm_parameter" "github_app_webhook_secret" {
  name            = "/gh-ci/github-app/webhook-secret"
  with_decryption = true
}
