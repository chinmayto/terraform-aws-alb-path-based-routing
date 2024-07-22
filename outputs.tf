output "public_subnets" {
  value = module.vpc.public_subnets
}

output "security_group_alb" {
  value = module.vpc.security_group_alb
}

output "security_groups_ec2" {
  value = module.vpc.security_group_ec2
}

output "ec2_instance_ids" {
  value = module.web.instance_ids
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

