#[.......Root main.tf file ...........]#



#........VPC Module..................#

module "vpc" {
  source = "./modules/vpc"

}

#........VPC Module...................#

module "alb" {
  source                     = "./modules/alb"
  public_subnet_id           = module.vpc.public_subnet_id
  vpc_id                     = module.vpc.vpc_id
  aws_security_group_http_id = module.sg.aws_security_group_http_id
}




#.......Security Group Module .........#

module "sg" {
  source             = "./modules/sg"
  vpc_id             = module.vpc.vpc_id
  aws_vpc_cidr_block = module.vpc.aws_vpc_cidr_block
}




#.........IAM Module....................#

module "iam" {
  source = "./modules/IAM"
}




#.........ECS Module.....................#

module "ecs" {
  source                         = "./modules/ecs"
  aws_autoscaling_group_arn      = module.asg.aws_autoscaling_group_arn
  ecs_task_role_arn              = module.iam.ecs_task_role_arn
  ecs_exec_role_arn              = module.iam.ecs_exec_role_arn
  aws_security_group_ecs_task_id = module.sg.aws_security_group_ecs_task_id
  public_subnet_id               = module.vpc.public_subnet_id
  aws_lb_target_group_arn        = module.alb.aws_lb_target_group_arn
  aws_lb_target_group_app        = module.alb.aws_lb_target_group_app
}


#.........Auto_scalling Group Module...........#

module "asg" {
  source                            = "./modules/asg"
  aws_security_group_id             = module.sg.aws_security_group_id
  aws_iam_instance_profile_node_arn = module.iam.aws_iam_instance_profile_node_arn
  ecs_cluster_name                  = module.ecs.ecs_cluster_name
  public_subnet_id                  = module.vpc.public_subnet_id

}