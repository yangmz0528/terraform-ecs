locals {
  prefix = "mingzi"
}

resource "aws_ecr_repository" "ecr" {
  name         = "${local.prefix}-ecr"
  force_delete = true
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.prefix}-ecs"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    mingzi-ecs-http = { # Task definition name and service name -> change
      cpu    = 512      # 0.5vCPU
      memory = 1024     # 1GB

      # Container definition(s)
      container_definitions = {
        ecs-sample = {     # container name
          essential = true #when creating task definition, on console the default is true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.prefix}-ecr:latest"
          port_mappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
        }
      }
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                         = flatten(data.aws_subnets.public.ids)
      security_group_ids                 = [module.ecs_sg.security_group_id]
    }
  }
}

module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${local.prefix}-ecs-sg"
  description = "Security group for ecs"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-8080-tcp"]
  egress_rules        = ["all-all"]
}