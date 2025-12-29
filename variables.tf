# 1. Virginia (Primary) Variables
variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "va_vpc_cidr" {
  description = "CIDR block for Virginia VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "va_azs" {
  description = "Availability Zones for Virginia"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1c"]
}

variable "va_public_subnets" {
  description = "Public Subnet CIDRs for Virginia"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "va_private_subnets" {
  description = "Private Subnet CIDRs for Virginia"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}
