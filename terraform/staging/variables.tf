variable "ecr_image" {
  type        = string
  description = "ECR image URI with tag (e.g., ecs-node-app:prod)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

