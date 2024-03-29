terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
  // default_tags {
  //tags = {
  //  Name = "architect-demo1"
  // }
  //}
}

//////////////////////////////////////////////////////////
resource "aws_ecr_repository" "foo" {
  name                 = "devops-code-challenge"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_availability_zones" "available_zones" {
  state = "available"
} //names[us-east-2a, us-east-2b, us-east-2c]

resource "aws_vpc" "default" {
  cidr_block = "10.32.0.0/16"
  tags = {
    Name = var.moses
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, 2 + count.index)     // "10.32.2.0/24" 10.32.3.0/24
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index] //us-east-1a
  vpc_id                  = aws_vpc.default.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index) // "10.32.0.0/24" "10.32.1.0/24"
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.default.id
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id

}

resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}


resource "aws_security_group" "lb" {
  name   = "devops-code-challenge-alb-security-group"
  vpc_id = aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "default" {
  name            = "devops-code-challenge-lb"
  subnets         = aws_subnet.public.*.id //specifies subnets in which to create the Amazon Elastic Load Balancer (ALB)
  security_groups = [aws_security_group.lb.id]
}


resource "aws_lb_target_group" "devopss-code-challenge" {
  name        = "devops-code-challenge-tg"
  port        = 8080 //specifies the destination port on target instance for incoming traffic from the load balancer
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"
}


resource "aws_lb_listener" "devopss-code-challenge" {
  load_balancer_arn = aws_lb.default.id
  port              = "80" //port on the load balancer listening for incoming traffic
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.devopss-code-challenge.id
    type             = "forward"
  }
}


resource "aws_ecs_task_definition" "devopss-code-challenge" {
  family                   = "devopss-code-challenge"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = <<DEFINITION
[
  {
    "image": "public.ecr.aws/h8n2j7c4/lightfeather-backend:3",
    "memoryReservation": 1024,
    "cpu":  512,
    "name": "devopss-code-challenge-backendapp",
	  "portMappings": [
	  {
        "containerPort": 8080,
         "hostPort": 8080
      }
    ],
      "essential": true
  },
  {
    "name": "devopss-code-challenge-frontendapp",
    "image": "public.ecr.aws/h8n2j7c4/lightfeather-frontend:3",
    "cpu":  512,
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
      "essential": true
  }
]
DEFINITION
}

resource "aws_security_group" "devopss-code-challenge_task" {
  name   = "devops-code-challenge-task-security-group"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    //security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
// ****************************************************************************
resource "aws_ecs_cluster" "main" {
  name = "devops-code-challenge-cluster"
}

resource "aws_ecs_service" "devopss-code-challenge" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.devopss-code-challenge.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.devopss-code-challenge_task.id]
    subnets         = aws_subnet.private.*.id //specifies the subnets in which to create the task network interfaces
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.devopss-code-challenge.id
    container_name   = "devopss-code-challenge-backendapp"
    container_port   = 8080 //port on the container that the traffic should be forwarded to
    //port that the backend application (expressjs) is listening on
  }

  depends_on = [aws_lb_listener.devopss-code-challenge]
}

///////////////////////////////////////////////////////////////////////////////////////////////////


variable "app_count" {
  type    = number
  default = 1
}


variable "moses" {
  type    = string
  default = "This is a review Raymond"
}

//////////////////////////////////////////////////////////////////////

output "load_balancer_ip" {
  value = aws_lb.default.dns_name
}





