output "image_build_role_arn" {
  value = aws_iam_role.image_build.arn
}

output "terraform_role_arn" {
  value = aws_iam_role.terraform.arn
}
