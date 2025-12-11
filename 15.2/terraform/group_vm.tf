## group_vm.tf

//
// Variables
//
variable "yandex_compute_instance_groupvms" {
  type        = list(object({
    name = string
    cores = number
    memory = number
    core_fraction = number
    platform_id = string
  }))

  default = [{
      name = "lamp-group"
      cores         = 2
      memory        = 2
      core_fraction = 5
      platform_id = "standard-v1"
    }]
}

variable "boot_disk" {
  type        = list(object({
    size = number
    type = string
    image_id = string
    }))
    default = [ {
    size = 10
    type = "network-hdd"
    image_id = "fd827b91d99psvq5fjit"
  }]
}

//
// Create service account for group VM
//
resource "yandex_iam_service_account" "groupvm-sa" {
  name        = "groupvm-sa"
  description = "Сервисный аккаунт для управления группой ВМ."
}

//
// Role foe service account
// 
resource "yandex_resourcemanager_folder_iam_member" "group-editor" {
  folder_id  = local.folder_id
  role       = "editor"
  member     = "serviceAccount:${yandex_iam_service_account.groupvm-sa.id}"
  depends_on = [
    yandex_iam_service_account.groupvm-sa,
  ]
}

//
// Create a new Compute Instance Group (IG)
//
resource "yandex_compute_instance_group" "group-vms" {
  name                = var.yandex_compute_instance_groupvms[0].name
  folder_id           = local.folder_id
  service_account_id  = yandex_iam_service_account.groupvm-sa.id
  deletion_protection = false
  depends_on          = [yandex_resourcemanager_folder_iam_member.group-editor]
  instance_template {
    platform_id = var.yandex_compute_instance_groupvms[0].platform_id
    resources {
      memory = var.yandex_compute_instance_groupvms[0].memory
      cores  = var.yandex_compute_instance_groupvms[0].cores
      core_fraction = var.yandex_compute_instance_groupvms[0].core_fraction
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.boot_disk[0].image_id
        type     = var.boot_disk[0].type
        size     = var.boot_disk[0].size
      }
    }
    network_interface {
      network_id = yandex_vpc_network.network.id
      subnet_ids = ["${yandex_vpc_subnet.public.id}"]
      nat = true
    }
 
    scheduling_policy {
    preemptible = true
  }

    metadata = {
    ssh-keys = "user:${local.ssh-keys}"
    serial-port-enable = "1"
    user-data  = <<EOF
#!/bin/bash
export PUBLIC_IPV4=$(curl ifconfig.me)  
echo instance: $(hostname), IP Address: $PUBLIC_IPV4 > /var/www/html/index.html  
echo https://mspitsyn-2025.website.yandexcloud.net >> /var/www/html/index.html  
EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.default_zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  health_check {
    interval = 30
    timeout  = 10
    tcp_options {
      port = 80
    }
  }

    load_balancer {
        target_group_name = "lamp-group"
    }
}