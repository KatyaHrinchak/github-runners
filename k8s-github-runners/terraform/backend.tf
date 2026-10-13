terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }

  backend "s3" {
    bucket = "terraform-backend-815756779189"
    key    = "k8s-github-runners/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_eks_cluster" "arc" {
  name = "task-eks-cluster"
}

provider "kubernetes" {
  host = data.aws_eks_cluster.arc.endpoint

  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.arc.certificate_authority[0].data
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", data.aws_eks_cluster.arc.name,
      "--region", "us-east-1"
    ]
  }
}

provider "helm" {
  kubernetes = {
    host = data.aws_eks_cluster.arc.endpoint

    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.arc.certificate_authority[0].data
    )

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", data.aws_eks_cluster.arc.name,
        "--region", "us-east-1"
      ]
    }
  }
}
