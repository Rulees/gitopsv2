resource "yandex_compute_disk" "boot-disk-1" {
  name     = "boot-disk-1"
  type     = "network-ssd"
  zone     = "ru-central1-a"
  size     = "15"
  image_id = "fd8bpal18cm4kprpjc2m"
}

resource "yandex_compute_instance" "this" {
  name = "vm"
  platform_id = "standard-v3"

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-1.id
  }

  labels = {
    env     = "dev"
    app     = "loadbalance"
    service = "fastapi"
  }

  network_interface {
    subnet_id = "e9bfgc27v0b7pgnac64f"
    ip_address = "10.10.1.10"
    nat = true
  }

  allow_stopping_for_update = true
  
  metadata = {
    user-data = templatefile("cloud-init.yml", {
      username = "melnikov"
      # ssh_key = file("/root/.ssh/YC.pub")
      ssh_key = file("/root/project_gitlab/secrets/admin/yc_ssh_key.pub")
    })
  }
}