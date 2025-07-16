Absolutely! Here's a complete Step-by-Step Method of Procedure (MOP) for your current ECS Fargate + Terraform + GitHub Actions CI/CD setup with dev, staging, and prod branches:
________________________________________
📘 Method of Procedure (MOP)
Project Title: Multi-Environment ECS Fargate Deployment with Terraform & GitHub Actions
Author: Jomari R. Samson
Environments: dev, staging, prod
App: Dockerized Node.js App
CI/CD: GitHub Actions
Infrastructure as Code: Terraform
________________________________________
✅ Prerequisites
1.	AWS CLI installed and configured (aws configure)
2.	Docker installed
3.	Terraform installed
4.	GitHub account & repo created
5.	Amazon ECR repo created (can be shared or one per env)
6.	IAM User/Role with appropriate permissions
________________________________________
🧱 Step 1: Directory Structure
bash
CopyEdit
aws-devops-portfolio/
├── app/                    # Your Dockerized Node.js App
│   ├── app.js
│   ├── Dockerfile
│   └── package.json
├── terraform/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── .github/
│   └── workflows/
│       ├── dev.yml
│       ├── staging.yml
│       └── prod.yml
└── README.md
________________________________________
<<<<<<< HEAD
⚙️ Step 3: Terraform Setup
root@ip-172-31-25-109://root/terraform# ls -larth
total 20K
drwxr-xr-x  3 root root 4.0K Jul 12 06:18 dev
drwxr-xr-x  3 root root 4.0K Jul 12 06:27 prod
drwxr-xr-x  3 root root 4.0K Jul 12 06:38 staging

FOR DEV

root@ip-172-31-25-109://root/terraform/dev# ls -larth
total 84K
-rw-r--r-- 1 root root   47 Jul 11 15:03 provider.tf
-rw-r--r-- 1 root root   54 Jul 11 15:03 outputs.tf
-rw-r--r-- 1 root root  104 Jul 11 15:38 terraform.tfvars
-rw-r--r-- 1 root root  223 Jul 11 15:39 variables.tf
-rw-r--r-- 1 root root 5.3K Jul 12 02:56 main.tf

root@ip-172-31-25-109://root/terraform/dev# cat provider.tf
provider "aws" {
  region = "ap-southeast-1"
}

root@ip-172-31-25-109://root/terraform/dev# cat outputs.tf
output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}

root@ip-172-31-25-109://root/terraform/dev# cat terraform.tfvars
ecr_image   = "064160141816.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-node-app:dev"
environment = "dev"

root@ip-172-31-25-109://root/terraform/dev# cat variables.tf
variable "ecr_image" {
  type        = string
  description = "ECR image URI with tag (e.g., ecs-node-app:prod)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}
root@ip-172-31-25-109:~/terraform/dev# cat main.tf
#Cloud Provider
#provider "aws" {
#  region = "ap-southeast-1"
#}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnets
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route.id
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "app_lb" {
  name               = "app-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

# ALB Target Group
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# ALB Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "fargate-cluster-${var.environment}"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "fargate-task-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "fargate-app"
    image     = "064160141816.dkr.ecr.ap-southeast-1.amazonaws.com/fargate-app:dev"
    essential = true
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
  }])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "fargate-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "fargate-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.app_listener]
}

# Autoscaling
resource "aws_appautoscaling_target" "ecs_scaling_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_scaling" {
  name               = "ecs-cpu-scaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

FOR STAGING
variable "environment" {
root@ip-172-31-25-109:~/terraform/staging# ls -larth
total 84K
-rw-r--r-- 1 root root   47 Jul 11 15:03 provider.tf
-rw-r--r-- 1 root root   54 Jul 11 15:03 outputs.tf
-rw-r--r-- 1 root root  112 Jul 11 15:37 terraform.tfvars
-rw-r--r-- 1 root root  223 Jul 11 15:38 variables.tf
-rw-r--r-- 1 root root 5.4K Jul 12 03:56 main.tf

root@ip-172-31-25-109:~/terraform/staging# cat provider.tf
provider "aws" {
  region = "ap-southeast-1"
}
root@ip-172-31-25-109:~/terraform/staging# cat outputs.tf
output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}
root@ip-172-31-25-109:~/terraform/staging# cat terraform.tfvars
ecr_image   = "064160141816.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-node-app:staging"
environment = "staging"

root@ip-172-31-25-109:~/terraform/staging# cat variables.tf
variable "ecr_image" {
  type        = string
  description = "ECR image URI with tag (e.g., ecs-node-app:prod)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}


root@ip-172-31-25-109:~/terraform/staging# cat main.tf
#Cloud Provider
#provider "aws" {
#  region = "ap-southeast-1"
#}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnets
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route.id
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "app_lb" {
  name               = "app-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

# ALB Target Group
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# ALB Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "fargate-cluster-${var.environment}"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "fargate-task-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "fargate-app"
    image     = "064160141816.dkr.ecr.ap-southeast-1.amazonaws.com/fargate-app:staging"
    essential = true
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
  }])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "fargate-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "fargate-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.app_listener]
}

# Autoscaling
resource "aws_appautoscaling_target" "ecs_scaling_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_scaling" {
  name               = "ecs-cpu-scaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}



FOR PROD

root@ip-172-31-25-109:~/terraform/prod# ls -larth
total 84K
-rw-r--r-- 1 root root   47 Jul  9 16:02 provider.tf
-rw-r--r-- 1 root root   54 Jul  9 16:02 outputs.tf
-rw-r--r-- 1 root root  223 Jul 11 15:35 variables.tf
-rw-r--r-- 1 root root  106 Jul 11 17:57 terraform.tfvars
-rw-r--r-- 1 root root 5.3K Jul 12 05:09 main.tf

root@ip-172-31-25-109:~/terraform/prod# cat provider.tf
provider "aws" {
  region = "ap-southeast-1"
}
root@ip-172-31-25-109:~/terraform/prod# cat outputs.tf
output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}
root@ip-172-31-25-109:~/terraform/prod# cat variables.tf
variable "ecr_image" {
  type        = string
  description = "ECR image URI with tag (e.g., ecs-node-app:prod)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

root@ip-172-31-25-109:~/terraform/prod# cat terraform.tfvars
ecr_image   = "064160141816.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-node-app:prod"
environment = "prod"


root@ip-172-31-25-109:~/terraform/prod# cat main.tf
#Cloud Provider
#provider "aws" {
#  region = "ap-southeast-1"
#}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnets
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route.id
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "app_lb" {
  name               = "app-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

# ALB Target Group
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# ALB Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "fargate-cluster-${var.environment}"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "fargate-task-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "fargate-app"
    image     = "064160141816.dkr.ecr.ap-southeast-1.amazonaws.com/fargate-app:prod"
    essential = true
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
  }])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "fargate-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "fargate-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.app_listener]
}

# Autoscaling
resource "aws_appautoscaling_target" "ecs_scaling_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_scaling" {
  name               = "ecs-cpu-scaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}






⚙️ Step 2: Setup Docker App
root@ip-172-31-25-109:~/aws-devops-portfolio/app# ls -alrth
total 20K
-rw-r--r-- 1 root root   82 Jul  9 10:47 Dockerfile
-rw-r--r-- 1 root root  121 Jul  9 10:48 package.json
-rw-r--r-- 1 root root  237 Jul 12 05:32 app.js\

root@ip-172-31-25-109:~/aws-devops-portfolio/app# cat Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "app.js"]

root@ip-172-31-25-109:~/aws-devops-portfolio/app# cat package.json
{
  "name": "fargate-app",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.18.2"
  }
}

root@ip-172-31-25-109:~/aws-devops-portfolio/app# cat app.js
const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Hello Jomari from ECS Fargate Updated Application 12/07/2025 version 1'));
app.listen(3000, () => console.log('App running on port 3000')); ________________________________________




Create AWS Resources (ECR, IAM, etc.)
🔸 Create ECR Repository
bash
CopyEdit
aws ecr create-repository --repository-name fargate-app
Get the repo URL:
064160141816.dkr.ecr.ap-southeast-1.amazonaws.com/fargate-app

🔐 Step 4: Configure GitHub Secrets
Go to your GitHub repository →
 Click Settings > Secrets and variables > Actions →
 Click “New repository secret” and add the following:


Name	Example Value
AWS_ACCESS_KEY_ID	
AWS_SECRET_ACCESS_KEY	
AWS_REGION	ap-southeast-1
AWS_ACCOUNT_ID	
ECR_REPO_NAME	fargate-app


.
 
🔸 Create IAM User for GitHub Actions or full Admin Access
•	Go to AWS IAM → Users → Add User
•	Programmatic access ✅
•	Attach policies:
o	AmazonEC2ContainerRegistryFullAccess
o	AmazonECS_FullAccess
o	IAMFullAccess (for testing)
Note the Access Key and Secret Key — these go to GitHub secrets.


________________________________________
⚡ Step 5: Setup GitHub Workflows
root@ip-172-31-25-109:~/aws-devops-portfolio/.github/workflows# ls -larth
total 28K
drwxr-xr-x 3 root root 4.0K Jul  9 10:49 ..
-rw-r--r-- 1 root root 1.2K Jul  9 10:53 README.md
-rw-r--r-- 1 root root 1.4K Jul  9 14:42 deploy.yml
-rw-r--r-- 1 root root 1.3K Jul 11 17:03 dev.yml
-rw-r--r-- 1 root root 1.4K Jul 11 17:04 staging.yml
-rw-r--r-- 1 root root 1.4K Jul 12 05:05 prod.yml


DEV

root@ip-172-31-25-109:~/aws-devops-portfolio/.github/workflows# cat dev.yml
name: Deploy to ECS Fargate (dev)

on:
  push:
    branches: [dev]

env:
  AWS_REGION: ap-southeast-1
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
  ENVIRONMENT: dev
  ECR_REPO_NAME: fargate-app
  ECR_IMAGE: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-southeast-1.amazonaws.com/fargate-app:dev
  TASK_FAMILY: fargate-task-dev
  SERVICE_NAME: fargate-service-dev
  CLUSTER_NAME: fargate-cluster-dev

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        run: |
          aws ecr get-login-password --region $AWS_REGION \
          | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

      - name: Build and Push Docker image
        run: |
          docker build -t $ECR_IMAGE ./app
          docker push $ECR_IMAGE

      - name: Force new ECS Deployment
        run: |
          aws ecs update-service \
            --cluster $CLUSTER_NAME \
            --service $SERVICE_NAME \
            --force-new-deployment


STAGING

root@ip-172-31-25-109:~/aws-devops-portfolio/.github/workflows# cat staging.yml
name: Deploy to ECS Fargate (staging)

on:
  push:
    branches: [staging]

env:
  AWS_REGION: ap-southeast-1
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
  ENVIRONMENT: staging
  ECR_REPO_NAME: fargate-app
  ECR_IMAGE: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-southeast-1.amazonaws.com/fargate-app:staging
  TASK_FAMILY: fargate-task-staging
  SERVICE_NAME: fargate-service-staging
  CLUSTER_NAME: fargate-cluster-staging

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        run: |
          aws ecr get-login-password --region $AWS_REGION \
          | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

      - name: Build and Push Docker image
        run: |
          docker build -t $ECR_IMAGE ./app
          docker push $ECR_IMAGE

      - name: Force new ECS Deployment
        run: |
          aws ecs update-service \
            --cluster $CLUSTER_NAME \
            --service $SERVICE_NAME \
            --force-new-deployment


PROD
root@ip-172-31-25-109:~/aws-devops-portfolio/.github/workflows# cat prod.yml
name: Deploy to ECS Fargate (prod)

on:
  push:
    branches: [prod]

env:
  AWS_REGION: ap-southeast-1
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
  ENVIRONMENT: prod
  ECR_REPO_NAME: fargate-app
  ECR_IMAGE: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-southeast-1.amazonaws.com/fargate-app:prod
  TASK_FAMILY: fargate-task-prod
  SERVICE_NAME: fargate-service-prod
  CLUSTER_NAME: fargate-cluster-prod
=======
⚙️ Step 2: Setup Docker App
app/Dockerfile
Dockerfile
CopyEdit
FROM node:18-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
________________________________________
🌍 Step 3: Create Terraform Code Per Environment
Each folder (dev, staging, prod) must have:
•	main.tf
•	variables.tf
•	outputs.tf
•	provider.tf
🔁 Repeat your current working prod Terraform files for dev and staging, update:
•	Cluster name
•	ECS service name
•	Task family name
•	ECR image (tag as :dev, :staging, :latest)
________________________________________
🔐 Step 4: Configure GitHub Secrets
In your GitHub repo, go to Settings → Secrets and variables → Actions
Create the following secrets:
Name	Value
AWS_ACCESS_KEY_ID	Your AWS access key
AWS_SECRET_ACCESS_KEY	Your AWS secret
AWS_REGION	ap-southeast-1
AWS_ACCOUNT_ID	Your AWS account ID
________________________________________
⚡ Step 5: Setup GitHub Workflows
Example: .github/workflows/dev.yml
yaml
CopyEdit
name: Deploy to Dev

on:
  push:
    branches:
      - dev

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
  ECR_REPO_NAME: fargate-app
  CLUSTER_NAME: fargate-cluster-dev
  SERVICE_NAME: fargate-service-dev
  TASK_FAMILY: fargate-task-dev
>>>>>>> 79ff612c565875f4a9e7de6c662186b8d43da042

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
<<<<<<< HEAD
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        run: |
          aws ecr get-login-password --region $AWS_REGION \
          | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

      - name: Build and Push Docker image
        run: |
          docker build -t $ECR_IMAGE ./app
          docker push $ECR_IMAGE

      - name: Force new ECS Deployment
        run: |
          aws ecs update-service \
            --cluster $CLUSTER_NAME \
            --service $SERVICE_NAME \
            --force-new-deployment
=======
    - name: Checkout
      uses: actions/checkout@v4

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v3
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to ECR
      run: |
        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

    - name: Build, Tag, Push Image
      run: |
        docker build -t $ECR_REPO_NAME ./app
        docker tag $ECR_REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:dev
        docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:dev

    - name: Deploy to ECS
      run: |
        aws ecs update-service \
          --cluster $CLUSTER_NAME \
          --service $SERVICE_NAME \
          --force-new-deployment
>>>>>>> 79ff612c565875f4a9e7de6c662186b8d43da042
🔁 Copy this for staging.yml and prod.yml, update:
•	ECR image tag to :staging or :latest
•	ECS cluster/service/task names
________________________________________
🌐 Step 6: Deploy Terraform Infra
<<<<<<< HEAD
=======
Per environment:
bash
CopyEdit
>>>>>>> 79ff612c565875f4a9e7de6c662186b8d43da042
cd terraform/dev
terraform init
terraform apply

cd ../staging
terraform init
terraform apply

cd ../prod
terraform init
terraform apply
☑️ Copy the output alb_dns after apply — this is your app URL.
________________________________________
🚀 Step 7: Workflow In Action
Make code changes to the app:
<<<<<<< HEAD
# Push to dev
git checkout dev
git add .
git commit -m "Update Dev App"
git push origin dev

# Promote to staging
git checkout staging
git merge dev
git push origin staging

# Promote to prod
git checkout prod
git merge staging
git push origin prod
=======
bash
CopyEdit
git checkout dev
# edit app.js
git add .
git commit -m "Update Dev App"
git push origin dev
>>>>>>> 79ff612c565875f4a9e7de6c662186b8d43da042
✅ This triggers:
•	Docker build
•	Push to ECR with :dev tag
•	ECS Fargate redeploy on dev
🔁 Repeat with staging and prod branches.
________________________________________
📦 Step 8: Add to Portfolio
•	Add README.md with:
o	Architecture diagram
o	Tools used
o	How to deploy and test
•	Add screenshots of:
o	GitHub Actions logs
o	App running on dev, staging, prod URLs
o	Terraform apply output
<<<<<<< HEAD
=======
________________________________________
Let me know if you'd like me to generate the sample README.md or CI/CD diagram next!





>>>>>>> 79ff612c565875f4a9e7de6c662186b8d43da042





Here’s your complete and professional README.md for the project, along with an ASCII-based CI/CD diagram. This is suitable for showcasing in a DevOps portfolio or GitHub repo:
________________________________________
markdown
CopyEdit
# 🚀 Multi-Environment ECS Fargate Deployment with Terraform & GitHub Actions

This project demonstrates a fully automated CI/CD pipeline that deploys a Dockerized Node.js app to **Amazon ECS Fargate** across three environments: `dev`, `staging`, and `prod`. It uses **Terraform** for infrastructure provisioning and **GitHub Actions** for continuous integration and deployment.

---

## 📐 Architecture Overview

```text
┌───────────────┐         ┌────────────────────┐
│ GitHub Repo   │  Push   │ GitHub Actions     │
│ (dev/staging/ │ ──────▶ │ CI/CD Pipelines    │
│ prod branches)│         │ (dev.yml, etc.)    │
└───────────────┘         └────────────────────┘
                                │
                                ▼
                        ┌───────────────┐
                        │ Build & Push │
                        │ Docker Image │
                        │  to ECR      │
                        └───────────────┘
                                │
                                ▼
                        ┌───────────────────┐
                        │ Terraform Infra   │
                        │ (VPC, ALB, ECS,   │
                        │ Auto Scaling)     │
                        └───────────────────┘
                                │
                                ▼
                     ┌────────────────────────┐
                     │ ECS Fargate Service    │
                     │ with Load Balancer     │
                     └────────────────────────┘
                                │
                                ▼
                        🌐 Public ALB DNS
________________________________________
🔧 Tools & Services Used
•	AWS ECS Fargate
•	AWS Application Load Balancer (ALB)
•	Amazon ECR
•	Terraform
•	GitHub Actions
•	Docker
•	Node.js (app)
________________________________________
🌍 Environments
Branch	ECS Cluster	ECR Image Tag	ALB DNS
dev	fargate-cluster-dev	:dev	Output of terraform apply
staging	fargate-cluster-staging	:staging	Output of terraform apply
prod	fargate-cluster	:latest	Output of terraform apply
________________________________________
📁 Project Structure
bash
CopyEdit
aws-devops-portfolio/
├── app/                        # Node.js App with Dockerfile
├── terraform/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── .github/
│   └── workflows/
│       ├── dev.yml
│       ├── staging.yml
│       └── prod.yml
└── README.md
________________________________________
⚙️ CI/CD Workflow
Each time a branch is pushed:
1.	GitHub Actions builds Docker image
2.	Tags and pushes it to ECR (:dev, :staging, :latest)
3.	Triggers ECS service update with force new deployment
4.	ECS pulls the new image and deploys it
5.	ALB serves the application
<<<<<<< HEAD
=======
________________________________________
🧪 How to Test
bash
CopyEdit
# Test Dev
git checkout dev
echo "console.log('Hello from Dev')" >> app/app.js
git commit -am "Update Dev App"
git push origin dev

# Test Staging
git checkout staging
echo "console.log('Hello from Staging')" >> app/app.js
git commit -am "Update Staging App"
git push origin staging

# Test Prod
git checkout prod
echo "console.log('Hello from Prod')" >> app/app.js
git commit -am "Update Prod App"
git push origin prod
Then, open the ALB DNS URL (from terraform output alb_dns) in your browser to verify.
________________________________________
🛡️ GitHub Secrets Required
Name	Description
AWS_ACCESS_KEY_ID	AWS IAM access key
AWS_SECRET_ACCESS_KEY	AWS IAM secret key
AWS_REGION	e.g., ap-southeast-1
AWS_ACCOUNT_ID	Your 12-digit AWS account ID
________________________________________
✅ How to Deploy Terraform
bash
CopyEdit
cd terraform/dev      # or staging/prod
terraform init
terraform apply
________________________________________
📷 Screenshots (optional)
You can upload screenshots of:
•	GitHub Actions logs for each branch
•	ECS task running on AWS console
•	Web app shown via the ALB DNS URL
________________________________________
>>>>>>> 79ff612c565875f4a9e7de6c662186b8d43da042
📌 Author
Jomari R. Samson
📧 zjrsamson07@gmail.com
📍 Sta. Maria, Bulacan
🌐 GitHub: jrstech-ops
<<<<<<< HEAD
	
=======

>>>>>>> 79ff612c565875f4a9e7de6c662186b8d43da042

