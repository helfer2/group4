
resource "aws_vpc" "awsvpc" {
  cidr_block           = "125.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
}

resource "aws_internet_gateway" "awsipg" {
  vpc_id = "${aws_vpc.awsvpc.id}"
}

resource "aws_subnet" "public_1a" {
  vpc_id            = "${aws_vpc.awsvpc.id}"
  availability_zone = "ap-northeast-2a"
  cidr_block        = "125.0.1.0/24"
}


resource "aws_subnet" "public_1d" {
  vpc_id            = "${aws_vpc.awsvpc.id}"
  availability_zone = "ap-northeast-2b"
  cidr_block        = "125.0.2.0/24"
}

resource "aws_eip" "awseip" {
  vpc = false
}
resource "aws_eip" "awseip2" {
  vpc = false
}

resource "aws_route_table" "awsrtp" {
  vpc_id = "${aws_vpc.awsvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.awsipg.id}"
  }
}


resource "aws_nat_gateway" "natgate_1a" {
  allocation_id = "${aws_eip.awseip.id}"
  subnet_id     = "${aws_subnet.public_1a.id}"
}

resource "aws_nat_gateway" "natgate_1d" {
  allocation_id = "${aws_eip.awseip2.id}"
  subnet_id     = "${aws_subnet.public_1d.id}"
}


resource "aws_route_table_association" "awsrtp1a" {
  subnet_id      = "${aws_subnet.public_1a.id}"
  route_table_id = "${aws_route_table.awsrtp.id}"
}


resource "aws_route_table_association" "awsrtp1d" {
  subnet_id      = "${aws_subnet.public_1d.id}"
  route_table_id = "${aws_route_table.awsrtp.id}"
}

resource "aws_default_security_group" "awssecurity" {
  vpc_id = "${aws_vpc.awsvpc.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 

resource "aws_default_network_acl" "awsnetworkacl" {
  default_network_acl_id = "${aws_vpc.awsvpc.default_network_acl_id}"

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  subnet_ids = [
    "${aws_subnet.public_1a.id}",
  ]
}

variable "amazon_linux" {
    default = "ami-0be3e6f84d3b968cd"
}

resource "aws_security_group" "webserverSecurutyGroup" {
  name        = "webserverSecurutyGroup"
  description = "open ssh port for webserverSecurutyGroup"

  vpc_id = "${aws_vpc.awsvpc.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "group4_vm" {
  ami               = "${var.amazon_linux}"
  availability_zone = "ap-northeast-2a"
  instance_type     = "t2.micro"
  key_name = "group4key"
  vpc_security_group_ids = ["${aws_security_group.webserverSecurutyGroup.id}"]

  subnet_id                   = "${aws_subnet.public_1a.id}"
  associate_public_ip_address = true
}
/*
resource "aws_launch_configuration" "launchconfig" {
    name_prefix = "launchconfig"
    image_id = "${var.amazon_linux}"    
    instance_type = "t2.micro"
    key_name = "group4key"
    security_groups = ["${aws_security_group.webserverSecurutyGroup.id}"]
}

resource "aws_autoscaling_group" "group4_autoscaling" {
    name = "group4_autoscaling"
    vpc_zone_identifier = ["${aws_subnet.public_1a.id},"]
    launch_configuration = "${aws_launch_configuration.launchconfig.name}"
    min_size = 1
    max_size = 3
    health_check_grace_period = 300
    health_check_type = "EC2"
    force_delete = true
    tag {
        key = "Name"
        value = "ec2 instance"
        propagate_at_launch = true
    }
}


resource "aws_lb" "alb" {  
  name            = "alb"  
//  subnets         = ["${aws_subnet.public_1a.id}"]
  security_groups = ["${aws_security_group.webserverSecurutyGroup.id}"]
  
  internal        = false 
  idle_timeout    = 60   
}

resource "aws_lb_target_group" "alb_target_group" {  
  name     = "alb-target-group4"  
  port     = "80"  
  protocol = "HTTP"  
  vpc_id   = "${aws_vpc.awsvpc.id}"   

  stickiness {    
    type            = "lb_cookie"    
    cookie_duration = 1800    
    enabled         = true 
  }   
  health_check {    
    healthy_threshold   = 3    
    unhealthy_threshold = 10    
    timeout             = 5    
    interval            = 10    
    path                = "/"    
    port                = 80
  }
}

resource "aws_lb_listener" "alb_listener" {  
  load_balancer_arn = "${aws_lb.alb.arn}"  
  port              = 80  
  protocol          = "http"
  
  default_action {    
    target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
    type             = "forward"  
  }
}

resource "aws_autoscaling_attachment" "alb_autoscale" {
  alb_target_group_arn   = "${aws_lb_target_group.alb_target_group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.group4_autoscaling.id}"
}
*/
