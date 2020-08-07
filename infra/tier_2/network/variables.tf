variable "tags" {
  type = map
  default = {
    environment = "demo"
    source      = "microsoft"
  }
}

variable "project_name" {}
variable "mgmt-rg" {}
variable "location" {}

variable "aks-vnet" {
  default = "vuggie-aks-aksprivatelinkdemo-vnet"
}

variable "aks-vnet-cidr" {
  default = "15.1.0.0/16"
}

variable "mgmt-vnet" {
  default = "vuggie-mgmt-aksprivatelinkdemo-vnet"
}

variable "mgmt-subnet" {
  default = "vuggie-mgmt-aksprivatelinkdemo-subnet"
}

variable "mgmt-vnet-cidr" {
  default = "10.1.0.0/16"
}

variable "mgmt-subnet-cidr" {
  default = "10.1.1.0/24"
}
