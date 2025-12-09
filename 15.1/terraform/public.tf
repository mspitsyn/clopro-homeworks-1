## public.tf

//
// Variables.
//
variable "public_subnet" {
  type        = string
  default     = "public"
  description = "subnet name"
}

variable "public_cidr" {
  type        = list(string)
  default     = ["192.168.10.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "yandex_compute_instance_public" {
  type        = list(object({
    vm_name = string
    cores = number
    memory = number
    core_fraction = number
    hostname = string
    platform_id = string
  }))

  default = [{
      vm_name = "public"
      cores         = 2
      memory        = 2
      core_fraction = 5
      hostname = "public"
      platform_id = "standard-v1"
    }]
}

variable "boot_disk_public" {
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

variable "yandex_compute_instance_nat" {
  type        = list(object({
    vm_name = string
    cores = number
    memory = number
    core_fraction = number
    hostname = string
    platform_id = string
    ip_address = string
  }))

  default = [{
      vm_name = "nat"
      cores         = 2
      memory        = 2
      core_fraction = 5
      hostname = "nat"
      platform_id = "standard-v1"
      ip_address = "192.168.10.254"
    }]
}

variable "boot_disk_nat" {
  type        = list(object({
    size = number
    type = string
    image_id = string
    }))
    default = [ {
    size = 10
    type = "network-hdd"
    image_id = "fd80mrhj8fl2oe87o4e1"
  }]
}

//
// Create a new VPC Subnet.
//
resource "yandex_vpc_subnet" "public" {
  name           = var.public_subnet
  zone           = var.default_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = var.public_cidr
}

//
// Create a new NAT-instance
//
resource "yandex_compute_instance" "nat" {
  name        = var.yandex_compute_instance_nat.vm_name
  platform_id = var.yandex_compute_instance_nat.platform_id
  hostname = var.yandex_compute_instance_nat.hostname

  resources {
    cores         = var.yandex_compute_instance_nat.cores
    memory        = var.yandex_compute_instance_nat.memory
    core_fraction = var.yandex_compute_instance_nat.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk_nat.image_id
      type     = var.boot_disk_nat.type
      size     = var.boot_disk_nat.size
    }
  }

  metadata = var.metadata

  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    nat        = true
    ip_address = var.yandex_compute_instance_nat.ip_address
  }
  scheduling_policy {
    preemptible = true
  }
}

//
// Create a new Compute Instance
// 
resource "yandex_compute_instance" "public" {
  name        = var.yandex_compute_instance_public.vm_name
  platform_id = var.yandex_compute_instance_public.platform_id
  hostname = var.yandex_compute_instance_public.hostname

  resources {
    cores         = var.yandex_compute_instance_public.cores
    memory        = var.yandex_compute_instance_public.memory
    core_fraction = var.yandex_compute_instance_public.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk_public.image_id
      type     = var.boot_disk_public.type
      size     = var.boot_disk_public.size
    }
  }

  metadata = var.metadata

  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    nat        = true
  }
  scheduling_policy {
    preemptible = true
  }
}