terraform {
 
  backend "s3" {
  }
 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
 
provider "aws" {
  region = "sa-east-1"
}
 
provider "github" {
  token = var.github_token != "" ? var.github_token : null
  owner = "moraes-caroline"
}