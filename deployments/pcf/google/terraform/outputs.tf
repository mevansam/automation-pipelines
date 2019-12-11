#
# Outputs that will be saved to the Terraform state 
# and can be referenced for future configurations.
#

#
# Root CA for signing self-signed cert
#
output "root_ca_key" {
  value = "${module.bootstrap.root_ca_key}"
}

output "root_ca_cert" {
  value = "${module.bootstrap.root_ca_cert}"
}

#
# GCP credentials
#

output "gcp_project" {
  value = "${data.external.gcp_credentials.result.project_id}"
}

output "gcp_service_account_email" {
  value = "${data.external.gcp_credentials.result.client_email}"
}

output "gcp_credentials" {
  value     = "${file(var.gcp_credentials)}"
  sensitive = true
}

output "gcp_region" {
  value = "${var.gcp_region}"
}

output "gcp_storage_access_key" {
  value     = "${var.gcp_storage_access_key}"
  sensitive = true
}

output "gcp_storage_secret_key" {
  value     = "${var.gcp_storage_secret_key}"
  sensitive = true
}

#
# Terraform state attributes
#

output "terraform_state_bucket" {
  value = "${var.terraform_state_bucket}"
}

output "bootstrap_state_prefix" {
  value = "${local.bootstrap_state_prefix}"
}

#
# Certificate Subject data for certificate creation
#
output "company_name" {
  value = "${var.company_name}"
}

output "organization_name" {
  value = "${var.organization_name}"
}

output "locality" {
  value = "${var.locality}"
}

output "province" {
  value = "${var.province}"
}

output "country" {
  value = "${var.country}"
}

#
# VPC configuration
#

output "vpc_name" {
  value = "${var.vpc_name}"
}

output "max_azs" {
  value = "${var.max_azs}"
}

output "vpc_dns_zone" {
  value = "${var.vpc_dns_zone}"
}

output "vpc_dns_zone_name" {
  value = "${module.bootstrap.vpc_dns_zone_name}"
}

#
# Concourse Automation common attributes
#

output "automation_pipelines_repo" {
  value = "${var.automation_pipelines_repo}"
}

output "automation_pipelines_branch" {
  value = "${var.automation_pipelines_branch}"
}

output "inceptor_pipelines_repo" {
  value = "${var.inceptor_pipelines_repo}"
}

output "inceptor_pipelines_branch" {
  value = "${var.inceptor_pipelines_branch}"
}

#
# Automation extensions git repository
#

output "automation_extensions_repo" {
  value = "${var.automation_extensions_repo}"
}

output "automation_extensions_branch" {
  value = "${var.automation_extensions_repo_branch}"
}

output "pcf_terraform_templates_path" {
  value = "${var.pcf_terraform_templates_path}"
}

output "pcf_tile_templates_path" {
  value = "${var.pcf_terraform_templates_path}"
}

#
# PCF Environments
#

output "pcf_sandbox_environment" {
  value = "${var.pcf_environments[0]}"
}

#
# PCF Deployment Networks CIDRs
#

output "pcf_networks" {
  value = "${var.pcf_networks}"
}

output "pcf_network_subnets" {
  value = "${var.pcf_network_subnets}"
}

output "pcf_network_dns" {
  value = "${var.pcf_network_dns}"
}

#
# PCF Install params
#

output "pivnet_token" {
  value     = "${var.pivnet_token}"
  sensitive = true
}

output "opsman_admin_password" {
  value = "${random_string.opsman-admin-password.result}"
}

output "common_admin_password" {
  value = "${random_string.common-admin-password.result}"
}

output "pas_system_dbpassword" {
  value     = "${random_string.pas-system-dbpassword.result}"
  sensitive = true
}

output "credhub_encryption_key" {
  value     = "${random_string.credhub-encryption-key.result}"
  sensitive = true
}

output "notification_email" {
  value = "${var.notification_email}"
}

#
# Backup / Restore pipeline params
#

output "backups_bucket" {
  value = "${google_storage_bucket.backups.name}"
}

#
# Network resource attributes
#
output "dmz_network" {
  value = "${module.bootstrap.dmz_network}"
}

output "dmz_subnetwork" {
  value = "${module.bootstrap.dmz_subnetwork}"
}

output "admin_network" {
  value = "${module.bootstrap.admin_network}"
}

output "admin_subnetwork" {
  value = "${module.bootstrap.admin_subnetwork}"
}

#
# Bastion resource attributes
#
output "bastion_fqdn" {
  value = "${module.bootstrap.bastion_fqdn}"
}

output "bastion_admin_fqdn" {
  value = "${module.bootstrap.bastion_admin_fqdn}"
}

output "bastion_admin_password" {
  value = "${module.bootstrap.bastion_admin_password}"
}

output "concourse_admin_password" {
  value = "${random_string.concourse-admin-password.result}"
}

#
# Default SSH key to use within VPC
#
output "default_openssh_public_key" {
  value = "${module.bootstrap.default_openssh_public_key}"
}

output "default_openssh_private_key" {
  value = "${module.bootstrap.default_openssh_private_key}"
}
