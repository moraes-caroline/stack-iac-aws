#----------------------- General -----------------------#
environment              = "dev"
region                   = "sa-east-1"
aws_account_id           = ""
 
#----------------------- S3 Bucket ----------------------#
buckets = {
  privado = {
    bucket_name                      = "bucket-aws"
    environment                      = "dev"
    versioning_enabled               = false
    mfa_delete_enabled               = false
    encryption_type                  = null
    kms_key_id                       = null
    block_public_acls                = true
    block_public_policy              = true
    ignore_public_acls               = true
    restrict_public_buckets          = true
    s3_bucket_website_enabled        = false
    s3_bucket_website_index_document = ""
    s3_bucket_website_error_document = ""
    lifecycle_enabled                = false
    transition_to_ia_days            = 30
    transition_to_glacier_days       = 90
    expiration_days                  = 365
    logging_enabled                  = false
    log_bucket                       = ""
    log_prefix                       = ""
    aws_region                       = "sa-east-1"
    enable_vpc_endpoint              = false
    vpc_endpoint_vpc_id              = "vpc-02393fda03cd3db38"#
    vpc_endpoint_type                = "Gateway"
    vpc_endpoint_route_table_ids     = ["rtb-06ad808bcc2321e60"]#
  }
}
 
#------------------------- KMS Key ----------------------#
 
kms_key_enabled                  = true
kms_key_deletion_window_in_days  = 7
kms_key_enable_key_rotation      = true
kms_key_rotation_period_in_days  = 365
kms_key_policy                   = null
kms_key_is_enabled               = true
kms_key_description              = "KMS key for Stack app1 - DEV environment"
kms_key_key_usage                = "ENCRYPT_DECRYPT"
kms_key_customer_master_key_spec = "SYMMETRIC_DEFAULT"
kms_key_multi_region             = false
kms_key_alias_name               = "alias/" #
 
#----------------------- Secrets Manager ----------------#
secrets_manager = {
  "sm-app1" = {
    secretsmanager_secret_name               = "sm-dev-br-001"#
    secretsmanager_description               = "Secret"#
    secretsmanager_kms_key_id                = ""
    secret_version_secret_string             = "" 
    secret_rotation_enable_rotation          = false
    secret_rotation_automatically_after_days = 30
    iam_role_lambda_name                     = "lambda-secretsmanager-app1-dev-br"#
    lambda_function_name                     = "secretsmanager-app1-dev-br-001"#
    lambda_function_runtime                  = "python3.11"
    lambda_function_handler                  = "lambda_function.lambda_handler"#
 
    iam_role_lambda_assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    EOF
 
    iam_policy_lambda_name   = "lambda-secretsmanager-app1-dev-br"
    iam_policy_lambda_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "secretsmanager:GetSecretValue",
            "secretsmanager:PutSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:UpdateSecretVersionStage"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "*"
        }
      ]
    }
    EOF
  }
}
 
#----------------------- IAM Roles -----------------------#
iam_roles = {
  "haf-dev-assinaturahsm" = {
    name                         = "iam-haf-assinaturahsm-api-dev-br-001"#
    description                  = "IAM Role for HAF DEV"
    enable_appconfig_policy      = true
    enable_secretsmanager_policy = true
    enable_kms_policy            = false
    enable_s3_policy             = false
    enable_postgresql_policy     = true
    appconfig_resource_arns      = ["arn:aws:appconfig:sa-east-1:887194768853:application/*/environment/*/configuration/*"]
    secretsmanager_resource_arns = ["arn:aws:secretsmanager:sa-east-1:887194768853:secret:*"]
    kms_resource_arns            = ["*"]
    s3_resource_arns             = ["*"]
    rdspostgresql_resource_arns  = ["arn:aws:rds-db:sa-east-1:887194768853:dbuser:db-RMMZXNO4POHCK4LHXN4PUXE2F4/app_assinaturahsm"]
    iam_managed_policy_arns      = []
    openshift_namespace          = "haf-ns1-d"
    openshift_service_account    = "aws-appconfig-sa"
  }
}
#----------------------- AppConfig ----------------------#
enable_github_variables = false
 
appconfig_applications = {
  "app1" = {
    name        = "app1-dev"
    description = "Configuração da aplicação app1 (dev)"
    environment = "dev"
 
    deployment_strategy = {
      name                           = "deployment-app1-dev"
      deployment_duration_in_minutes = 1
      growth_factor                  = 25
      final_bake_time_in_minutes     = 0
      replicate_to                   = "NONE"
    }
 
    services = {
      "app1-ser" = {
        profile_name        = "app1-dev"
        profile_description = "AppConfig profile for app1 (dev)"
        location_uri        = "hosted"
        type                = "AWS.Freeform"
        content_type        = "application/json"
        github_repo         = "application1"
        github_branch       = "develop"
        github_file_path    = "config/appsettings.api.dev.json"
        github_env_name     = "dev"
        github_variant      = "APP1"
        github_secret_name  = "sm-app1-dev-br-001"
      }
    }
  }
}
