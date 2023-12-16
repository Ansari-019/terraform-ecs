# Get the vpc from remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-cloudgeeks"
    key    = "terraform/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

# Get the alb from remote state
data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = "terraform-cloudgeeks"
    key    = "terraform/alb/terraform.tfstate"
    region = "us-east-1"
  }
}

# https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  version = "5.7.3"

  cluster_name = "ecs-cloudgeeks"

  cluster_service_connect_defaults = {
    "namespace" = "arn:aws:servicediscovery:us-east-1:326125176711:namespace/ns-af4uihpgemsd7fft"
  }

  cluster_settings = {
    "name": "containerInsights",
    "value": "enabled"
  }

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }


  tags = {
    Environment = "Development"
    Project     = "DevOps"
  }
}
