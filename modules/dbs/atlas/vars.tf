variable "dev_url" {
  description = "URL тестовой бд для проверки изменений и валидации на предмет ошибок"
  type        = string
  sensitive   = true
}

variable "url" {
  description = "URL целевой базы данных для применения схемы"
  type        = string
  sensitive   = true
}

variable "src" {
  description = "Содержимое HCL-файла, определяющего желаемую схему БД."
  type        = string
}

# variable "lint_review_mode" {
#   description = "Политика проверки (линтования) схемы. 'ALWAYS=всегда ручная проверка', 'WARNING=..', 'ERROR=если ошибка, то проверка'."
#   type        = string
# }

# variable "lint_review_time" {
#   description = "Таймаут для ручной проверки линтования (например, '1s'). После 1 секунды сразу падает с ошибкой" 
#   type        = string
# }

variable "transaction_mode" {
  description = <<EOF
    Режим транзакции для применения схемы. none, file, all. 
    none: Нет транзакций. Каждая SQL-команда выполняется отдельно, без отката.
    file (по умолчанию)
    all: Вся последовательность сгенерированных DDL-команд выполняется в одной большой транзакции. Если что-то не так, все откатывается.
  EOF
  type        = string
  default     = "file"
}

variable "concurrent_index" {
  description = "Конфигурация для параллельного создания/удаления индексов, Стопить не стопить бд для других, когда создание/удаление таблиц"
  type = object({
    create = bool
    drop   = bool
  })
  default = {
    create = true
    drop   = true
  }
}

variable "skip" {
  description = "Политики пропуска изменений при диффе схемы. Все по умолчанию 'false' для полной декларативности."
  type = object({
    add_column         = bool
    add_foreign_key    = bool
    add_index          = bool
    add_schema         = bool
    add_table          = bool

    drop_column        = bool
    drop_foreign_key   = bool
    drop_index         = bool
    drop_schema        = bool
    drop_table         = bool

    modify_column      = bool
    modify_foreign_key = bool
    modify_index       = bool
    modify_schema      = bool
    modify_table       = bool
  })
  default = {
    add_column         = false
    add_foreign_key    = false
    add_index          = false
    add_schema         = false
    add_table          = false

    drop_column        = false
    drop_foreign_key   = false
    drop_index         = false
    drop_schema        = false
    drop_table         = false

    modify_column      = false
    modify_foreign_key = false
    modify_index       = false
    modify_schema      = false
    modify_table       = false
  }
}