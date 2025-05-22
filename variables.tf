variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "598dfb98-1228-47ff-8459-ec0d6192bb05"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central US"
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name used in resource naming and tags"
  type        = string
  default     = "salthea"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "salthea-rg"
}

variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
  default     = "salthea-backend-api"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "salthea-app-plan"
}

variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "S1" # Changed from B1 to S1 to support deployment slots
}

variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
  default     = "salthea-vnet"
}

variable "vnet_address_space" {
  description = "Virtual Network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "backend_subnet_name" {
  description = "Backend subnet name"
  type        = string
  default     = "backend-subnet"
}

variable "backend_subnet_address_prefix" {
  description = "The address prefix for the backend subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_endpoints_subnet_address_prefix" {
  description = "The address prefix for the private endpoints subnet."
  type        = string
  default     = "10.0.2.0/24" # Ensure this doesn't overlap with other subnets
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
  default     = "salthea-kv"
}

variable "cosmos_account_name" {
  description = "Cosmos DB account name"
  type        = string
  default     = "salthea-cosmos"
}

variable "cosmos_db_name" {
  description = "Cosmos DB database name"
  type        = string
  default     = "salthea-database"
}

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
  default     = "saltheastorage123"
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
  default     = "saltheaacr123"
}

variable "log_analytics_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "salthea-logs"
}

variable "app_insights_name" {
  description = "Application Insights name"
  type        = string
  default     = "salthea-insights"
}

variable "openai_name" {
  description = "Azure OpenAI resource name"
  type        = string
  default     = "salthea-openai"
}

variable "openai_location" {
  description = "Azure OpenAI resource location"
  type        = string
  default     = "East US" # Adjust based on availability
}

variable "ip_allowlist" {
  description = "List of IP addresses to allow access"
  type        = list(string)
  default     = []  # Changed from ["YOUR_IP_ADDRESS"] to allow all IPs for development
}

variable "clerk_secret_key" {
  description = "Clerk.dev secret key"
  type        = string
  default     = "sk_test_TH8Rg9enkDIEKer4SoUwf8q3P7Zwt21Mthop9nQDZo" # Replace with your actual Clerk secret key
  sensitive   = true
}

variable "clerk_publishable_key" {
  description = "Clerk.dev publishable key"
  type        = string
  default     = "pk_test_bW92ZWQtamF2ZWxpbi0yNC5jbGVyay5hY2NvdW50cy5kZXYk" # Replace with your actual Clerk publishable key
  sensitive   = true
}

variable "valyu_api_key" {
  description = "Valyu.network API key"
  type        = string
  default     = "your-valyu-api-key" # Replace with your actual Valyu API key
  sensitive   = true
}

variable "openai_deployment_name" {
  description = "Azure OpenAI deployment name"
  type        = string
  default     = "salthea-gpt4o"
  sensitive   = true
}

variable "sentry_dsn" {
  description = "Sentry DSN for error tracking"
  type        = string
  default     = "your-sentry-dsn" # Replace with your actual Sentry DSN
  sensitive   = true
}

variable "cors_allowed_origins" {
  description = "List of origins to allow CORS from"
  type        = list(string)
  default     = ["https://salthea.com", "https://www.salthea.com", "http://localhost:3000"]
}

variable "hipaa_compliant" {
  description = "Flag to indicate if resources should be HIPAA compliant"
  type        = bool
  default     = false # Default to false, override in tfvars if needed
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "cosmos_throughput" {
  description = "Throughput for Cosmos DB database"
  type        = number
  default     = 400
}

variable "staging_cosmos_db_connection_string_secret_name" {
  description = "The name of the Key Vault secret for the staging Cosmos DB connection string."
  type        = string
  default     = "StagingCosmosDbConnectionString"
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    environment = "production" # Or use var.environment if you prefer
    project     = "salthea"      # Or use var.project_name if you prefer
  }
}

variable "alert_notification_email" {
  description = "Email address for alert notifications."
  type        = string
  default     = "support@cerebrallabs.io"
}

# FHIR Service Variables
variable "fhir_service_name" {
  description = "Name of the Azure API for FHIR service"
  type        = string
  default     = "salthea-fhir"
}

variable "fhir_service_kind" {
  description = "Kind of FHIR service (fhir-R4, fhir-Stu3)"
  type        = string
  default     = "fhir-R4"
}

# OneRecord and TryTerra Variables
variable "onerecord_client_id" {
  description = "Client ID for OneRecord OAuth"
  type        = string
  sensitive   = true
  default     = ""
}

variable "onerecord_client_secret" {
  description = "Client Secret for OneRecord OAuth"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tryterra_dev_id" {
  description = "Developer ID for TryTerra API"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tryterra_api_key" {
  description = "API Key for TryTerra API"
  type        = string
  sensitive   = true
  default     = ""
}

variable "backend_production_image_tag" {
  description = "The specific Docker image tag to use for the backend production slot."
  type        = string
  default     = "specify-in-tfvars-or-pipeline" # Placeholder, ensure this is set to a valid image tag before apply
} 