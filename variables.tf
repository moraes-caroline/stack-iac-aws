#---------------------- Default Tags ---------------------#
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Managed_By             = "Terraform"
    Project                = ""
    Centro_Custo           = ""
    Owner                  = ""
    Domain                 = ""
    Sub_Domain             = ""
    Acronym                = ""
  }
}
 
#--------------------- AWS Environment -------------------#
variable "environment" {
  description = "Environment (e.g., dev, hmg, prod)"
  type        = string
}

variable "aws_account_id" {
  type = string
}
 
variable "region" {
  type        = string
  description = "AWS region"
}

 variable "bucket" {
  description = "Configuração de um bucket S3"
  type = object({
    bucket_name                      = string
    environment                      = string
    versioning_enabled               = bool
    mfa_delete_enabled               = bool
    encryption_type                  = optional(string)
    kms_key_id                       = optional(string)
    block_public_acls                = bool
    block_public_policy              = bool
    ignore_public_acls               = bool
    restrict_public_buckets          = bool
    lifecycle_enabled                = bool
    transition_to_ia_days            = number
    transition_to_glacier_days       = number
    expiration_days                  = number
    logging_enabled                  = bool
    log_bucket                       = string
    log_prefix                       = string
    aws_region                       = string
    s3_bucket_website_enabled        = bool
    s3_bucket_website_index_document = string
    s3_bucket_website_error_document = string

    enable_vpc_endpoint          = optional(bool, false)
    vpc_endpoint_vpc_id          = optional(string)
    vpc_endpoint_type            = optional(string)
    vpc_endpoint_route_table_ids = optional(list(string), [])
  })
}

#------------------------ IAM Roles ----------------------#
 
variable "iam_roles" {
  type = map(object({
    name                         = string
    description                  = optional(string)
    enable_appconfig_policy      = optional(bool)
    enable_secretsmanager_policy = optional(bool)
    enable_kms_policy            = optional(bool)
    enable_s3_policy             = optional(bool)
    enable_postgresql_policy     = optional(bool)
    appconfig_resource_arns      = optional(list(string), [])
    secretsmanager_resource_arns = optional(list(string), [])
    kms_resource_arns            = optional(list(string), [])
    s3_resource_arns             = optional(list(string), [])
    iam_managed_policy_arns      = optional(list(string), [])
    rdspostgresql_resource_arns  = optional(list(string), [])
    openshift_namespace          = optional(string)
    openshift_service_account    = optional(string)
  }))
}
 
variable "iam_managed_policy_arns" {
  type    = list(string)
  default = []
}
 
variable "role_to_assume" {
  type    = string
  default = ""
}
 
 
#------------------------ AppConfig ----------------------#
 
variable "github_token" {
  description = "GitHub Personal Access Token for accessing private repositories."
  type        = string
  sensitive   = true
  default     = ""
}
 
variable "appconfig_applications" {
  description = "Map of AppConfig applications with their services and configurations"
  type = map(object({
    name        = string
    description = string
    environment = string
    deployment_strategy = object({
      name                           = string
      deployment_duration_in_minutes = number
      growth_factor                  = number
      final_bake_time_in_minutes     = number
      replicate_to                   = string
    })
    services = map(object({
      profile_name        = string
      profile_description = string
      location_uri        = string
      type                = string
      content_type        = string
      github_repo         = string
      github_branch       = string
      github_file_path    = string
      github_env_name     = string
      github_variant      = string
      github_secret_name  = string
    }))
  }))
}
 
 
#---------------------- Habilitar / Desabilitar a criação das variaveis do appconfig -------#
variable "enable_github_variables" {
  description = "Se true, cria variáveis de environment no GitHub. Se false, não cria nada."
  type        = bool
  default     = false
}
 