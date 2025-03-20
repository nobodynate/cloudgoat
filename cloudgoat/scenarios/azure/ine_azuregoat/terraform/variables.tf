variable "subscription_id" {
    description = "The Azure subscription ID to use."
    type = string
}

variable "region" {
    description = "The Azure region to deploy resources to."
    default = "westus"
}

variable "cgid" {
    description = "CGID variable for unique naming."
    type = string
}

variable "cg_whitelist" {
    description = "User's public IP address, pulled from the file ../whitelist.txt."
    type = list(any)
}

variable "resource_group" {
  default = "azuregoat_app"
}

locals {
  now = timestamp()
  sasExpiry = timeadd(local.now, "240h")
  date_now = formatdate("YYYY-MM-DD", local.now)
  date_br = formatdate("YYYY-MM-DD", local.sasExpiry)
}
