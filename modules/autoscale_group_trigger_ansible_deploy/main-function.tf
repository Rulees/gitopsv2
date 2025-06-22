locals {
  function_name            = "${var.project_prefix}--${var.function_name}-${random_id.this.hex}--${var.env}"
  function_path            = "${path.module}/function"
  sa_key_json              = file(var.sa_key_path)
  archive_local            = "${local.function_path}.zip"
}

resource "local_file" "sa_key_json" {
  filename                 = "${local.function_path}/sa_key.json"
  content                  = local.sa_key_json
}

# Установка зависимостей
resource "null_resource" "install_python_deps" {
  provisioner "local-exec" {
    command = <<EOT
      echo "📦 Installing Python deps..."
      rm -rf ${local.function_path}/libs
      pip install -r ${local.function_path}/requirements.txt -t ${local.function_path}/libs
    EOT
  }

  triggers = {
    requirements_hash      = filesha256("${local.function_path}/requirements.txt")
  }
}

# Архивация всей функции
data "archive_file" "function_zip" {
  type                     = "zip"
  source_dir               = local.function_path
  output_path              = local.archive_local
  depends_on               = [local_file.sa_key_json, null_resource.install_python_deps]
}


resource "null_resource" "upload_function_zip" {

  provisioner "local-exec" {
    command = <<EOT
      echo "📤 Uploading ZIP to Object Storage..."
      aws s3 cp ${local.archive_local} s3://${var.bucket_name}/${var.object_name} --endpoint-url=https://storage.yandexcloud.net
    EOT
  }

  triggers = {
    archive_sha            = data.archive_file.function_zip.output_sha256
  }

  depends_on               = [data.archive_file.function_zip]
}

resource "null_resource" "cleanup_function_zip" {
provisioner "local-exec" {
  command = <<EOT
    echo "🧹 Cleaning up sensitive files..."
    rm -f ${local.function_path}/sa_key.json
    echo "✅ sa_key.json removed"
  EOT
}
  depends_on               = [null_resource.upload_function_zip]
}

resource "yandex_function" "trigger_gitlab_deploy" {
  description              = "Function to trigger GitLab pipeline for deploying new instances as fastapi backend"
  name                     = local.function_name
  service_account_id       = var.service_account_id
  connectivity {network_id = var.network_id}
  labels                   = var.labels

  runtime                  = "python311"
  entrypoint               = "main.handler"
  memory                   = 512
  execution_timeout        = 60
  user_hash                = data.archive_file.function_zip.output_base64sha256

  package {
    bucket_name            = var.bucket_name
    object_name            = var.object_name
  }

  environment = {
    FOLDER_ID              = var.folder_id
    SA_ID                  = var.service_account_id
    ENV                    = var.env
    APP                    = var.app
    SERVICE                = var.service
    SUBSERVICE             = var.subservice
    GITLAB_TRIGGER_TOKEN   = var.gitlab_trigger_token
    GITLAB_PROJECT_ID      = var.gitlab_project_id
    GITLAB_BRANCH          = var.gitlab_branch
    INSTANCE_GROUP_ID      = var.instance_group_id
  }
  depends_on               = [null_resource.cleanup_function_zip]
}