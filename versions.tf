terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"

      configuration_aliases = [
        aws,
        aws.route53,
        aws.us-east-1,
      ]
    }
  }
  required_version = ">= 1.1.0"
}
