
# --- ECS Launch Template --- #

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "ecs_ec2" {
  name_prefix            = "demo-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "m5.large"
  vpc_security_group_ids = [var.aws_security_group_id]

  iam_instance_profile { arn = var.aws_iam_instance_profile_node_arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config;
    EOF
  )
}



# --- ECS ASG --- #

resource "aws_autoscaling_group" "ecs" {
  name_prefix               = "demo-ecs-asg-"
  vpc_zone_identifier       = var.public_subnet_id
  min_size                  = 1
  max_size                  = 2
  health_check_grace_period = 30
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "demo-ecs-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}