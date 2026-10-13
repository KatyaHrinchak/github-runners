# resource "aws_ecr_repository" "repositories" {
#   name = "arc-runner-set"
# }

# resource "aws_ecr_lifecycle_policy" "repositories" {
#   repository = aws_ecr_repository.repositories.name

#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Delete all old images if more than 5 exist"
#         selection = {
#           tagStatus   = "any"
#           countType   = "imageCountMoreThan"
#           countNumber = 5
#         }
#         action = { type = "expire" }
#       }
#     ]
#   })
# }
