resource "aws_security_group" "api-gateway_sg" {
  name   = "api-gateway-${var.project}-${var.env}-${var.launch_type}-ecs-sg"
  vpc_id = module.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 8011
    to_port         = 8011
    security_groups = [module.lb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "api-gateway_task_definition" {
  source         = "./modules/ecs/task_definition"
  name           = "api-gateway-${var.project}-${var.env}-ecs-task-def"
  launch_type    = [var.launch_type]
  network_mode   = var.network_mode
  cpu            = var.cpu
  memory         = var.memory
  execution_role = module.task_execution_role.arn
  definitions = templatefile("definitions/container_definition.json", {
    repository_url  = "appcd2023/is-gateway-service:latest"
    definition_name = "api-gateway-${var.project}-${var.env}-${var.launch_type}"
    container_port  = 8011
    host_port       = 8011
  })
}

module "api-gateway_ecs_service" {
  source          = "./modules/ecs/service"
  name            = "api-gateway-${var.project}-${var.env}-${var.launch_type}-ecs-service"
  cluster         = module.ecs_cluster.id
  task_definition = module.api-gateway_task_definition.arn
  desired_count   = var.desired_tasks
  launch_type     = var.launch_type
  container_name  = "api-gateway-${var.project}-${var.env}-${var.launch_type}"
  container_port  = 8011
  network_config = [
    {
      subnets         = module.vpc.private_subnet_ids
      public_ip       = "false"
      security_groups = [aws_security_group.api-gateway_sg.id]
    }
  ]

  namespace = "${var.project}-${var.env}"
  dns_name  = "api-gateway"
}

  