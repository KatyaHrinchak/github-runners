# GitHub Runners

Terraform configurations for running ephemeral GitHub Actions self-hosted runners on AWS or Kubernetes.

## Projects

- AWS GitHub Runners - EC2-based runners managed by the `github-aws-runners` Terraform module. The stack includes a VPC, private subnets, Lambda webhook handling, Spot capacity, and OpenTelemetry.
- Kubernetes GitHub Runners - Actions Runner Controller and a runner scale set deployed to an existing Kubernetes cluster.
