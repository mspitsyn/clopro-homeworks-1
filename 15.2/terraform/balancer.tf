## balancer.tf

//
// Create a new Network Load Balancer (NLB).
//
resource "yandex_lb_network_load_balancer" "my_nlb" {
  name = "lmy-network-load-balancer"
  deletion_protection = "false"
  
  listener {
    name = "http-check"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_compute_instance_group.group-vms.load_balancer[0].target_group_id
    healthcheck {
      name = "http"
      interval = 2
      timeout = 1
      unhealthy_threshold = 2
      healthy_threshold = 5
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}