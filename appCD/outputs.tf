output "rds_connection_endpoint" {
    value = module.rds.db_instance_endpoint
    description = "db connection endpoint "
}

output "rds_instance_arn" {
    value = module.rds.db_instance_arn
    description = "RDS instance ARN"
}