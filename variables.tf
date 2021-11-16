variable "vpc_cidr" {
  description = "The CIDR block of the vpc"
}
variable "region" {
  description = "The region to launch the VPC"
}

variable "identifier" {
  description = "Identifier to prefix in the Name tag(s)"
}

variable "default_tags" {
  description = "Default tags"
}
