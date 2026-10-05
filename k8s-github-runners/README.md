# Kubernetes GitHub Runners

Terraform code to install Actions Runner Controller (ARC) and a runner scale set in an existing Kubernetes cluster.

The cluster and network are created separately using [self-managed-k8s](https://github.com/KatyaHrinchak/self-managed-k8s). This project only manages ARC and its GitHub authentication Secret.

## Requirements

- Terraform and access to the Kubernetes cluster.
- AWS access to the GitHub App credentials in SSM.
- A GitHub App installed on the target repository.

## Configuration

Set the kubeconfig path, context, repository URL, and GitHub App installation ID in `terraform.tfvars`.

The App ID and Base64-encoded private key are read from SSM:

- `/gh-ci/github-app/id`
- `/gh-ci/github-app/key-base64`

## Deploy

```bash
terraform init
terraform plan
terraform apply
```

## Test

Use this target in your GitHub Actions workflow:

```yaml
runs-on: arc-runner-set
```

Watch runner pods:

```bash
kubectl get pods -n arc-runners -w
```

Runners are created when jobs start and removed after completion. The default configuration allows up to three runners.

## Remove

```bash
terraform destroy
```

This removes ARC resources managed by this project. The cluster and network remain.