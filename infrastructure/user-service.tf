resource "aws_security_group" "user-service_sg" {
  name   = "user-service-${var.project}-${var.env}-${var.launch_type}-ecs-sg"
  vpc_id = module.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 8017
    to_port         = 8017
    security_groups = [aws_security_group.orchestration-service_sg.id, module.lb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "user-service_task_definition" {
  source         = "./modules/ecs/task_definition"
  name           = "user-service-${var.project}-${var.env}-ecs-task-def"
  launch_type    = [var.launch_type]
  network_mode   = var.network_mode
  cpu            = var.cpu
  memory         = var.memory
  execution_role = module.task_execution_role.arn
  definitions = templatefile("definitions/container_definition.json", {
    repository_url  = "appcd2023/is-user-service:latest"
    definition_name = "user-service-${var.project}-${var.env}-${var.launch_type}"
    container_port  = 8017
    host_port       = 8017
  })
}

module "user-service_ecs_service" {
  source          = "./modules/ecs/service"
  name            = "user-service-${var.project}-${var.env}-${var.launch_type}-ecs-service"
  cluster         = module.ecs_cluster.id
  task_definition = module.user-service_task_definition.arn
  desired_count   = var.desired_tasks
  launch_type     = var.launch_type
  container_name  = "user-service-${var.project}-${var.env}-${var.launch_type}"
  container_port  = 8017
  network_config = [
    {
      subnets         = module.vpc.private_subnet_ids
      public_ip       = "false"
      security_groups = [aws_security_group.user-service_sg.id]
    }
  ]

  lb_target_group = module.user-service_target_group.arn
  http_listener   = module.http_listener.arn
  namespace       = "${var.project}-${var.env}"
  dns_name        = "user-service"
}


module "user-service_target_group" {
  source      = "./modules/alb/target_group"
  name        = "user-service-${var.project}-${var.env}-tg"
  port        = 8017
  protocol    = var.tg_protocol
  target_type = var.tg_type
  vpc_id      = module.vpc.id
}

module "user-service_http_listener_rule" {
  source       = "./modules/alb/lb_listener_rule"
  listener_arn = module.http_listener.arn
  action_type  = var.http_listener_action
  tg_arn       = module.user-service_target_group.arn
  svc_name     = "user-service"
}