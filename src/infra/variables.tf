variable "location" {
  type        = string
  description = "Azure Region"
  default     = "West Europe"
}

variable "resource_group" {
  type        = string
  description = "Azure Resource Group"
  default     = "default-resource-group"
}

locals {
  default_tags = {
    Project     = "AKS with TF via ADO Sample"
    Toolkit     = "Terraform"
  }
}