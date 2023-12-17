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

# Get the ecs cluster from remote state
data "terraform_remote_state" "ecs_cluster" {
  backend = "s3"
  config = {
    bucket = "terraform-cloudgeeks"
    key    = "terraform/ecs/terraform.tfstate"
    region = "us-east-1"
  }
}



locals {

  cluster_name = data.terraform_remote_state.ecs_cluster.outputs.ecs.cluster_name

  # region
  region = "us-east-1"


  # Ecs Service Connect
  namespace_arn  = "arn:aws:servicediscovery:us-east-1:205778047326:namespace/ns-koohieplz5q34cdp"
  namespace_name = "saqlainmushtaq.com"
  namespace_id   = "ns-koohieplz5q34cdp"

  # environment
  environment = "dev"

  # image
  image    = "redis:latest"

  # container
  container_name = "redis"

  # service
  service_name   = local.container_name

  # port
  port      = 6379

  # env vars
  environment_vars = [
    {
      name : "redis_host",
      value : "redis.saqlainmushtaq.com"
    },
    {
      name : "python_app_env_2",
      value : "VALUE"
    },

  ]


  # secrets from ssm parameter store
  secrets = [
    {
      name : "pythonapp_secret_1",
      valueFrom : "arn:aws:ssm:us-east-1:205778047326:parameter/pythonapp_secret_1"
    },
    {
      name : "pythonapp_secret_2",
      valueFrom : "arn:aws:ssm:us-east-1:205778047326:parameter/pythonapp_secret_2"
    }
  ]



}


resource "aws_ecs_task_definition" "es_task_definition" {
  family                       = "${local.container_name}_${local.environment}"
  cpu                          = "1024"
  network_mode                 = "awsvpc"
  memory                       = "2048"
  requires_compatibilities     = ["FARGATE"]
  task_role_arn                = aws_iam_role.ecs-task-execution-role-ecs-fargate.arn
  execution_role_arn           = aws_iam_role.ecs-task-execution-role-ecs-fargate.arn
  container_definitions        = data.template_file.container_definition.rendered

  lifecycle {
    create_before_destroy      = true
    ignore_changes             = [container_definitions]
  }
}

data "template_file" "container_definition" {
  template = file("./container_definition.json.tpl")
  vars = {
    environment = jsonencode(local.environment_vars)
    secrets     = jsonencode(local.secrets)
    image       = local.image
    log_group   = aws_cloudwatch_log_group.cloudwatch_log_group.name
    cntr        = local.container_name
    port        = local.port
    region      = local.region
  }
}

#######################
# Cloudwatch Log Group
#######################
resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name = "/ecs/loggroup/${local.container_name}_${local.environment}"

  tags = {
    Environment = local.environment
    Application = local.container_name
  }
}

# Service Discovery
# https://medium.com/inspiredbrilliance/ecs-integrated-service-discovery-18cdbce45d8b
# we created namespace with aws cli
# aws servicediscovery create-service --name redis --namespace-id ns-koohieplz5q34cdp --dns-config '{"NamespaceId": "ns-koohieplz5q34cdp", "DnsRecords": [{"Type": "A", "TTL": 10}]}'


###################
# Service Section
###################
resource "aws_ecs_service" "aws_ecs_service" {
  name                                     = local.container_name
  launch_type                              = "FARGATE"  # launch_type -  Defaults to EC2
  # ---> Cluster ARN
  cluster                                  = data.terraform_remote_state.ecs_cluster.outputs.ecs.cluster_arn
  deployment_minimum_healthy_percent       = "100"
  deployment_maximum_percent               = "200"
  task_definition                          = aws_ecs_task_definition.es_task_definition.arn
  desired_count                            = "1"

  # Do not use this if you are using service connect
#  # aws servicediscovery list-services --region us-east-1
#  service_registries {
#    registry_arn = "arn:aws:servicediscovery:us-east-1:205778047326:service/srv-w7weekujfqiutz6h"
#  }

  # https://stackoverflow.com/questions/75213261/aws-service-connect-with-terraform
  service_connect_configuration {
    enabled   = true
    namespace = local.namespace_arn
    service {
      discovery_name = local.container_name
      port_name      = local.container_name
      client_alias {
        dns_name = "${local.container_name}.${local.namespace_name}"
        port     = local.port
      }
    }
  }

  #  health_check_grace_period_seconds        = "180" # Used if service is configured to use ELB/ALB/NLB


  #  load_balancer {
  #    target_group_arn  = data.terraform_remote_state.alb.outputs.alb.target_groups["redis-app"].arn
  #    container_name    = local.container_name
  #    container_port    = local.port
  #  }


  network_configuration {
    security_groups  = [data.terraform_remote_state.vpc.outputs.vpc.default_security_group_id]
    subnets          = data.terraform_remote_state.vpc.outputs.vpc.public_subnets
    assign_public_ip = "true"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [desired_count]
  }


}

######################
# Service Auto Scaling
######################
resource "aws_appautoscaling_target" "aws_ecs_target" {
  max_capacity       = "1"
  min_capacity       = "1"
  # ECS ClusterName  # ServiceName
  resource_id        = "service/${local.cluster_name}/${local.container_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.aws_ecs_service]
}


#################
# CPU Utilization
#################
resource "aws_appautoscaling_policy" "aws_ecs_policy_cpu" {
  name               = "${local.container_name}-cpu-autoscaling-${local.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.aws_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.aws_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.aws_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {


      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300

    target_value       = 80
  }
  depends_on = [aws_appautoscaling_target.aws_ecs_target]
}

####################
# Memory Utilization
####################
resource "aws_appautoscaling_policy" "aws_ecs_policy_memory" {
  name               = "${local.container_name}-memory-autoscaling-${local.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.aws_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.aws_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.aws_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 300

    target_value       = 80

  }

  depends_on = [aws_appautoscaling_target.aws_ecs_target]

}
