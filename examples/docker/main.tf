locals {
  hostname = "master.server.address"
}

provider "docker" {
  host = "tcp://${local.hostname}:2376/"
}

module "ovpn" {
  source = "../../modules/docker/"

  # For remote usage
  # source = "<terraform-aws-openvpn.git>//modules/docker?ref=monorepo"

  ovpn_company = "Example"
  ovpn_email   = "support@example.com"
  ovpn_domain  = "example.vpn.domain"
  ovpn_subnet  = "10.10.0.0/24"

  volume_data = "/var/lib/docker-volumes/openvpn/data"
  volume_conf = "/var/lib/docker-volumes/openvpn/conf"

  remote_host = "${local.hostname}"
  remote_user = "pi"

  ovpn_clients = [
    "server@sample"
  ]
}
