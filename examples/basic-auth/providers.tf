terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
