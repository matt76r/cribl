variable "cribl_client_id" {
  description = "Cribl Cloud client ID"
  type        = string
  sensitive   = true
}

variable "cribl_client_secret" {
  description = "Cribl Cloud client secret"
  type        = string
  sensitive   = true
}

variable "cribl_auth_url" {
  description = "Cribl Cloud OAuth2 token endpoint"
  type        = string
  default     = "https://login.cribl.cloud/oauth/token"
}
