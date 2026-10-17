terraform {
  backend "s3" {
    bucket       = "hongmall-terraform-state-697196251337"
    key          = "hongmall/cloudwatch/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}