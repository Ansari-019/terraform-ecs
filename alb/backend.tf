### Backend ###
# S3
###############

terraform {
  backend "s3" {
    bucket = "terraform-cloudgeeks"
    key    = "terraform/alb/terraform.tfstate"
    region = "us-east-1"
  }
}