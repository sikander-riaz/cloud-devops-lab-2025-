terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  # Comment this out initially, then uncomment after resources are created
  # backend "s3" {
  #   bucket         = "siku-tfstate-bucket-us-east-2"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-2"
  #   dynamodb_table = "tf_state_table"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
  # Remove or comment out the profile if not configured
  # profile = "tkxel"
}