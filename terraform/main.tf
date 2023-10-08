# Переменные

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

# Провайдер

provider "yandex" {
  token        = "xxx"
  cloud_id     = "xxx"
  folder_id    = "xxx"
}

# Создание сети

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

# Создание подсетей

resource "yandex_vpc_subnet" "subnet1" {
  name = "subnet1"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet2" {
  name = "subnet2"
  zone = "ru-central1-b"
  network_id = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_vpc_subnet" "subnet3" {
  name = "subnet3"
  zone = "ru-central1-c"
  network_id = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.30.0/24"]
}

#=======================
#Создание vm1, vm2

resource "yandex_compute_instance" "web-server1" {
  name = "web-server1"
  zone = "ru-central1-a"

  resources{
    cores = 2
    core_fraction = 20
    memory = 4
  }

  boot_disk{
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size = 10
      description = "boot disk for web-server1"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

resource "yandex_compute_instance" "web-server2" {
  name = "web-server2"
  zone = "ru-central1-b"

  resources{
    cores = 2
    core_fraction = 20
    memory = 4
  }
 boot_disk{
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size = 10
      description = "boot disk for web-server1"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}
