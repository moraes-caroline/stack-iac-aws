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

#----------------------- S3 Bucket ----------------------#
 
locals {
  expanded = merge([
    for key, bucket in var.buckets : {
      for b in bucket.bucket_name :
      "${key}-${b}" => merge(bucket, { bucket_name = b })
    }
  ]...)
}
 
module "aws_s3_bucket" {
  source = "git::https://github.com/moraes-caroline/iac-modules.git//aws/aws-s3bucket?ref=main"
 
  for_each                         = local.expanded
  bucket_name                      = each.value.bucket_name
  environment                      = each.value.environment
  versioning_enabled               = contains(local.buckets_with_object_lock, each.value.bucket_name) ? true : each.value.versioning_enabled
  mfa_delete_enabled               = each.value.mfa_delete_enabled
  encryption_type                  = each.value.encryption_type
  kms_key_id                       = each.value.kms_key_id
  block_public_acls                = each.value.block_public_acls
  block_public_policy              = each.value.block_public_policy
  ignore_public_acls               = each.value.ignore_public_acls
  restrict_public_buckets          = each.value.restrict_public_buckets
  lifecycle_enabled                = each.value.lifecycle_enabled
  transition_to_ia_days            = each.value.transition_to_ia_days
  transition_to_glacier_days       = each.value.transition_to_glacier_days
  expiration_days                  = each.value.expiration_days
  logging_enabled                  = each.value.logging_enabled
  log_bucket                       = each.value.log_bucket
  log_prefix                       = each.value.log_prefix
  s3_bucket_website_index_document = each.value.s3_bucket_website_index_document
  s3_bucket_website_error_document = each.value.s3_bucket_website_error_document
  s3_bucket_website_enabled        = each.value.s3_bucket_website_enabled
  enable_vpc_endpoint              = each.value.enable_vpc_endpoint
  vpc_endpoint_vpc_id              = each.value.vpc_endpoint_vpc_id
  vpc_endpoint_type                = each.value.vpc_endpoint_type
  vpc_endpoint_route_table_ids     = each.value.vpc_endpoint_route_table_ids
  region                           = var.region
  tags                             = each.value.tags
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
  source = "git::https://github.com/moraes-caroline/iac-modules.git//aws/aws-iamroles?ref=main"
  for_each = var.iam_roles
 
  environment = var.environment
 
  iam_role_name        = each.value.name
  iam_role_description = each.value.description
 
  # Gerar assume role policy dinamicamente
  iam_role_assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAssumeRoleWithRosa",
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${var.aws_account_id}:oidc-provider/${var.oidc_provider_identifier}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${var.oidc_provider_identifier}:aud" : "sts.amazonaws.com",
            "${var.oidc_provider_identifier}:sub" : "system:serviceaccount:${each.value.openshift_namespace}:${each.value.openshift_service_account}"
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