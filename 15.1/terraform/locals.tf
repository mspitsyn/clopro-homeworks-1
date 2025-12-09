##locals.tf

locals {
  ssh-keys = file("~/.ssh/id_rsa.pub")
  ssh-private-keys = file("~/.ssh/id_rsa")
  cloud_id = "b1gchhnthvn0qe3v2rfb"
  folder_id = "b1gh2n9lu2pm397sqa8m"
  token = "y0__xDamLsEGMHdEyDr0OLjE-MJXOiYgG0lqcK8r0R4pjW8-Rh4"
}
