### Backend ###
# S3
###############

terraform {
  backend "s3" {
    bucket = "terraform-cloudgeeks"
    key    = "terraform/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}