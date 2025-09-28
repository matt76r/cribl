terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

# Generate OAuth2 token for Cribl Cloud
data "http" "cribl_token" {
  url    = var.cribl_auth_url
  method = "POST"
  
  request_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
  }
  
  request_body = "grant_type=client_credentials&client_id=${var.cribl_client_id}&client_secret=${var.cribl_client_secret}"
  
  lifecycle {
    postcondition {
      condition     = contains([200, 201], self.status_code)
      error_message = "Failed to obtain OAuth2 token from Cribl Cloud"
    }
  }
}

locals {
  token_response = jsondecode(data.http.cribl_token.response_body)
}

output "access_token" {
  description = "OAuth2 access token for Cribl Cloud"
  value       = local.token_response.access_token
  sensitive   = true
}

output "token_type" {
  description = "Token type (usually Bearer)"
  value       = local.token_response.token_type
}
