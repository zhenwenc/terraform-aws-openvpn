module "shared" {
  source = "../shared/"

  ovpn_country  = "${var.ovpn_country}"
  ovpn_province = "${var.ovpn_province}"
  ovpn_city     = "${var.ovpn_city}"
  ovpn_company  = "${var.ovpn_company}"
  ovpn_section  = "${var.ovpn_section}"
  ovpn_email    = "${var.ovpn_email}"
  ovpn_domain   = "${var.ovpn_domain}"
  ovpn_subnet   = "${var.ovpn_subnet}"
  ovpn_proto    = "${var.ovpn_proto}"
  ovpn_dev      = "${var.ovpn_dev}"
  volume_data   = "${var.ecs_volume_data}"
  volume_conf   = "${var.ecs_volume_conf}"
}

resource "null_resource" "openvpn_conf" {
  triggers {
    instance = "${aws_instance.this.id}"
    server   = "${md5(data.template_file.openvpn_server.rendered)}"
    client   = "${md5(data.template_file.openvpn_client.rendered)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p ${var.ecs_volume_conf}",
      "sudo chown ec2-user: ${var.ecs_volume_conf}",
    ]

    connection {
      type = "ssh"
      host = "${aws_instance.this.public_ip}"
      user = "ec2-user"
    }
  }

  provisioner "file" {
    content     = "${data.template_file.openvpn_server.rendered}"
    destination = "${var.ecs_volume_conf}/openvpn.conf"

    connection {
      type = "ssh"
      host = "${aws_instance.this.public_ip}"
      user = "ec2-user"
    }
  }

  provisioner "file" {
    content     = "${data.template_file.openvpn_client.rendered}"
    destination = "${var.ecs_volume_conf}/client.ovpn"

    connection {
      type = "ssh"
      host = "${aws_instance.this.public_ip}"
      user = "ec2-user"
    }
  }
}

resource "null_resource" "openvpn_clients" {
  triggers {
    instance = "${aws_instance.this.id}"
    clients  = "${md5(join("\n", var.ovpn_clients))}"
  }

  provisioner "file" {
    content     = "${join("\n", var.ovpn_clients)}\n"
    destination = "${var.ecs_volume_conf}/clients.txt"

    connection {
      type = "ssh"
      host = "${aws_instance.this.public_ip}"
      user = "ec2-user"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /usr/bin/openvpn load-clients",
    ]

    connection {
      type = "ssh"
      host = "${aws_instance.this.public_ip}"
      user = "ec2-user"
    }
  }

  # Requires volume access permission
  depends_on = ["null_resource.openvpn_conf"]
}

# ----------------------------------------------------------------

resource "aws_ecs_cluster" "this" {
  name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_service" "this" {
  name                               = "${var.ecs_service_name}"
  cluster                            = "${aws_ecs_cluster.this.arn}"
  task_definition                    = "${aws_ecs_task_definition.this.arn}"
  scheduling_strategy                = "DAEMON"
  desired_count                      = 1
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}

resource "aws_ecs_task_definition" "this" {
  family                = "openvpn"
  container_definitions = "${data.template_file.ecs_task_def.rendered}"

  volume {
    name      = "openvpn-data"
    host_path = "${var.ecs_volume_data}"
  }

  volume {
    name      = "openvpn-conf"
    host_path = "${var.ecs_volume_conf}"
  }
}

data "template_file" "ecs_task_def" {
  template = "${file("${path.module}/templates/task-def.json")}"

  vars {
    hash = "${md5(data.template_file.openvpn_server.rendered)}"
  }
}
