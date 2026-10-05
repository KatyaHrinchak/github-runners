output "webhook_endpoint" {
  value = module.github_runner.webhook.endpoint
}

output "webhook_secret_ssm" {
  value = module.github_runner.ssm_parameters.webhook_secret.name
}
