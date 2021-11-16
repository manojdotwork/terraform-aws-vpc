# terraform-aws-vpc

## Usage
```hcl
locals {
  default_tags = {
    "Source" = "Terraform"
  }
}

module "networking" {
  source       = "./terraform-aws-vpc"
  vpc_cidr     = var.vpc_cidr
  region       = var.region
  identifier   = var.identifier
  default_tags = local.default_tags
}
```