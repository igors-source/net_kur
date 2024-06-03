terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yandex_cloud_token 
  cloud_id  = "b1g6fo99h0qim9jv8gnk"
  folder_id = "b1g2495p8ldt10kjk28s"
  zone      = "ru-central1-a"
}

resource "yandex_iam_service_account" "ig-sa" {
  name        = "ig-sa"
  description = "service account to manage IG"
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = "b1g2495p8ldt10kjk28s"
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.ig-sa.id}"
}
####################################################################
#                         Виртуальные машины                       #                        
####################################################################
resource "yandex_compute_instance" "web-server1" {
  name        = "web-server1"
  hostname    = "web-server1"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"


  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80qjt4v3h9ukucg1di"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.s-ssh-traffic.id, yandex_vpc_security_group.s-webservers.id]
    ip_address         = "10.0.1.3"
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "web-server2" {
  name        = "web-server2"
  hostname    = "web-server2"
  zone        = "ru-central1-b"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80qjt4v3h9ukucg1di"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-2.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.s-ssh-traffic.id, yandex_vpc_security_group.s-webservers.id]
    ip_address         = "10.0.2.3"
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

####################################################################
#                         bastion-host                             #                        
####################################################################

resource "yandex_compute_instance" "bastion-host" {
  name        = "bastion-host"
  hostname    = "bastion-host"
  zone        = "ru-central1-d"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80qjt4v3h9ukucg1di"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-3.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.s-bastion-host.id]
    ip_address         = "10.0.3.10"
  }

  metadata = {
    user-data = "${file("./bastion_meta.yml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}



####################################################################
#                         ZABBIX                                   #                        
####################################################################

resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  zone        = "ru-central1-d"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80qjt4v3h9ukucg1di"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-3.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.s-public-zabbix.id, yandex_vpc_security_group.s-ssh-traffic.id]
    ip_address         = "10.0.3.5"
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

####################################################################
#                        ELASTIC                                   #                        
####################################################################

resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores         = 4
    memory        = 8
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = "fd80qjt4v3h9ukucg1di"
      size     = 15
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.s-elasticsearch.id, yandex_vpc_security_group.s-ssh-traffic.id]
    ip_address         = "10.0.1.4"
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}


####################################################################
#                        KIBANA                                    #                        
####################################################################


resource "yandex_compute_instance" "kibana" {
  name     = "kibana"
  hostname = "kibana"
  zone     = "ru-central1-d"
  platform_id = "standard-v3"
  
  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80qjt4v3h9ukucg1di"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-3.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.s-public-kibana.id, yandex_vpc_security_group.s-ssh-traffic.id]
    ip_address         = "10.0.3.6"
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}


####################################################################
#                        VPC NET                                   #                        
####################################################################

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "nat-route-table"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}


####################################################################
#                        VPC SUBNET                                #                        
####################################################################

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = "${yandex_vpc_route_table.rt.id}"
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = "${yandex_vpc_route_table.rt.id}"
}

resource "yandex_vpc_subnet" "subnet-3" {
  name           = "subnet3"
  zone           = "ru-central1-d"
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["10.0.3.0/24"]
  route_table_id = "${yandex_vpc_route_table.rt.id}"
}


####################################################################
#                        TARGET GROUP                              #                        
####################################################################

resource "yandex_alb_target_group" "target-group" {
  name = "target-group"

  target {
    subnet_id  = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address = "${yandex_compute_instance.web-server1.network_interface.0.ip_address}"
  }

  target {
    subnet_id  = "${yandex_vpc_subnet.subnet-2.id}"
    ip_address = "${yandex_compute_instance.web-server2.network_interface.0.ip_address}"
  }
}



####################################################################
#                        BACKEND GROUP                             #                        
####################################################################

resource "yandex_alb_backend_group" "backend-group" {
  name = "backend-group"

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.target-group.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "1s"
      interval            = "1s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}


####################################################################
#                        HTTP ROUTER                               #                        
####################################################################

resource "yandex_alb_http_router" "http-router" {
  name = "http-router"
}

resource "yandex_alb_virtual_host" "virtual-host" {
  name           = "virtual-host"
  http_router_id = yandex_alb_http_router.http-router.id
  route {
    name = "route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
          backend_group_id = yandex_alb_backend_group.backend-group.id
          timeout          = "3s"
      }
    }
  }
}


####################################################################
#                        L7 BALANCER                               #                        
####################################################################

resource "yandex_alb_load_balancer" "load-balancer" {
  
  name               = "load-balancer"
  network_id         = yandex_vpc_network.network-1.id
  security_group_ids = [yandex_vpc_security_group.s-public-alb.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-1.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-2.id
    }
  }

  listener {
    name = "listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http-router.id
      }
    }
  }
}


####################################################################
#                        ГРУППЫ БЕЗОПАСНОСТИ                       #                        
####################################################################


resource "yandex_vpc_security_group" "s-bastion-host" {
  name       = "s-bastion-host"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_vpc_security_group" "s-ssh-traffic" {
  name       = "s-ssh-traffic"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.0.0.0/21"]
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["10.0.0.0/21"]
  }
}


resource "yandex_vpc_security_group" "s-webservers" {
  name       = "s-webservers"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["10.0.0.0/21"]
  }

  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.0.0.0/21"]
  }
  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["10.0.0.0/21"]
  }

  ingress {
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["10.0.0.0/21"]
  }
  ingress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["10.0.0.0/21"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "yandex_vpc_security_group" "s-public-zabbix" {
  name       = "s-public-zabbix"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol = "TCP" 
    description = "allow zabbix connections from internet" 
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 80
  }
  ingress {
    protocol = "ICMP" 
    description = "allow ping" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "TCP" 
    description = "allow agent" 
    v4_cidr_blocks = ["10.0.0.0/21"]
    port = 10050
  }
  egress {
    protocol = "ANY" 
    description = "allow any outgoing connection" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_vpc_security_group" "s-elasticsearch" {
  name       = "s-elasticsearch"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.0.0.0/21"]
  }

  ingress {
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["10.0.0.0/21"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_vpc_security_group" "s-public-kibana" {
  name       = "s-public-kibana"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["10.0.0.0/21"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_vpc_security_group" "s-public-alb" {
  name       = "s-public-alb"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol          = "ANY"
    description       = "Health checks"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    predefined_target = "load_balancer_healthchecks"
  }

  ingress {
    protocol       = "TCP"
    description    = "allow HTTP connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


####################################################################
#                        СНАПШОТЫ                                  #                        
####################################################################

resource "yandex_compute_snapshot_schedule" "default" {
  name = "default"

  schedule_policy {
    expression = "0 0 * * *"
  }

  snapshot_count = 7

  snapshot_spec {
    description = "daily"
    labels = {
      snapshot-label = "snapshot-label-value"
    }
  }

  labels = {
    my-label = "my-label-value"
  }

  disk_ids = [yandex_compute_instance.bastion-host.boot_disk.0.disk_id,
    yandex_compute_instance.web-server1.boot_disk.0.disk_id,
    yandex_compute_instance.web-server2.boot_disk.0.disk_id,
    yandex_compute_instance.zabbix.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id]
}


####################################################################
#                        ВЫВЕСТИ ВНЕШНИЕ IP                        #                        
####################################################################

output "bastion-host" {
  value = yandex_compute_instance.bastion-host.network_interface.0.nat_ip_address
}
output "kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}
output "zabbix" {
  value = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}