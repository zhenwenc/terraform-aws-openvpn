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
  volume_data   = "${var.volume_data}"
  volume_conf   = "${var.volume_conf}"
}

resource "null_resource" "openvpn_conf" {
  triggers = {
    script  = "${md5(module.shared.server_script)}"
    server  = "${md5(module.shared.server_conf)}"
    client  = "${md5(module.shared.client_conf)}"
    clients = "${md5(join("\n", var.ovpn_clients))}"
  }

  provisioner "remote-exec" {
    inline = [
      # Ensure the OpenVPN docker volume exists
      "sudo mkdir -p ${var.volume_conf}",
      "sudo chown ${var.remote_user}: ${var.volume_conf}",
    ]

    connection {
      type = "ssh"
      host = "${var.remote_host}"
      user = "${var.remote_user}"
    }
  }

  provisioner "file" {
    content     = "${module.shared.server_script}"
    destination = "${var.volume_conf}/openvpn.sh"

    connection {
      type = "ssh"
      host = "${var.remote_host}"
      user = "${var.remote_user}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x ${var.volume_conf}/openvpn.sh",
    ]

    connection {
      type = "ssh"
      host = "${var.remote_host}"
      user = "${var.remote_user}"
    }
  }

  provisioner "file" {
    content     = "${module.shared.server_conf}"
    destination = "${var.volume_conf}/openvpn.conf"

    connection {
      type = "ssh"
      host = "${var.remote_host}"
      user = "${var.remote_user}"
    }
  }

  provisioner "file" {
    content     = "${module.shared.client_conf}"
    destination = "${var.volume_conf}/client.ovpn"

    connection {
      type = "ssh"
      host = "${var.remote_host}"
      user = "${var.remote_user}"
    }
  }

  provisioner "file" {
    content     = "${join("\n", var.ovpn_clients)}\n"
    destination = "${var.volume_conf}/clients.txt"

    connection {
      type = "ssh"
      host = "${var.remote_host}"
      user = "${var.remote_user}"
    }
  }
}

resource "docker_container" "openvpn" {
  name    = "openvpn"
  image   = "zhenwenc/openvpn-arm"
  command = ["/opt/openvpn/openvpn.sh", "start-server"]

  capabilities {
    add = ["NET_ADMIN"]
  }

  ports {
    internal = 1194
    external = 1194
    protocol = "udp"
  }

  volumes {
    host_path      = "${var.volume_data}"
    container_path = "/etc/openvpn"
  }

  volumes {
    host_path      = "${var.volume_conf}"
    container_path = "/opt/openvpn"
  }

  depends_on = [null_resource.openvpn_conf]
}
