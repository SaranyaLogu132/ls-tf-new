module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  prefix     = var.prefix
  vpc_cidr   = var.vpc_cidr
}

module "security" {
  source = "./modules/security"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  prefix      = var.prefix
}

module "alb" {
  source = "./modules/alb"

  environment       = var.environment
  prefix           = var.prefix
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_sg_id
}

module "asg" {
  source = "./modules/asg"

  environment       = var.environment
  prefix           = var.prefix
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.ec2_sg_id
  target_group_arn  = module.alb.target_group_arn
  instance_type     = "t2.micro"
}

module "rds" {
  source = "./modules/rds"

  environment        = var.environment
  prefix            = var.prefix
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.rds_sg_id
}
