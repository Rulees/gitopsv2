# Получаем существующий VPC по имени
data "yandex_vpc_network" "vpc" {
  # name      = "yc"
  network_id = "enphdr1gng2vd36babdd"
}

locals {
  # subnet = "yc-ru-central1-${substr(var.zone, -1, 1)}"  # Пример вычисления локальной переменной
  subnet = "yc-a"
}

# Получаем подсеть на основе зоны
data "yandex_vpc_subnet" "subnet" {
  name       = local.subnet
}