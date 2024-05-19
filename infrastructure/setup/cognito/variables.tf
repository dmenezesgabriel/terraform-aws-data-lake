variable "region" {
  description = "AWS region"
  type        = string
}

variable "identity_provider_callback_urls" {
  type        = list(any)
  description = "List of allowed callback URLs for the identity providers"
  default     = ["http://localhost:8501"]
}

variable "default_callback_url" {
  type        = string
  description = "The default callback URL for identity providers"
  default     = "http://localhost:8501"
}
