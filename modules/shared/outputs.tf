output "server_conf" {
  value = "${templatefile("${path.module}/templates/server.conf", {
    domain  = "${var.ovpn_domain}"
    proto   = "${var.ovpn_proto}"
    dev     = "${var.ovpn_dev}"
    address = "${cidrhost(var.ovpn_subnet, 0)}"
    netmask = "${cidrnetmask(var.ovpn_subnet)}"
  })}"
}

output "client_conf" {
  value = "${templatefile("${path.module}/templates/client.ovpn", {
    domain = "${var.ovpn_domain}"
    proto  = "${var.ovpn_proto}"
    dev    = "${var.ovpn_dev}"
  })}"
}

output "server_script" {
  value = "${templatefile("${path.module}/templates/openvpn.sh", {
    country     = "${var.ovpn_country}"
    province    = "${var.ovpn_province}"
    city        = "${var.ovpn_city}"
    company     = "${var.ovpn_company}"
    section     = "${var.ovpn_section}"
    email       = "${var.ovpn_email}"
    domain      = "${var.ovpn_domain}"
    volume      = "${var.volume_data}"
    client_conf = "${var.volume_conf}/client.ovpn"
    clients_txt = "${var.volume_conf}/clients.txt"
  })}"
}
