data "aws_ssm_parameter" "github_app_id" {
  name            = "/gh-ci/github-app/id"
  with_decryption = true
}

data "aws_ssm_parameter" "github_app_key" {
  name            = "/gh-ci/github-app/key-base64"
  with_decryption = true
}

data "aws_ssm_parameter" "github_app_installation_id" {
  name = "/gh-ci/github-app/installation-id"
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.arc.identity[0].oidc[0].issuer
}

data "aws_ecr_repository" "runner" {
  name = "arc-runner-set"
}
