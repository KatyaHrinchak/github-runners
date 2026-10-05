# AWS GitHub Runners

Terraform code to deploy ephemeral GitHub Actions self-hosted runners on EC2 Spot instances in a private VPC.

The project creates the network, downloads the runner Lambda packages, and deploys the `github-aws-runners` module with a GitHub App. Runner logs are sent through OpenTelemetry and CloudWatch.

## Requirements

- Terraform, Packer, and AWS credentials with permission to create the required resources.
- An S3 Terraform backend configured for the network state.
- A GitHub App installed on the target repository.
- GitHub App values stored in AWS SSM Parameter Store:
	- `/gh-ci/github-app/id`
	- `/gh-ci/github-app/key-base64`
	- `/gh-ci/github-app/webhook-secret`

## Build the AMI

The runner uses an Amazon Linux AMI with OpenTelemetry installed:

```bash
cd packer
packer init .
packer build github-runner.pkr.hcl
```

Set the AMI name or filter in `terraform/github-runners/main.tf` to the AMI that was built before deploying the runners.

## Deploy

Create the network first, then download the Lambda artifacts and deploy the runners:

```bash
cd terraform/network
terraform init
terraform apply

cd ../download-lambda
terraform init
terraform apply

cd ../github-runners
terraform init
terraform plan
terraform apply
```

## Test

Use the default runner labels in a GitHub Actions workflow:

```yaml
runs-on: [self-hosted, aws, linux, x64]
```

Runners are created for jobs and removed after completion. The default capacity uses `t3.small` Spot instances.

## Remove

Destroy the runner resources, Lambda artifacts, and network separately:

```bash
cd terraform/github-runners && terraform destroy
cd ../download-lambda && terraform destroy
cd ../network && terraform destroy
```
