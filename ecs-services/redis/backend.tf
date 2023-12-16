### Backend ###
# S3
###############

terraform {
  backend "s3" {
    bucket = "terraform-cloudgeeks"
    key    = "terraform/ecs-service-redis-app/terraform.tfstate"
    region = "us-east-1"
  }
}