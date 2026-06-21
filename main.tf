#------------------------- Data Sources -----------------------#
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
 
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
 
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:us-east-1:123456789012:secret:meu-segredo-*"
    ]
  }
}
module "aws_s3_bucket" {
  source = "git::https://github.com/moraes-caroline/iac-modules.git//aws/aws-s3bucket?ref=main"

  bucket_name                      = var.bucket.bucket_name
  environment                      = var.bucket.environment
  versioning_enabled               = var.bucket.versioning_enabled
  mfa_delete_enabled               = var.bucket.mfa_delete_enabled
  encryption_type                  = var.bucket.encryption_type
  kms_key_id                       = var.bucket.kms_key_id
  block_public_acls                = var.bucket.block_public_acls
  block_public_policy              = var.bucket.block_public_policy
  ignore_public_acls               = var.bucket.ignore_public_acls
  restrict_public_buckets          = var.bucket.restrict_public_buckets
  lifecycle_enabled                = var.bucket.lifecycle_enabled
  transition_to_ia_days            = var.bucket.transition_to_ia_days
  transition_to_glacier_days       = var.bucket.transition_to_glacier_days
  expiration_days                  = var.bucket.expiration_days
  logging_enabled                  = var.bucket.logging_enabled
  log_bucket                       = var.bucket.log_bucket
  log_prefix                       = var.bucket.log_prefix
  s3_bucket_website_index_document = var.bucket.s3_bucket_website_index_document
  s3_bucket_website_error_document = var.bucket.s3_bucket_website_error_document
  s3_bucket_website_enabled        = var.bucket.s3_bucket_website_enabled
  enable_vpc_endpoint              = var.bucket.enable_vpc_endpoint
  vpc_endpoint_vpc_id              = var.bucket.vpc_endpoint_vpc_id
  vpc_endpoint_type                = var.bucket.vpc_endpoint_type
  vpc_endpoint_route_table_ids     = var.bucket.vpc_endpoint_route_table_ids
  region                           = var.region
  tags                             = var.tags
}

#------------------------ ECR -----------------------#
 
 module "ecr" {
  source = "git::https://github.com/moraes-caroline/iac-modules.git//aws/aws-ecr?ref=main"

  repository_name = "flask-app"

  tags = {
    Environment = "dev"
  }
}
#------------------------ ECS -----------------------#
module "ecs" {
    source = "git::https://github.com/moraes-caroline/iac-modules.git//aws/aws-ecs?ref=main"


  cluster_name    = "flask-cluster"
  service_name    = "flask-app"
  container_image = "524558748007.dkr.ecr.sa-east-1.amazonaws.com/flask-app:latest"

  tags = {
    Environment = "dev"
  }
}
#------------------------ AppConfig -----------------------#
module "aws_appconfig" {
  source = "git::https://github.com/moraes-caroline/iac-modules.git//aws/aws-appconfig?ref=main"
 
  enable_github_variables = var.enable_github_variables
  github_token            = var.github_token
  appconfig_applications  = var.appconfig_applications
  tags                    = var.tags
}

#---------------------- IAM Roles (Multiple per Application) -----------------------#
module "iam_roles" {
  source = "git::https://github.com/moraes-caroline/iac-modules.git//aws/aws-iamrole?ref=main"
  for_each = var.iam_roles
 
  environment = var.environment
 
  iam_role_name        = each.value.name
  iam_role_description = each.value.description
  
  github_token            = var.github_token
  appconfig_applications  = var.appconfig_applications
  enable_github_variables = var.enable_github_variables

 
  # Gerar assume role policy dinamicamente
  iam_role_assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAssumeRoleWithGitHub",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.aws_account_id}:oidc-provider/${var.oidc_provider_identifier}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${var.oidc_provider_identifier}:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "${var.oidc_provider_identifier}:sub": "repo:moraes-caroline/application1:*"
        }
      }
    }
  ]
})
 
  # Políticas pré-definidas
  enable_appconfig_policy      = each.value.enable_appconfig_policy
  enable_secretsmanager_policy = each.value.enable_secretsmanager_policy
  #enable_kms_policy            = each.value.enable_kms_policy
  enable_s3_policy         = each.value.enable_s3_policy
  enable_postgresql_policy = each.value.enable_postgresql_policy
 
  # ARNs específicos dos recursos
  appconfig_resource_arns      = each.value.appconfig_resource_arns
  secretsmanager_resource_arns = each.value.secretsmanager_resource_arns
  #kms_resource_arns            = each.value.kms_resource_arns
  s3_resource_arns            = each.value.s3_resource_arns
  rdspostgresql_resource_arns = each.value.rdspostgresql_resource_arns
 
  # Políticas AWS gerenciadas adicionais (Qualquer uma existente na AWS)
  iam_managed_policy_arns = lookup(each.value, "iam_managed_policy_arns", [])
 
}