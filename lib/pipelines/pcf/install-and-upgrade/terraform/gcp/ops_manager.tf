resource "google_compute_instance" "ops-manager" {
  name         = "${var.prefix}-ops-manager"
  depends_on   = ["google_compute_subnetwork.subnet-ops-manager"]
  machine_type = "n1-standard-2"
  zone         = "${var.gcp_zone_1}"

  tags = ["${var.prefix}", "${var.prefix}-opsman"]

  boot_disk {
    initialize_params {
      image = "${var.pcf_opsman_image_name}"
      size  = 160
    }
  }

  attached_disk {
    source = "${google_compute_disk.opsman-data-disk.self_link}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-ops-manager.name}"
  }

  metadata {
    ssh-keys = "ubuntu:${data.terraform_remote_state.bootstrap.default_openssh_public_key}"
  }
}

resource "null_resource" "ops-manager" {
  provisioner "file" {
    content     = "${data.template_file.export-installation.rendered}"
    destination = "/home/ubuntu/export-installation.sh"
  }

  provisioner "file" {
    content     = "${data.template_file.import-installation.rendered}"
    destination = "/home/ubuntu/import-installation.sh"
  }

  provisioner "file" {
    content     = "${data.template_file.mount-opsman-data-volume.rendered}"
    destination = "/home/ubuntu/mount-opsman-data-volume.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0744 /home/ubuntu/export-installation.sh",
      "chmod 0744 /home/ubuntu/import-installation.sh",
      "chmod 0744 /home/ubuntu/mount-opsman-data-volume.sh",
      "/home/ubuntu/mount-opsman-data-volume.sh",
      "/home/ubuntu/import-installation.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "/home/ubuntu/export-installation.sh",
    ]

    when = "destroy"
  }

  triggers {
    export-installation      = "${md5(data.template_file.export-installation.rendered)}"
    import-installation      = "${md5(data.template_file.import-installation.rendered)}"
    mount-opsman-data-volume = "${md5(data.template_file.mount-opsman-data-volume.rendered)}"
  }

  connection {
    type        = "ssh"
    host        = "${google_dns_record_set.ops-manager-dns.name}"
    user        = "ubuntu"
    private_key = "${data.terraform_remote_state.bootstrap.default_openssh_private_key}"
  }

  depends_on = ["google_compute_instance.ops-manager"]
}

data "template_file" "export-installation" {
  template = "${file("${path.module}/export-installation.sh")}"

  vars {
    opsman_dns_name = "${substr(
      google_dns_record_set.ops-manager-dns.name, 0, length(google_dns_record_set.ops-manager-dns.name)-1)}"

    opsman_admin_password = "${data.terraform_remote_state.bootstrap.opsman_admin_password}"
  }
}

data "template_file" "import-installation" {
  template = "${file("${path.module}/import-installation.sh")}"

  vars {
    opsman_dns_name = "${substr(
      google_dns_record_set.ops-manager-dns.name, 0, length(google_dns_record_set.ops-manager-dns.name)-1)}"

    opsman_admin_password = "${data.terraform_remote_state.bootstrap.opsman_admin_password}"
  }
}

data "template_file" "mount-opsman-data-volume" {
  template = "${file("${path.module}/mount-volume.sh")}"

  vars {
    attached_device_name = "/dev/sdb"
    mount_directory      = "/data"
    world_readable       = "true"
  }
}

resource "google_compute_disk" "opsman-data-disk" {
  name = "${var.prefix}-opsman-data-disk"
  type = "pd-standard"
  zone = "${var.gcp_zone_1}"
  size = "100"
}

resource "google_storage_bucket" "director" {
  name          = "${var.prefix}-director"
  location      = "${var.gcp_storage_bucket_location}"
  force_destroy = true
}