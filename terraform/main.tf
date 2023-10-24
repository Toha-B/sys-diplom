terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token        = "xxx"
  cloud_id     = "xxx"
  folder_id    = "xxx"
}

#=====================================================

# Security bastion host

resource "yandex_vpc_security_group" "group-bastion-host" {
  name        = "My security group bastion host"
  network_id  = yandex_vpc_network.network-1.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group to allow incoming ssh traffic
resource "yandex_vpc_security_group" "group-ssh-traffic" {
  name        = "My security group ssh traffic"
  network_id  = yandex_vpc_network.network-1.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  ingress {
    protocol       = "ICMP"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }
}

# Security group webservers
resource "yandex_vpc_security_group" "group-webservers" {
  name        = "My security group webservers"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 80
   # predefined_target = "loadbalancer_healthchecks"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  ingress {
    protocol       = "TCP"
    port           = 4040
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  ingress {
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
# Security group prometheus
resource "yandex_vpc_security_group" "group-prometheus" {
  name        = "My security group prometheus"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Security group public network grafana
resource "yandex_vpc_security_group" "group-public-network-grafana" {
  name        = "My security group public network grafana"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = ["192.168.30.3/32"]
  }
}

# Security group elasticsearch
resource "yandex_vpc_security_group" "group-elasticsearch" {
  name        = "My security group elasticsearch"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  egress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }
}

# Security group public network kibana
resource "yandex_vpc_security_group" "group-public-network-kibana" {
  name        = "My security group public network kibana"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["192.168.30.22/32"]
  }
}
# Security group public application load balancer
resource "yandex_vpc_security_group" "group-public-network-alb" {
  name        = "My security group public network application load balancer"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

#=======================================================

# network

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

# subnet

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

# bastion host

resource "yandex_compute_instance" "bastion-host" {

  name = "bastion-host"
  zone = "ru-central1-c"

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80iibe8asp4inkhuhr"
      size = 13
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet3.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-bastion-host.id]
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }
}

#===================================================

#web-server-1

resource "yandex_compute_instance" "nginxserver1" {
  name = "nginxserver1"
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
      description = "boot disk for nginx_server1"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.yaml")}"
  }
}

#web-server-2

resource "yandex_compute_instance" "nginxserver2" {
  name = "nginxserver2"
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
      description = "boot disk for nginx_server1"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.yaml")}"
  }
}

#===================================================

# target group

resource "yandex_alb_target_group" "my-target-group" {
  name      = "my-target-group"
  #region_id = "ru-central1"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet1.id}"
    ip_address   = "${yandex_compute_instance.nginxserver1.network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.subnet2.id}"
    ip_address   = "${yandex_compute_instance.nginxserver2.network_interface.0.ip_address}"
  }
}

# Backend

resource "yandex_alb_backend_group" "my-backend-group" {
  name      = "my-backend-group"

  http_backend {
    name = "my-http-backend"
    weight = 1
    port = 80
    target_group_ids = ["${yandex_alb_target_group.my-target-group.id}"]
    healthcheck {
      timeout = "1s"
      interval = "1s"
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

#=======================================================================

# HTTP router

resource "yandex_alb_http_router" "my-http-router" {
  name      = "my-http-router"
}

#=======================================================================

# hosts

resource "yandex_alb_virtual_host" "my-virtual-host" {
  name      = "my-virtual-host"
  http_router_id = yandex_alb_http_router.my-http-router.id
  route {
    name = "my-route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.my-backend-group.id
        timeout = "3s"
      }
    }
  }
}

#======================================================================

# networkloadbalancer

resource "yandex_alb_load_balancer" "my-network-load-balancer" {
  name        = "my-load-balancer"

  network_id  = yandex_vpc_network.network-1.id
  security_group_ids = [yandex_vpc_security_group.group-public-network-alb.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet1.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet2.id
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.my-http-router.id
      }
    }
  }
}



