################################################################################
# Create VPC and components
################################################################################

module "vpc" {
  source                        = "./modules/vpc"
  aws_region                    = var.aws_region
  vpc_cidr_block                = var.vpc_cidr_block
  enable_dns_hostnames          = var.enable_dns_hostnames
  vpc_public_subnets_cidr_block = var.vpc_public_subnets_cidr_block
  aws_azs                       = var.aws_azs
  common_tags                   = local.common_tags
  naming_prefix                 = local.naming_prefix
}

################################################################################
# Create Web Server Instances
################################################################################

module "web" {
  source             = "./modules/web"
  instance_type      = var.instance_type
  instance_key       = var.instance_key
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
  public_subnets     = module.vpc.public_subnets
  security_group_ec2 = module.vpc.security_group_ec2
}

################################################################################
# Create load balancer with target group
################################################################################

module "alb" {
  source             = "./modules/alb"
  aws_region         = var.aws_region
  aws_azs            = var.aws_azs
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnets     = module.vpc.public_subnets
  security_group_alb = module.vpc.security_group_alb
  instance_ids       = module.web.instance_ids
  instance_ids_other = module.web.instance_ids_other
}

