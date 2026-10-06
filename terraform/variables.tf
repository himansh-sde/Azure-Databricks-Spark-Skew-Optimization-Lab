# ==========================================
# Base Configuration
# ==========================================
variable "project_name" {
  description = "Base name for the project resources"
  type        = string
  default     = "sparkoptlab"
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure Region for deployment"
  type        = string
  default     = "Central India"
}

variable "tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "Spark-Skew-Optimization"
    ManagedBy   = "Terraform"
    Owner       = "Data-Engineering"
  }
}

# ==========================================
# Storage Configuration
# ==========================================
variable "adls_containers" {
  description = "List of containers to create in ADLS Gen2"
  type        = list(string)
  default     = ["lab-data", "bronze", "silver", "gold"]
}

# ==========================================
# Databricks Compute Configuration
# ==========================================
variable "cluster_name" {
  description = "Name of the Databricks cluster"
  type        = string
  default     = "skew-optimization-cluster"
}

variable "spark_version" {
  description = "Databricks Runtime version for the cluster"
  type        = string
  default     = "14.3.x-scala2.12" # LTS Version
}

variable "node_type" {
  description = "Azure VM size for the Databricks nodes"
  type        = string
  default     = "Standard_D2s_v3" # Mid-sized node, perfect for forcing disk spills
}

variable "min_workers" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1 # 1 worker (2 cores) + 1 driver (2 cores) = 4 cores total
}

variable "max_workers" {
  description = "Maximum number of worker nodes (Autoscaling limit)"
  type        = number
  default     = 1 # Disable scaling to prevent hitting the quota mid-job
}

variable "auto_termination_minutes" {
  description = "Minutes of inactivity before cluster shuts down to save costs"
  type        = number
  default     = 60
}

# ==========================================
# Security & IAM Configuration
# ==========================================
# These variables will be passed via environment variables (TF_VAR_sp_client_id) 
# in GitHub Actions, keeping secrets out of your code.

variable "sp_client_id" {
  description = "Service Principal Client ID for ADLS access"
  type        = string
  sensitive   = true
  default     = "" 
}

variable "sp_client_secret" {
  description = "Service Principal Client Secret for ADLS access"
  type        = string
  sensitive   = true
  default     = ""
}
