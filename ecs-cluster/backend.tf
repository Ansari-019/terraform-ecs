### Backend ###
# S3
###############

terraform {
  backend "s3" {
    bucket = "terraform-cloudgeeks"
    key    = "terraform/ecs/terraform.tfstate"
    region = "us-east-1"
  }
}