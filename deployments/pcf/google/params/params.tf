#
# Parameters to be passed along when setting up the PCF pipelines
#

locals {
  pcf_stop_at_start = "2000-01-01T${data.terraform_remote_state.bootstrap.pcf_stop_at == "0" 
    ? "00:00" : data.terraform_remote_state.bootstrap.pcf_stop_at }:00Z"

  pcf_stop_at_stop = "${timeadd(local.pcf_stop_at_start, "1m")}"

  pcf_start_at_start = "2000-01-01T${data.terraform_remote_state.bootstrap.pcf_start_at == "0" 
    ? "00:00" : data.terraform_remote_state.bootstrap.pcf_start_at }:00Z"

  pcf_start_at_stop = "${timeadd(local.pcf_start_at_start, "1m")}"
}

data "template_file" "params" {
  template = "${file(var.params_template_file)}"

  vars {
    gcp_project     = "${data.terraform_remote_state.bootstrap.gcp_project}"
    gcp_credentials = "${indent(2, data.terraform_remote_state.bootstrap.gcp_credentials)}"
    gcp_region      = "${data.terraform_remote_state.bootstrap.gcp_region}"

    gcp_storage_access_key = "${data.terraform_remote_state.bootstrap.gcp_storage_access_key}"
    gcp_storage_secret_key = "${data.terraform_remote_state.bootstrap.gcp_storage_secret_key}"

    terraform_state_bucket = "${data.terraform_remote_state.bootstrap.terraform_state_bucket}"
    bootstrap_state_prefix = "${data.terraform_remote_state.bootstrap.bootstrap_state_prefix}"

    vpc_name = "${data.terraform_remote_state.bootstrap.vpc_name}"

    environment = "${length(var.environment) > 0 
      ? var.environment 
      : data.terraform_remote_state.bootstrap.pcf_sandbox_environment}"

    locale = "${data.terraform_remote_state.bootstrap.locale}"

    automation_pipelines_repo   = "${data.terraform_remote_state.bootstrap.automation_pipelines_repo}"
    automation_pipelines_branch = "${data.terraform_remote_state.bootstrap.automation_pipelines_branch}"

    automation_extensions_repo   = "${data.terraform_remote_state.bootstrap.automation_extensions_repo}"
    automation_extensions_branch = "${data.terraform_remote_state.bootstrap.automation_extensions_branch}"

    pcf_terraform_templates_path = "${data.terraform_remote_state.bootstrap.pcf_terraform_templates_path}"
    pcf_tile_templates_path      = "${data.terraform_remote_state.bootstrap.pcf_tile_templates_path}"

    vpc_dns_zone = "${data.terraform_remote_state.bootstrap.vpc_dns_zone}"

    pivnet_token           = "${data.terraform_remote_state.bootstrap.pivnet_token}"
    opsman_admin_password  = "${data.terraform_remote_state.bootstrap.opsman_admin_password}"
    common_admin_password  = "${data.terraform_remote_state.bootstrap.common_admin_password}"
    pas_system_dbpassword  = "${data.terraform_remote_state.bootstrap.pas_system_dbpassword}"
    credhub_encryption_key = "${data.terraform_remote_state.bootstrap.credhub_encryption_key}"

    opsman_major_minor_version = "${data.terraform_remote_state.bootstrap.opsman_major_minor_version}"

    mysql_monitor_recipient_email = "${data.terraform_remote_state.bootstrap.notification_email}"

    num_diego_cells = "${data.terraform_remote_state.bootstrap.num_diego_cells}"

    backup_interval       = "${data.terraform_remote_state.bootstrap.backup_interval}"
    backup_interval_start = "${data.terraform_remote_state.bootstrap.backup_interval_start}"
    backup_interval_stop  = "${data.terraform_remote_state.bootstrap.backup_interval_stop}"
    backup_age            = "${data.terraform_remote_state.bootstrap.backup_age}"
    backups_bucket        = "${data.terraform_remote_state.bootstrap.backups_bucket}"

    pcf_stop_trigger_start  = "${substr(local.pcf_stop_at_start, 11, 5)}"
    pcf_stop_trigger_stop   = "${substr(local.pcf_stop_at_stop, 11, 5)}"
    pcf_stop_trigger_days   = "${data.terraform_remote_state.bootstrap.pcf_stop_trigger_days}"
    pcf_start_trigger_start = "${substr(local.pcf_start_at_start, 11, 5)}"
    pcf_start_trigger_stop  = "${substr(local.pcf_start_at_stop, 11, 5)}"
    pcf_start_trigger_days  = "${data.terraform_remote_state.bootstrap.pcf_start_trigger_days}"
  }
}

resource "local_file" "params" {
  content  = "${data.template_file.params.rendered}"
  filename = "${var.params_file}"
}
