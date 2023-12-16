[{
    "logConfiguration": {
      "logDriver": "awslogs",
      "secretOptions": null,
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "environment": ${environment},
    "secrets": ${secrets},
    "portMappings": [
      {
        "name":   "${cntr}",
        "hostPort": ${port},
        "protocol": "tcp",
        "containerPort": ${port}
      }
    ],
    "essential": true,
    "image": "${image}",
    "name": "${cntr}"
  }]