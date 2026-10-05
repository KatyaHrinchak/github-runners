terraform {
  backend "s3" {
    bucket = "terraform-backend-815756779189"
    key    = "network/aws-github-runners/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
