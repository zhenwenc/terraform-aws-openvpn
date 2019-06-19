resource "aws_instance" "this" {
  ami                  = "${data.aws_ami.this.image_id}"
  availability_zone    = "${var.availability_zone}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.instance_key_name}"
  iam_instance_profile = "${var.instance_profile_name}"
  user_data            = "${data.template_cloudinit_config.user_data.rendered}"

  # The EC2 instance should always be assigned to the default
  # VPC since tunnel traffics are useing the public interface.
  security_groups = ["${aws_security_group.this.name}"]

  tags {
    Name = "vpn"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count = "${var.ebs_volume_id != "" ? 1 : 0}"

  device_name  = "/dev/sdf"
  force_detach = true
  volume_id    = "${var.ebs_volume_id}"
  instance_id  = "${aws_instance.this.id}"
}

resource "aws_security_group" "this" {
  name_prefix = "vpn-instance"

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "vpn"
  }
}

data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-2018.03.u-amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_init.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.user_data.rendered}"
  }
}

data "template_file" "cloud_init" {
  template = "${file("${path.module}/templates/cloud-init.yml")}"

  vars {
    openvpn = "${data.template_file.openvpn_script.rendered}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user-data.sh")}"

  vars {
    ecs_cluster    = "${aws_ecs_cluster.this.name}"
    ecs_attributes = ""
    ecs_volume     = "${var.ecs_volume_data}"
    ebs_volume     = "/dev/xvdf"
  }
}

data "template_file" "openvpn_script" {
  template = "${file("${path.module}/templates/openvpn.sh")}"

  vars {
    country     = "${var.ovpn_country}"
    province    = "${var.ovpn_province}"
    city        = "${var.ovpn_city}"
    company     = "${var.ovpn_company}"
    section     = "${var.ovpn_section}"
    email       = "${var.ovpn_email}"
    domain      = "${var.ovpn_domain}"
    volume      = "${var.ecs_volume_data}"
    client_conf = "${var.ecs_volume_conf}/client.ovpn"
    clients_txt = "${var.ecs_volume_conf}/clients.txt"
  }
}
