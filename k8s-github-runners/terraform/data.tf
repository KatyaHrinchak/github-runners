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
