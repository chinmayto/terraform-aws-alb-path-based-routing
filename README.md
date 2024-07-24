# Implementing Path based routing with Application Load Balancer ALB and EC2 Instances using Terraform

In this tutorial, we'll leverage Terraform to set up an architecture that includes an Application Load Balancer (ALB) with path-based routing to EC2 instances hosting different web services.

Path-based routing is a method of directing traffic to different backend services based on the URL path of the incoming request. This approach allows you to host multiple applications or services on the same domain or load balancer, each accessible via a unique path. For example, you could route `example.com/app1` requests to one set of servers and `example.com/app2` requests to another.

## Architecture Overview
Before diving into the implementation details, let's outline the architecture we will be working with:

![alt text](/images/diagram.png)

## Step 1: Create VPC
First, we'll define a Virtual Private Cloud (VPC) and networking components
```terraform
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
```

## Step 2: Create Two Web Services on Separate EC2 Instances
Next, we'll provision two groups EC2 instances within our VPC, each running a distinct web service or application. These instances will serve as our backend servers behind the ALB.

First EC2 instance will be at default path and second instance will be at path pattern `/other/`, therefore keep the web files at `/var/www/html/other/` for second EC2 instance.

```terraform
################################################################################
# Get latest Amazon Linux 2 AMI
################################################################################
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

################################################################################
# Create the Linux EC2 Web server
################################################################################
resource "aws_instance" "web" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = var.instance_type
  key_name        = var.instance_key
  security_groups = var.security_group_ec2

  count     = length(var.public_subnets)
  subnet_id = element(var.public_subnets, count.index)


  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  instanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)
  instanceAZ=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
  pubHostName=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
  pubIPv4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
  privHostName=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
  privIPv4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  
  echo "<font face = "Verdana" size = "5">"                                       > /var/www/html/index.html
  echo "<center><h1>AWS Linux VM Deployed with Terraform</h1></center>"          >> /var/www/html/index.html
  echo "<center> <b>EC2 Instance Metadata</b> </center>"                         >> /var/www/html/index.html
  echo "<center> <b>Instance ID:</b> $instanceId </center>"                      >> /var/www/html/index.html
  echo "<center> <b>AWS Availablity Zone:</b> $instanceAZ </center>"             >> /var/www/html/index.html
  echo "<center> <b>Public Hostname:</b> $pubHostName </center>"                 >> /var/www/html/index.html
  echo "<center> <b>Public IPv4:</b> $pubIPv4 </center>"                         >> /var/www/html/index.html
  echo "<center> <b>Private Hostname:</b> $privHostName </center>"               >> /var/www/html/index.html
  echo "<center> <b>Private IPv4:</b> $privIPv4 </center>"                       >> /var/www/html/index.html
  echo "</font>"                                                                 >> /var/www/html/index.html
EOF

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-${count.index + 1}"
  })
}

################################################################################
# Create the Linux EC2 Web server - other instance
################################################################################
resource "aws_instance" "web_other" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = var.instance_type
  key_name        = var.instance_key
  security_groups = var.security_group_ec2

  count     = length(var.public_subnets)
  subnet_id = element(var.public_subnets, count.index)


  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  instanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)
  instanceAZ=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
  pubHostName=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
  pubIPv4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
  privHostName=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
  privIPv4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  
  mkdir -p /var/www/html/other
  echo "<font face = "Verdana" size = "5">"                                                 > /var/www/html/other/index.html
  echo "<center><h1>AWS Linux VM Deployed with Terraform - Other Instance</h1></center>"   >> /var/www/html/other/index.html
  echo "<center> <b>EC2 Instance Metadata</b> </center>"                                   >> /var/www/html/other/index.html
  echo "<center> <b>Instance ID:</b> $instanceId </center>"                                >> /var/www/html/other/index.html
  echo "<center> <b>AWS Availablity Zone:</b> $instanceAZ </center>"                       >> /var/www/html/other/index.html
  echo "<center> <b>Public Hostname:</b> $pubHostName </center>"                           >> /var/www/html/other/index.html
  echo "<center> <b>Public IPv4:</b> $pubIPv4 </center>"                                   >> /var/www/html/other/index.html
  echo "<center> <b>Private Hostname:</b> $privHostName </center>"                         >> /var/www/html/other/index.html
  echo "<center> <b>Private IPv4:</b> $privIPv4 </center>"                                 >> /var/www/html/other/index.html
  echo "</font>"                                                                           >> /var/www/html/other/index.html
EOF

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-${count.index + 1}-other"
  })
}
```

## Step 3: Configure ALB with Path-Based Routing
The core of our setup involves configuring the ALB to route incoming requests based on their URL paths:

ALB Configuration: We'll define an ALB with multiple target groups, each associated with one of our target group of EC2 instances. This setup allows the ALB to route traffic to different sets of instances based on the URL path.

Make sure health checks for alb target groups are correctly configured.

```terraform
################################################################################
# create application load balancer
################################################################################
resource "aws_lb" "aws-application_load_balancer" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_alb[0]]
  //subnets                    = [var.public_subnets[0],var.public_subnets[1] ,var.public_subnets[2],var.public_subnets[3]]
  subnets                    = tolist(var.public_subnets)
  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb"
  })
}

################################################################################
# create target groups for ALB - Default and Other
################################################################################
resource "aws_lb_target_group" "alb_target_group_default" {
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    timeout             = 5
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-tg-default"
  })
}

resource "aws_lb_target_group" "alb_target_group_other" {
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/other/"
    timeout             = 5
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-tg-other"
  })
}

```

Listener Rules: We'll create listener rules using Terraform to specify path-based routing logic. For instance, requests to `/*` will be forwarded to default target group, while requests to `/other/*` will be directed to another.



```terraform
################################################################################
# create a listener on port 80 with redirect action - Default and Other
################################################################################
resource "aws_lb_listener" "alb_http_listener_default" {
  load_balancer_arn = aws_lb.aws-application_load_balancer.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_default.id

  }
}

################################################################################
# create a listener rule for other listener
################################################################################
resource "aws_lb_listener_rule" "alb_rule_other" {
  listener_arn = aws_lb_listener.alb_http_listener_default.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_other.arn
  }
  condition {
    path_pattern {
      values = ["/other/"]
    }
  }
}

################################################################################
# Target Group Attachment with Instance
################################################################################

resource "aws_alb_target_group_attachment" "alb_tg_attach_default" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.alb_target_group_default.arn
  target_id        = element(var.instance_ids, count.index)
}


resource "aws_alb_target_group_attachment" "alb_tg_attach_other" {
  count            = length(var.instance_ids_other)
  target_group_arn = aws_lb_target_group.alb_target_group_other.arn
  target_id        = element(var.instance_ids_other, count.index)
}

```

## Steps to Run Terraform
Follow these steps to execute the Terraform configuration:
```terraform
terraform init
terraform plan 
terraform apply -auto-approve
```

Upon successful completion, Terraform will provide relevant outputs.
```terraform
Apply complete! Resources: 23 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name = "tf-lb-20240724121109991900000006-1464435819.us-east-1.elb.amazonaws.com"
ec2_instance_ids = [
  "i-0c3ec981cbc105993",
  "i-034025ab95d436bcb",
]
public_subnets = [
  "subnet-0bf0fb37d7fe382ac",
  "subnet-086da92937739db51",
]
security_group_alb = [
  "sg-0c1110387f85745d4",
]
security_groups_ec2 = [
  "sg-0ea78de50cb1702e2",
]
```

## Testing
ALB with a listner with 2 rules:
![alt text](/images/alb.png)

Listner rules Default and Other
![alt text](/images/listener.png)

ALB Resource Map:
![alt text](/images/resourcemap.png)

Default route EC2 web insances:
![alt text](/images/ec2a.png)
![alt text](/images/ec2b.png)

Path based route EC2 web instances:
![alt text](/images/ec2c.png)
![alt text](/images/ec2d.png)

All running instances:
![alt text](/images/instances.png)

## Cleanup
Remember to stop AWS components to avoid large bills.
```terraform
terraform destroy -auto-approve
```

## Conclusion
By following this guide and using Terraform for infrastructure as code, you can easily implement path-based routing with ALB and EC2 instances on AWS. This approach enhances scalability and simplifies management by consolidating multiple services under a single load balancer while maintaining clear separation based on URL paths.

## Resources
ALB Path Based Routing: https://repost.aws/knowledge-center/elb-achieve-path-based-routing-alb

Github Link: https://github.com/chinmayto/terraform-aws-alb-path-based-routing