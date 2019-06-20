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

data "template_file" "openvpn_server" {
  template = "${file("${path.module}/templates/server.conf")}"

  vars {
    domain  = "${var.ovpn_domain}"
    proto   = "${var.ovpn_proto}"
    dev     = "${var.ovpn_dev}"
    address = "${cidrhost(var.ovpn_subnet, 0)}"
    netmask = "${cidrnetmask(var.ovpn_subnet)}"
  }
}

data "template_file" "openvpn_client" {
  template = "${file("${path.module}/templates/client.ovpn")}"

  vars {
    domain = "${var.ovpn_domain}"
    proto  = "${var.ovpn_proto}"
    dev    = "${var.ovpn_dev}"
  }
}
