output "instance_public_ip_addresses" {
  description = "The external IP addresses of the instances."
  value       = yandex_compute_instance.this.network_interface[0].nat_ip_address
}