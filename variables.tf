# ----------------------------------------------------------------
# Instance Variables

variable "instance_type" {
  description = "The type of instance to start."
  default     = "t2.micro"
}

variable "instance_key_name" {
  description = "The key name of the instance."
  default     = "master"
}

variable "instance_profile_name" {
  description = "The name of IAM instance profile for the instance."
}

variable "availability_zone" {
  description = "The AZ to start the instance in."
  default     = ""
}

variable "ebs_volume_id" {
  description = "The ID of EBS volume to store OpenVPN keys."
  default     = ""
}

# ----------------------------------------------------------------
# ECS Variables

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  default     = "vpn"
}

variable "ecs_service_name" {
  description = "The name of the VPN service."
  default     = "vpn"
}

variable "ecs_volume_data" {
  description = "The path of presented OpenVPN data on the host instance."
  default     = "/var/lib/docker-volumes/openvpn"
}

variable "ecs_volume_conf" {
  description = "The path of presented OpenVPN data on the host instance."
  default     = "/var/lib/docker-volumes/openvpn-conf"
}

# ----------------------------------------------------------------
# OpenVPN Variables

variable "ovpn_country" {
  description = "Country name for the CA."
  default     = "NZ"
}

variable "ovpn_province" {
  description = "State or province name for the CA."
  default     = "Auckland"
}

variable "ovpn_city" {
  description = "Locality name for the CA."
  default     = "Auckland"
}

variable "ovpn_company" {
  description = "Organization name for the CA."
}

variable "ovpn_section" {
  description = "Organizational unit name for the CA."
  default     = "VPN"
}

variable "ovpn_email" {
  description = "Email address for the CA."
}

variable "ovpn_domain" {
  description = "Domain name of the OpenVPN."
}

variable "ovpn_subnet" {
  default = "10.8.0.0/24"
}

variable "ovpn_proto" {
  default = "udp"
}

variable "ovpn_dev" {
  default = "tun0"
}

variable "ovpn_clients" {
  description = "List of client names to be created."
  type        = "list"
  default     = []
}
