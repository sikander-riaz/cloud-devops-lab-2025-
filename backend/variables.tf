variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "AmiLinux" {
  description = "AMI IDs for Linux instances by region"
  type        = map(string)
  default = {
    us-east-1 = "ami-0e95a5e2743ec9ec9"
    us-east-2 = "ami-0cfde0ea8edd312d4"
    us-west-1 = "ami-09456542751abbd92"
    us-west-2 = "ami-0bbc328167dee8f3c"
    eu-west-1 = "ami-06ce611e9f0dba763"
  }
}

variable "ssh_key" {
  description = "SSH private key filename"
  type        = string
  default     = "auth"
}

variable "name" {
  description = "Name for IAM role"
  type        = string
  default     = "ec2-role"
}

variable "log_group_name" {
  description = "The name of the CloudWatch log group"
  type        = string
  default     = "sikander-log-group"
}

variable "retention_days" {
  description = "The number of days to retain the logs in the CloudWatch log group"
  type        = number
  default     = 7
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "us-east-2a"
}