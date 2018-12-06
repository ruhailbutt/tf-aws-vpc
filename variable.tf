variable "vpc_region" {
 description = "vpc region..."
}
variable "vpc_cidr" {
description = "CIDR range for Dev VPC.."
}
variable "vpc_name" {
 description = "vpc name"
}
variable "instance_tenancy" {}
variable "enable_dns_hostnames" {}
variable "enable_dns_support" {}
variable "pub_subnet_cidr" {}
variable "pub_subnet_az" {}
variable "pri_subnet_cidr" {}
variable "pri_subnet_az" {}
variable "pub_subnet_ip_on_launch" {}
variable "amis" {
 type = "map"
}
variable "region" {}
variable "key" {}
variable "security_group_ids" {
 type = "list"
}
variable "instance_type" {}
variable "azs" {
 type = "list"
 }
