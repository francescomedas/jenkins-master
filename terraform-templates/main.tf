provider "aws" {
  region = "eu-west-1"
}

resource "aws_autoscaling_group" "master" {
  name                      = "jenkins-master"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = aws_launch_configuration.master.name
  health_check_type         = "ELB"
  health_check_grace_period = 900
  load_balancers            = ["${aws_elb.master.id}"]
  termination_policies      = ["OldestLaunchConfiguration"]
  vpc_zone_identifier       = [element(var.private_subnet_ids, 0)]
  depends_on                = [aws_launch_configuration.master]
  lifecycle {
    create_before_destroy = true
  }
  dynamic "tag" {
    for_each = var.resources_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_configuration" "master" {
  image_id        = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [aws_security_group.master.id]
  depends_on      = [aws_security_group.master]
  user_data       = data.template_file.master_user_data.rendered
  root_block_device {
    volume_size = 20
  }
  ebs_block_device {
    volume_size = 100
    device_name = "/dev/xvdf"
  }
}

data "template_file" "master_user_data" {
  template = "${file("${path.module}/startup-master.sh.tpl")}"

  vars = {
    efs_dns_name = aws_efs_file_system.master.dns_name
  }
}

resource "aws_elb" "master" {
  name            = "jenkins-master-elb"
  internal        = true
  security_groups = ["${aws_security_group.master.id}"]
  subnets         = var.public_subnet_ids

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    target              = "HTTP:80/_health_check"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 300
  connection_draining         = true
  connection_draining_timeout = 60

  tags = var.resources_tags
}

resource "aws_efs_mount_target" "master" {
  file_system_id  = aws_efs_file_system.master.id
  subnet_id       = element(var.private_subnet_ids, 0)
  security_groups = [aws_security_group.master-efs-storage.id]
}

resource "aws_efs_file_system" "master" {
  creation_token = "JenkinsMaster"
  tags           = var.resources_tags
}
