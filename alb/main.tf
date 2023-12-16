# Get the vpc from remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-cloudgeeks"
    key    = "terraform/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.2.0"

  name    = "cloudgeeks-alb"
  vpc_id  = data.terraform_remote_state.vpc.outputs.vpc.vpc_id
  # Using the public subnet IDs from the remote state
  subnets = data.terraform_remote_state.vpc.outputs.vpc.public_subnets

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

# listeners and rules
  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:us-east-1:326125176711:certificate/285797d9-c289-4cdf-8d3d-eb9f4326dffa"

      # Default action
      forward = {
        target_group_key = "default-instance"
      }


      # Rules if path is /* and host is python-app.saqlainmushtaq.com forward to python-app target group
      rules = {
        python-app-rule = {
          priority = 1

          conditions = [
            {
              path_pattern = {
                values = ["/"]
              }
            },
            {
              host_header = {
                values = ["python-app.saqlainmushtaq.com"]
              }
            }
          ]
          actions = [
            {
              type             = "forward"
              target_group_key = "python-app"
            }
          ]
        }

      }
    }
  }




  target_groups = {

    default-instance = {
      name              = "default"
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      create_attachment = false
    }


    python-app = {
      name                              = "python-app"
      protocol                          = "HTTP"
      port                              = 5000
      target_type                       = "ip"
      deregistration_delay              = 10
      create_attachment                 = false
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }



      tags = {
        Environment = "Development"
        Project     = "DevOps"
      }

    }

  }

  enable_deletion_protection = false

}