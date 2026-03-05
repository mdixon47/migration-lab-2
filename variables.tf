variable "aws_region" {
  type        = string
  description = "AWS region for the lab"
  default     = "us-east-2"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name Terraform should use"
  default     = "Test_user"
}

variable "project_prefix" {
  type        = string
  description = "Prefix for naming resources"
  default     = "migration-lab-2"
}

variable "environment" {
  type        = string
  description = "Environment tag value"
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Owner tag value"
  default     = "Parris"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

# ALB requires subnets in at least 2 AZs. :contentReference[oaicite:3]{index=3}
variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnets for ALB (must be 2 in different AZs for internet-facing ALB)"
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "public_subnet_azs" {
  type        = list(string)
  description = "AZs for public subnets (must be 2 different AZs)"
  default     = ["us-east-2a", "us-east-2b"]
}

variable "private_subnet_cidr" {
  type        = string
  description = "Private subnet CIDR block (server lives here)"
  default     = "10.0.2.0/24"
}

variable "private_subnet_az" {
  type        = string
  description = "AZ for the private subnet (single AZ for the server)"
  default     = "us-east-2a"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the source server"
  default     = "t3.micro"
}

variable "health_check_path" {
  type        = string
  description = "ALB target group health check path"
  default     = "/health"
}
