variable "project_name" {
  description = "Project name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "log_name" {
  description = "Log type name (e.g., application, security, audit, api, database)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.log_name))
    error_message = "Log name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "destination_name" {
  description = "Destination name (e.g., s3, cribl, elasticsearch, splunk)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.destination_name))
    error_message = "Destination name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "buffer_size" {
  description = "Buffer size in MB (1-5)"
  type        = number
  default     = 5
  validation {
    condition     = var.buffer_size >= 1 && var.buffer_size <= 5
    error_message = "Buffer size must be between 1 and 5 MB."
  }
}

variable "buffer_interval" {
  description = "Buffer interval in seconds (60-900)"
  type        = number
  default     = 300
  validation {
    condition     = var.buffer_interval >= 60 && var.buffer_interval <= 900
    error_message = "Buffer interval must be between 60 and 900 seconds."
  }
}

variable "compression_format" {
  description = "Compression format for S3"
  type        = string
  default     = "GZIP"
  validation {
    condition     = contains(["UNCOMPRESSED", "GZIP", "ZIP", "Snappy", "HADOOP_SNAPPY"], var.compression_format)
    error_message = "Compression format must be one of: UNCOMPRESSED, GZIP, ZIP, Snappy, HADOOP_SNAPPY."
  }
}

variable "s3_prefix" {
  description = "S3 key prefix with timestamp partitioning"
  type        = string
  default     = "year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
}

variable "error_output_prefix" {
  description = "S3 error output prefix"
  type        = string
  default     = "errors/"
}

variable "cribl_endpoint_url" {
  description = "Cribl Cloud HTTP endpoint URL (optional)"
  type        = string
  default     = ""
}

variable "cribl_client_id" {
  description = "Cribl Cloud client ID for OAuth2 authentication (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cribl_client_secret" {
  description = "Cribl Cloud client secret for OAuth2 authentication (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_cloudwatch_logging" {
  description = "Enable CloudWatch logging for Firehose"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
