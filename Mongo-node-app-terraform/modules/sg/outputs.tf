output "aws_security_group_id" {
  value = aws_security_group.ecs_node_sg.id
}

output "aws_security_group_ecs_task_id" {
  value = aws_security_group.ecs_task.id
}


output "aws_security_group_http_id" {
  value = aws_security_group.http.id
}