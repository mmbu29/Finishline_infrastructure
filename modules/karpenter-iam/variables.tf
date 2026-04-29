variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN for the EKS cluster"
}

variable "oidc_provider_url" {
  type        = string
  description = "OIDC provider URL (issuer)"
}

variable "oidc_sub_key" {
  type        = string
  description = "The rendered OIDC sub key string (URL:sub)"
}

variable "oidc_aud_key" {
  type        = string
  description = "The rendered OIDC aud key string (URL:aud)"
}