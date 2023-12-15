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


module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  version = "5.7.3"

  cluster_name = "ecs-cloudgeeks"

  cluster_service_connect_defaults = {
    "namespace" = "arn:aws:servicediscovery:us-east-1:686432060491:namespace/ns-5z2tbrwt7ycinxam"
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

  services = {
    python-frontend-app = {
      cpu    = 1024
      memory = 4096

      # Container definition(s)
      container_definitions = {

        python-frontend-app = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "docker.io/quickbooks2018/python-app:latest"
          port_mappings = [
            {
              name          = "python-frontend-app"
              containerPort = 5000
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false


          enable_cloudwatch_logging = true
          log_configuration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group" = "/aws/ecs/python-frontend-app/python-frontend-app"
              "awslogs-region" = "us-east-1"
              "awslogs-stream-prefix" = "ecs"
            }
          }
          memory_reservation = 100
        }
      }

      service_connect_configuration = {
        namespace = "arn:aws:servicediscovery:us-east-1:686432060491:namespace/ns-5z2tbrwt7ycinxam"
        service = {
          client_alias = {
            port     = 5000
            dns_name = "python-frontend-app"
          }
          port_name      = "python-frontend-app"
          discovery_name = "python-frontend-app"
        }
      }

      load_balancer = {
        service = {
          target_group_arn = data.terraform_remote_state.alb.outputs.alb.target_groups["python-app"].arn
          container_name   = "python-frontend-app"
          container_port   = 5000
        }
      }

      subnet_ids = data.terraform_remote_state.vpc.outputs.vpc.private_subnets
      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = data.terraform_remote_state.alb.outputs.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = {
    Environment = "Development"
    Project     = "DevOps"
  }
}