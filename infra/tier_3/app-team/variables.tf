variable "tags" {
  type = map
  default = {
    environment = "demo"
    source      = "microsoft"
  }
}


variable "id-name" {}
variable "dns-zone" {}
variable "keyvault-name" {}
variable "aks-name" {}
variable "rg-name" {}
variable "location" {}

variable "aks-vnet" {}
variable "mgmt-vnet" {}
variable "mgmt-rg" {}
variable "aks-subnet-cidr" {}
