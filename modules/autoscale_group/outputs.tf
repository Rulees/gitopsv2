output "instance_group_id" {
  description = "ID of the created instance group"
  value       = yandex_compute_instance_group.this.id
}

output "instance_group_name" {
  value = yandex_compute_instance_group.this.name
}

output "instance_ids" {
  description = "List of instance IDs in the group"
  value       = [for inst in yandex_compute_instance_group.this.instances : inst.instance_id]
}

output "external_ip" {
  description = "List of NAT IPs of instances"
  value       = flatten([
    for inst in yandex_compute_instance_group.this.instances :
    [for ni in inst.network_interface : ni.nat_ip_address]
  ])
}