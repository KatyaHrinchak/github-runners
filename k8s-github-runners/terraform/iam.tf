resource "aws_iam_role" "otel" {
  name = "task-eks-arc-otel"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"

      Principal = {
        Federated = data.aws_iam_openid_connect_provider.eks.arn
      }

      Condition = {
        StringEquals = {
          "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:arc-systems:otel-arc"
          "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "otel" {
  name = "cloudwatch-metrics"
  role = aws_iam_role.otel.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "cloudwatch:PutMetricData"
      Resource = "*"
    }]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

resource "aws_iam_role" "image_build" {
  name = "github-actions-arc-image"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }

      Action = "sts:AssumeRoleWithWebIdentity"

      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:KatyaHrinchak/k8s-github-runners:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "image_build" {
  name = "github-actions-arc-image"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = data.aws_ecr_repository.runner.arn
      },
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "image_build" {
  role       = aws_iam_role.image_build.name
  policy_arn = aws_iam_policy.image_build.arn
}

resource "aws_iam_role" "terraform" {
  name = "github-actions-arc-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"

      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }

      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"

          "token.actions.githubusercontent.com:sub" = [
            "repo:KatyaHrinchak/github-runners:ref:refs/heads/main",
            "repo:KatyaHrinchak/github-runners:environment:terraform-apply"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "terraform" {
  name = "arc-terraform"
  role = aws_iam_role.terraform.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Terraform backend bucket
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::terraform-backend-815756779189"

        Condition = {
          StringEquals = {
            "s3:prefix" = [
              "k8s-github-runners/eks/terraform.tfstate",
              "k8s-github-runners/eks/terraform.tfstate.tflock"
            ]
          }
        }
      },

      # Terraform state
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::terraform-backend-815756779189/k8s-github-runners/eks/terraform.tfstate"
      },

      # Terraform state locking
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::terraform-backend-815756779189/k8s-github-runners/eks/terraform.tfstate.tflock"
      },

      # GitHub App credentials
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:us-east-1:815756779189:parameter/gh-ci/github-app/id",
          "arn:aws:ssm:us-east-1:815756779189:parameter/gh-ci/github-app/installation-id",
          "arn:aws:ssm:us-east-1:815756779189:parameter/gh-ci/github-app/key-base64"
        ]
      },

      # Read EKS connection details
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = "arn:aws:eks:us-east-1:815756779189:cluster/task-eks-cluster"
      },

      # Manage EKS access entries and policy associations
      {
        Effect = "Allow"
        Action = [
          "eks:CreateAccessEntry",
          "eks:DescribeAccessEntry",
          "eks:UpdateAccessEntry",
          "eks:DeleteAccessEntry",
          "eks:AssociateAccessPolicy",
          "eks:DisassociateAccessPolicy",
          "eks:ListAssociatedAccessPolicies",
          "eks:TagResource",
          "eks:UntagResource",
          "eks:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:eks:us-east-1:815756779189:cluster/task-eks-cluster",
          "arn:aws:eks:us-east-1:815756779189:access-entry/task-eks-cluster/*"
        ]
      },

      # Read GitHub and EKS OIDC providers
      {
        Effect = "Allow"
        Action = "iam:GetOpenIDConnectProvider"
        Resource = [
          "arn:aws:iam::815756779189:oidc-provider/token.actions.githubusercontent.com",
          "arn:aws:iam::815756779189:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/*"
        ]
      },

      # Manage OTel and GitHub Actions roles and inline policies
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:DeleteRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::815756779189:role/task-eks-arc-otel",
          "arn:aws:iam::815756779189:role/github-actions-arc-image",
          "arn:aws:iam::815756779189:role/github-actions-arc-terraform"
        ]
      },

      # Read the existing runner image repository
      {
        Effect   = "Allow"
        Action   = "ecr:DescribeRepositories"
        Resource = "arn:aws:ecr:us-east-1:815756779189:repository/arc-runner-set"
      },

      # Manage the ARC dashboard
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetDashboard",
          "cloudwatch:PutDashboard",
          "cloudwatch:DeleteDashboards"
        ]
        Resource = "arn:aws:cloudwatch::815756779189:dashboard/arc-runners-eks"
      }
    ]
  })
}

resource "aws_eks_access_entry" "terraform" {
  cluster_name  = "task-eks-cluster"
  principal_arn = aws_iam_role.terraform.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "terraform" {
  cluster_name  = aws_eks_access_entry.terraform.cluster_name
  principal_arn = aws_eks_access_entry.terraform.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
