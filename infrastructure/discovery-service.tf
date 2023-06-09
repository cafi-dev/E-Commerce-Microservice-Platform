resource "aws_security_group" "discovery-service_sg" {
  name   = "discovery-service-${var.project}-${var.env}-${var.launch_type}-ecs-sg"
  vpc_id = module.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 8010
    to_port         = 8010
    security_groups = [module.lb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "discovery-service_task_definition" {
  source         = "./modules/ecs/task_definition"
  name           = "discovery-service-${var.project}-${var.env}-ecs-task-def"
  launch_type    = [var.launch_type]
  network_mode   = var.network_mode
  cpu            = var.cpu
  memory         = var.memory
  execution_role = module.task_execution_role.arn
  definitions = templatefile("definitions/container_definition.json", {
    repository_url  = "appcd2023/is-service-discovery:latest"
    definition_name = "discovery-service-${var.project}-${var.env}-${var.launch_type}"
    container_port  = 8010
    host_port       = 8010
  })
}

module "discovery-service_ecs_service" {
  source          = "./modules/ecs/service"
  name            = "discovery-service-${var.project}-${var.env}-${var.launch_type}-ecs-service"
  cluster         = module.ecs_cluster.id
  task_definition = module.discovery-service_task_definition.arn
  desired_count   = var.desired_tasks
  launch_type     = var.launch_type
  container_name  = "discovery-service-${var.project}-${var.env}-${var.launch_type}"
  container_port  = 8010
  network_config = [
    {
      subnets         = module.vpc.private_subnet_ids
      public_ip       = "false"
      security_groups = [aws_security_group.discovery-service_sg.id]
    }
  ]

  namespace = "${var.project}-${var.env}"
  dns_name  = "discovery-service"
}

  