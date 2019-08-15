# ----------------------------------------------------------------
# Instance Variables

variable "volume_data" {
  description = "The path of docker volume to store OpenVPN keys."
}

variable "volume_conf" {
  description = "The path of docker volume to store OpenVPN configs."
}

variable "remote_host" {
  description = "The hostname of remote VPS instance."
}

variable "remote_user" {
  description = "The user used to ssh into the remote instance."
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

# ----------------------------------------------------------------
# Registered Clients

variable "ovpn_clients" {
  description = "List of client names to be created."
  type        = "list"
  default     = []
}
