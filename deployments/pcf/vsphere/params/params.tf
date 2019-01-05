#
# Parameters to be passed along when setting up the PCF pipelines
#

data "template_file" "params" {
  template = "${file(var.params_template_file)}"

  vars {
    vsphere_server               = "${data.terraform_remote_state.bootstrap.vsphere_server}"
    vsphere_user                 = "${data.terraform_remote_state.bootstrap.vsphere_user}"
    vsphere_password             = "${data.terraform_remote_state.bootstrap.vsphere_password}"
    vsphere_allow_unverified_ssl = "${data.terraform_remote_state.bootstrap.vsphere_allow_unverified_ssl}"

    vcenter_datacenter            = "${data.terraform_remote_state.bootstrap.vcenter_datacenter}"
    vcenter_clusters              = "${data.terraform_remote_state.bootstrap.vcenter_clusters}"
    vcenter_ephemeral_datastores  = "${data.terraform_remote_state.bootstrap.vcenter_ephemeral_datastores}"
    vcenter_persistant_datastores = "${data.terraform_remote_state.bootstrap.vcenter_persistant_datastores}"

    terraform_state_bucket = "${data.terraform_remote_state.bootstrap.terraform_state_bucket}"
    bootstrap_state_prefix = "${data.terraform_remote_state.bootstrap.bootstrap_state_prefix}"

    vpc_name = "${data.terraform_remote_state.bootstrap.vpc_name}"

    environment = "${length(var.environment) > 0 
      ? var.environment 
      : data.terraform_remote_state.bootstrap.pcf_sandbox_environment}"

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
  }
}

resource "local_file" "params" {
  content  = "${data.template_file.params.rendered}"
  filename = "${var.params_file}"
}