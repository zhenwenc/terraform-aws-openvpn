# terraform-aws-openvpn

Terraform module which creates OpenVPN resources on AWS.

# Usage

``` hcl
module "vpn" {
  source = "zhenwenc/openvpn/aws"

  availability_zone     = "${data.aws_availability_zones.this.names[0]}"
  instance_profile_name = "${module.iam.ecs_instance_profile_name}"
  ebs_volume_id         = "${aws_ebs_volume.vpn.id}"
  ecs_cluster_name      = "${aws_ecs_cluster.vpn.name}"
  ovpn_company          = "Example Co."
  ovpn_email            = "support@example.com"
  ovpn_domain           = "vpn.example.com"
  ovpn_clients          = ["fred@vpn.example.com"]
}

resource "aws_ebs_volume" "vpn" {
  availability_zone = "${data.aws_availability_zones.this.names[0]}"
  encrypted         = true
  type              = "gp2"
  size              = 1
}

data "aws_availability_zones" "this" {
  state = "available"
}
```

## License

MIT Licensed. See LICENSE for full details.
