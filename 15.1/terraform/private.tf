## private.tf

//
// Variables.
//

variable "private_subnet" {
  type        = string
  default     = "private"
  description = "subnet name"
}

variable "private_cidr" {
  type        = list(string)
  default     = ["192.168.20.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "yandex_compute_instance_private" {
  type        = list(object({
    vm_name = string
    cores = number
    memory = number
    core_fraction = number
    hostname = string
    platform_id = string
  }))

  default = [{
      vm_name = "private"
      cores         = 2
      memory        = 2
      core_fraction = 5
      hostname = "private"
      platform_id = "standard-v1"
    }]
}

variable "boot_disk_private" {
  type        = list(object({
    size = number
    type = string
    image_id = string
    }))
    default = [ {
    size = 10
    type = "network-hdd"
    image_id = "fd8pbf0hl06ks8s3scqk"
  }]
}

//
// Create a new VPC Subnet.
//
resource "yandex_vpc_subnet" "private" {
  v4_cidr_blocks = var.private_cidr
  zone           = var.default_zone
  network_id     = yandex_vpc_network.network.id
  route_table_id = yandex_vpc_route_table.private-route.id
}

//
// Create a new VPC Route Table.
//
resource "yandex_vpc_route_table" "private-route" {
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.yandex_compute_instance_nat[0].ip_address
  }
}

//
// Create a new Compute Instance
//
resource "yandex_compute_instance" "private" {
  name        = var.yandex_compute_instance_private[0].vm_name
  platform_id = var.yandex_compute_instance_private[0].platform_id
  hostname = var.yandex_compute_instance_private[0].hostname

  resources {
    cores         = var.yandex_compute_instance_private[0].cores
    memory        = var.yandex_compute_instance_private[0].memory
    core_fraction = var.yandex_compute_instance_private[0].core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk_private[0].image_id
      type     = var.boot_disk_private[0].type
      size     = var.boot_disk_private[0].size
    }
  }

  metadata = {
    ssh-keys = "user:${local.ssh-keys}"
    serial-port-enable = "1"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.private.id
    nat        = false
  }
  scheduling_policy {
    preemptible = true
  }
}



