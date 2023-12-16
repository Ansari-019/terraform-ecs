##############################
# IAM Role Task Execution Role
##############################
resource "aws_iam_role" "ecs-task-execution-role-ecs-fargate" {
  name               = "${local.container_name}-ecs-task-execution-role-ecs-fargate-${local.environment}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}




# ECS Task Execution Policy
resource "aws_iam_policy" "ecs-task-execution-policy-ecs-fargate" {
  name = "${local.container_name}-ecs-task-execution-policy-ecs-fargate-${local.environment}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutLogEvents",
                "ssm:GetParameters",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}



resource "aws_iam_policy_attachment" "ecs-task-execution-policy-attach" {
  name           = "${local.container_name}-ecs-task-execution-policy-${local.environment}"
  roles          = [aws_iam_role.ecs-task-execution-role-ecs-fargate.name]
  policy_arn     = aws_iam_policy.ecs-task-execution-policy-ecs-fargate.arn
}