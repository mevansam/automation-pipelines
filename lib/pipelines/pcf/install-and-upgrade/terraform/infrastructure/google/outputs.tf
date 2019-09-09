// Core Project Output

output "company_name" {
  value = "${data.terraform_remote_state.bootstrap.outputs.company_name}"
}

output "deployment_prefix" {
  value = "${local.prefix}"
}

output "gcp_project" {
  value = "${data.terraform_remote_state.bootstrap.outputs.gcp_project}"
}

output "gcp_service_account_email" {
  value = "${data.terraform_remote_state.bootstrap.outputs.gcp_service_account_email}"
}

output "gcp_credentials" {
  value = "${data.terraform_remote_state.bootstrap.outputs.gcp_credentials}"
}

output "gcp_region" {
  value = "${data.terraform_remote_state.bootstrap.outputs.gcp_region}"
}

output "gcp_storage_access_key" {
  value = "${data.terraform_remote_state.bootstrap.outputs.gcp_storage_access_key}"
}

output "gcp_storage_secret_key" {
  value = "${data.terraform_remote_state.bootstrap.outputs.gcp_storage_secret_key}"
}

# PKS Service Accounts

output "gcp_master_service_account" {
  value = "${google_service_account.pks-master.email}"
}

output "gcp_worker_service_account" {
  value = "${google_service_account.pks-worker.email}"
}

// DNS Output

output "env_dns_zone_name_servers" {
  value = "${google_dns_managed_zone.env_dns_zone.name_servers}"
}

output "env_dns_zone_name" {
  value = "${google_dns_managed_zone.env_dns_zone.name}"
}

output "env_domain" {
  value = "${local.env_domain}"
}

output "system_domain" {
  value = "${local.system_domain}"
}

output "tcp_domain" {
  value = "tcp.${local.env_domain}"
}

output "apps_domain" {
  value = "${local.apps_domain}"
}

output "pks_url" {
  value = "${
    substr(
      google_dns_record_set.pks.name, 0, 
      length(google_dns_record_set.pks.name)-1)}"
}

output "harbor_registry_fqdn" {
  value = "${
    substr(
      google_dns_record_set.harbor.name, 0, 
      length(google_dns_record_set.harbor.name)-1)}"
}

// Availability Zones

output "singleton_availability_zone" {
  value = "${local.singleton_zone}"
}

output "availability_zones" {
  value = "${join(",", data.google_compute_zones.available.names)}"
}

// Network Output

output "pcf_networks" {
  value = <<JSON
{
  "pcf_networks": ${jsonencode(data.external.pcf-network-info.*.result)}
}
JSON
}

output "vpc_network_name" {
  value = "${google_compute_network.pcf.name}"
}

// Public IPs

output "pub_ip_global_pcf" {
  value = "${google_compute_global_address.pcf.address}"
}

output "pub_ip_ssh_and_doppler" {
  value = "${google_compute_address.cf-ssh.address}"
}

output "pub_ip_ssh_tcp_lb" {
  value = "${google_compute_address.cf-tcp.address}"
}

// Load balancer pools

output "pas_http_lb_name" {
  value = "http:${google_compute_backend_service.ert_http_lb_backend_service.name}"
}

output "pas_tcp_lb_name" {
  value = "tcp:${google_compute_target_pool.cf-tcp.name}"
}

output "pas_ssh_lb_name" {
  value = "tcp:${google_compute_target_pool.cf-ssh.name}"
}

output "pas_doppler_lb_name" {
  value = "tcp:${google_compute_target_pool.cf-gorouter.name}"
}

output "pks_lb_name" {
  value = "tcp:${google_compute_target_pool.pks.name}"
}

output "harbor_lb_name" {
  value = "tcp:${google_compute_target_pool.harbor.name}"
}

output "tcp_routing_reservable_ports" {
  value = "${google_compute_forwarding_rule.cf-tcp.port_range}"
}

// Cloud Storage Bucket Output

output "buildpacks_bucket" {
  value = "${google_storage_bucket.buildpacks.name}"
}

output "droplets_bucket" {
  value = "${google_storage_bucket.droplets.name}"
}

output "packages_bucket" {
  value = "${google_storage_bucket.packages.name}"
}

output "resources_bucket" {
  value = "${google_storage_bucket.resources.name}"
}

output "director_blobstore_bucket" {
  value = "${google_storage_bucket.director.name}"
}

// Database

output "db_host" {
  value = "${google_sql_database_instance.master.ip_address.0.ip_address}"
}

output "db_tls_ca" {
  value = "${google_sql_database_instance.master.server_ca_cert.0.cert}"
}

// Certificates

output "ca_certs" {
  value = "${data.terraform_remote_state.bootstrap.outputs.root_ca_cert}"
}

output "saml_cert" {
  value = "${length(var.pcf_saml_ssl_cert) > 0 ? var.pcf_saml_ssl_cert : tls_locally_signed_cert.saml-san.cert_pem}"
}

output "saml_cert_key" {
  value = "${length(var.pcf_saml_ssl_key) > 0 ? var.pcf_saml_ssl_key : tls_private_key.saml-san.private_key_pem}"
}

output "ert_cert" {
  value = "${google_compute_ssl_certificate.lb-cert.certificate}"
}

output "ert_cert_key" {
  value = "${google_compute_ssl_certificate.lb-cert.private_key}"
}

output "pks_cert" {
  value = "${google_compute_ssl_certificate.lb-cert.certificate}"
}

output "pks_cert_key" {
  value = "${google_compute_ssl_certificate.lb-cert.private_key}"
}

output "harbor_registry_cert" {
  value = "${google_compute_ssl_certificate.lb-cert.certificate}"
}

output "harbor_registry_cert_key" {
  value = "${google_compute_ssl_certificate.lb-cert.private_key}"
}

output "platform_san_cert" {
  value = "${google_compute_ssl_certificate.lb-cert.certificate}"
}

output "platform_san_cert_key" {
  value = "${google_compute_ssl_certificate.lb-cert.private_key}"
}

# Notification Email
output "notification_email" {
  value = "${data.terraform_remote_state.bootstrap.outputs.notification_email}"
}
