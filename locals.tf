locals {
  common_tags = {
    Owner       = var.owner
    Project     = var.project_prefix
    Environment = var.environment
  }
}
