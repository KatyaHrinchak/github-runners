packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.8.1"
    }
  }
}

source "amazon-ebs" "github_runner" {
  region        = "us-east-1"
  instance_type = "t3.small"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  ssh_username = "ec2-user"
  ami_name     = "github-runner-otel-{{timestamp}}"

  tags = {
    Name    = "github-runner-otel"
    Project = "gh-ci"
  }
}

build {
  sources = ["source.amazon-ebs.github_runner"]

  provisioner "file" {
    source      = "otel-config.yaml"
    destination = "/tmp/otel-config.yaml"
  }

  provisioner "shell" {
    script = "setup.sh"
  }
}