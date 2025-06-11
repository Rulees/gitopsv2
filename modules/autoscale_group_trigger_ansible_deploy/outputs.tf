output "trigger_id" {
  description = "ID of the created trigger"
  value       = yandex_function_trigger.timer.id
}

output "function_id" {
  description = "ID of the push-custom-metric Cloud Function"
  value       = yandex_function.trigger_gitlab_deploy.id
}

output "function_name" {
  description = "NAME of the push-custom-metric Cloud Function"
  value = yandex_function.trigger_gitlab_deploy.name
}