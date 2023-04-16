variable "metal_lb_ip_range" {
  type = string
  description = "Metal LB IP range. Example: '192.168.30.80-192.168.30.90'"
}

variable "apiserver_endpoint" {
  type = string
  description = "apiserver_endpoint is virtual ip-address which will be configured on each master"
}

variable "system_timezone" {
  type = string
  description = "Set your timezone"
}

variable "k3s_token" {
  type = string
  description = <<EOF
    k3s_token is required  masters can talk together securely
    this token should be alpha numeric only
  EOF
  sensitive = true
}
