variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "598dfb98-1228-47ff-8459-ec0d6192bb05"
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "East US" # Example default, override in tfvars if needed
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
  default     = "salthea-asp"
}

variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan (e.g., P1v2, S1, B1)"
  type        = string
  default     = "P1v2" # Example: Premium V2 Small
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
  default     = "salthea-kv" // Ensure this is globally unique or use a suffix
}

variable "key_vault_sku" {
  description = "SKU for the Key Vault (standard or premium)"
  type        = string
  default     = "standard"
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
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "saltheaacr123" // Set to the correct ACR name
}

variable "acr_sku" {
  description = "SKU for the Azure Container Registry (e.g., Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "log_analytics_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "salthea-logs"
}

variable "app_insights_name" {
  description = "Name of the Application Insights resource"
  type        = string
  default     = "salthea-appinsights"
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
  default     = "salthea-loganalytics"
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

/*
variable "clerk_secret_key" {
  description = "Clerk.dev secret key - DEPRECATED: use clerk_secret_key_value and supply via tfvars/env"
  type        = string
  sensitive   = true
  # default     = "sk_test_TH8Rg9enkDIEKer4SoUwf8q3P7Zwt21Mthop9nQDZo" # REMOVED - USE TFVARS
}
*/

/*
variable "clerk_publishable_key" {
  description = "Clerk.dev publishable key - DEPRECATED: use clerk_publishable_key_value and supply via tfvars/env"
  type        = string
  sensitive   = true
  # default     = "pk_test_bW92ZWQtamF2ZWxpbi0yNC5jbGVyay5hY2NvdW50cy5kZXYk" # REMOVED - USE TFVARS
}
*/

/*
variable "valyu_api_key" {
  description = "Valyu.network API key - DEPRECATED: use valyu_api_key_value (if created) and supply via tfvars/env"
  type        = string
  sensitive   = true
  # default     = "your-valyu-api-key" # REMOVED - USE TFVARS (Create a valyu_api_key_value if needed for KV)
}
*/

variable "openai_deployment_name" {
  description = "Azure OpenAI deployment name"
  type        = string
  default     = "salthea-gpt4o"
  sensitive   = true
}

variable "cors_allowed_origins" {
  description = "A list of allowed origins for CORS configuration."
  type        = list(string)
  default     = ["http://localhost:3000", "https://salthea-frontend.azurewebsites.net", "https://salthea-frontend-staging.azurewebsites.net"]
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
  default     = "StagingCosmosDbConnectionStringV2"
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

# TryTerra and Particle Health Variables
variable "particle_health_client_id" {
  description = "Client ID for Particle Health OAuth2"
  type        = string
  sensitive   = true
  default     = ""
}

variable "particle_health_client_secret" {
  description = "Client Secret for Particle Health OAuth2"
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

variable "clerk_secret_key_value" {
  description = "Clerk Secret Key actual value (sensitive)"
  type        = string
  sensitive   = true
  # No default, value should be provided via tfvars or environment
}

variable "clerk_publishable_key_value" {
  description = "Clerk Publishable Key actual value"
  type        = string
  sensitive   = true # It's a good idea to mark this sensitive too
  # No default, value should be provided via tfvars or environment
}

variable "openai_api_key_value" {
  description = "OpenAI API Key actual value (sensitive)"
  type        = string
  sensitive   = true
  # No default, value should be provided via tfvars or environment
}

variable "azure_openai_endpoint_value" {
  description = "Azure OpenAI Endpoint actual value"
  type        = string
  # No default, value should be provided via tfvars or environment
}

variable "azure_openai_deployment_value" {
  description = "Azure OpenAI Deployment ID/Name actual value"
  type        = string
  # No default, value should be provided via tfvars or environment
}

# We need a valyu_api_key_value if it's to be stored in Key Vault
# If it's not stored in Key Vault and used directly, the old var.valyu_api_key (now without default) will be prompted for.
# For consistency with Key Vault pattern:
variable "valyu_api_key_value" {
  description = "Valyu API Key actual value (sensitive) - for Key Vault storage"
  type        = string
  sensitive   = true
  # No default, value should be provided via tfvars or environment
}

variable "always_on_enabled" {
  description = "Flag to enable Always On for the App Service Plan. Recommended for production to avoid cold starts."
  type        = bool
  default     = true
}

variable "frontend_webapp_name" {
  description = "Name of the frontend web application"
  type        = string
  default     = "salthea-frontend"
}

variable "backend_api_webapp_name" {
  description = "Name of the backend API web application"
  type        = string
  default     = "salthea-backend-api"
}

variable "storage_account_name_for_logs" {
  description = "Name of the storage account for App Service logs. Must be globally unique."
  type        = string
  default     = "salthealogs" // Ensure uniqueness
}

variable "storage_account_tier_for_logs" {
  description = "Storage account tier for logs (e.g., Standard, Premium)."
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_for_logs" {
  description = "Storage account replication type for logs (e.g., LRS, GRS)."
  type        = string
  default     = "LRS"
}

variable "vnet_integration_subnet_id" {
  description = "The subnet ID for VNet integration for the App Services."
  type        = string
  default     = null # Set to a valid subnet ID if VNet integration is required
} 