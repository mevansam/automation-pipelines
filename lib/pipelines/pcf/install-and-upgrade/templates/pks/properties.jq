#
# jq -n \
#    --arg pks_url "" \
#    --arg pks_cert "" \
#    --arg pks_cert_key "" \
#    --arg cloud_provider "google" \
#    --arg gcp_master_service_account "" \
#    --arg gcp_worker_service_account "" \
#    --arg gcp_project "" \
#    --arg vpc_network_name "" \
#    --arg vsphere_user "" \
#    --arg vsphere_password "" \
#    --arg vsphere_server "" \
#    --arg vcenter_datacenter "" \
#    --arg vcenter_persistant_datastores "" \
#    --arg vcenter_vms_path "pcf_vms" \
#    --argjson plan1_worker_instances 3 \
#    --argjson plan1_allow_privileged_containers false \
#    --arg plan1_az_placement "$AVAILABILITY_ZONES" \
#    --argjson plan2_worker_instances 5 \
#    --argjson plan2_allow_privileged_containers false \
#    --arg plan2_az_placement "$AVAILABILITY_ZONES" \
#    --argjson plan3_worker_instances 0 \
#    --argjson plan3_allow_privileged_containers false \
#    --arg plan3_az_placement "$AVAILABILITY_ZONES" \
#    "$(cat properties.jq)"
#

{
  ".properties.pks_api_hostname": { "value": $pks_url },
  ".pivotal-container-service.pks_tls": {
    "value": {
      "cert_pem": $pks_cert,
      "private_key_pem": $pks_cert_key
    }
  },
  ".properties.telemetry_selector": { "value": "disabled" }
}

# Configure plans
+
if $plan1_worker_instances > 0 then
{
  ".properties.plan1_selector": { "value": "Plan Active" },
  ".properties.plan1_selector.active.name": { "value": "small" },
  ".properties.plan1_selector.active.description": { "value": "Default plan for K8s cluster" },
  ".properties.plan1_selector.active.master_az_placement": { "value": ($plan1_az_placement | split(",")) },
  ".properties.plan1_selector.active.worker_az_placement": { "value": ($plan1_az_placement | split(",")) },
  ".properties.plan1_selector.active.master_vm_type": { "value": "medium.disk" },
  ".properties.plan1_selector.active.master_persistent_disk_type": { "value": "10240" },
  ".properties.plan1_selector.active.worker_vm_type": { "value": "medium.disk" },
  ".properties.plan1_selector.active.worker_persistent_disk_type": { "value": "51200" },
  ".properties.plan1_selector.active.worker_instances": { "value": $plan1_worker_instances },
  ".properties.plan1_selector.active.errand_vm_type": { "value": "micro" },
  ".properties.plan1_selector.active.addons_spec": { "value": "" },
  ".properties.plan1_selector.active.allow_privileged_containers": { "value": $plan1_allow_privileged_containers }
}
else
{ 
  ".properties.plan1_selector": { "value": "Plan Inactive" } 
}
end
+
if $plan2_worker_instances > 0 then
{
  ".properties.plan2_selector": { "value": "Plan Active" },
  ".properties.plan2_selector.active.name": { "value": "medium" },
  ".properties.plan2_selector.active.description": { "value": "For Large Workloads" },
  ".properties.plan2_selector.active.master_az_placement": { "value": ($plan2_az_placement | split(",")) },
  ".properties.plan2_selector.active.worker_az_placement": { "value": ($plan2_az_placement | split(",")) },
  ".properties.plan2_selector.active.master_vm_type": { "value": "medium.disk" },
  ".properties.plan2_selector.active.master_persistent_disk_type": { "value": "10240" },
  ".properties.plan2_selector.active.worker_vm_type": { "value": "large.disk" },
  ".properties.plan2_selector.active.worker_persistent_disk_type": { "value": "51200" },
  ".properties.plan2_selector.active.worker_instances": { "value": $plan2_worker_instances },
  ".properties.plan2_selector.active.errand_vm_type": { "value": "micro" },
  ".properties.plan2_selector.active.addons_spec": { "value": "" },
  ".properties.plan2_selector.active.allow_privileged_containers": { "value": $plan2_allow_privileged_containers }
}
else
{ 
  ".properties.plan2_selector": { "value": "Plan Inactive" } 
}
end
+
if $plan3_worker_instances > 0 then
{
  ".properties.plan3_selector": { "value": "Plan Active" },
  ".properties.plan3_selector.active.name": { "value": "large" },
  ".properties.plan3_selector.active.description": { "value": "For Extra Large Workloads" },
  ".properties.plan3_selector.active.master_az_placement": { "value": ($plan3_az_placement | split(",")) },
  ".properties.plan3_selector.active.worker_az_placement": { "value": ($plan3_az_placement | split(",")) },
  ".properties.plan3_selector.active.master_vm_type": { "value": "medium.disk" },
  ".properties.plan3_selector.active.master_persistent_disk_type": { "value": "10240" },
  ".properties.plan3_selector.active.worker_vm_type": { "value": "xlarge.disk" },
  ".properties.plan3_selector.active.worker_persistent_disk_type": { "value": "51200" },
  ".properties.plan3_selector.active.worker_instances": { "value": $plan3_worker_instances },
  ".properties.plan3_selector.active.errand_vm_type": { "value": "micro" },
  ".properties.plan3_selector.active.addons_spec": { "value": "" },
  ".properties.plan3_selector.active.allow_privileged_containers": { "value": $plan3_allow_privileged_containers }
}
else
{ 
  ".properties.plan3_selector": { "value": "Plan Inactive" } 
}
end

# Configure cloud provider
+
if $cloud_provider == "google" then
{
  ".properties.cloud_provider": { "value": "GCP" },
  ".properties.cloud_provider.gcp.master_service_account": { "value": $gcp_master_service_account },
  ".properties.cloud_provider.gcp.worker_service_account": { "value": $gcp_worker_service_account },
  ".properties.cloud_provider.gcp.project_id": { "value": $gcp_project },
  ".properties.cloud_provider.gcp.network": { "value": $vpc_network_name },
}
elif $cloud_provider == "vsphere" then
{
  ".properties.cloud_provider": { "value": "vSphere" },
  ".properties.cloud_provider.vsphere.vcenter_master_creds": { 
    "value": {
      "identity": $vsphere_user,
      "password": $vsphere_password
    }
  },
  ".properties.cloud_provider.vsphere.vcenter_ip": { "value": $vsphere_server },
  ".properties.cloud_provider.vsphere.vcenter_dc": { "value": $vcenter_datacenter },
  ".properties.cloud_provider.vsphere.vcenter_ds": { "value": (
      $vcenter_persistant_datastores | split(",") | first
    ) },
  ".properties.cloud_provider.vsphere.vcenter_vms": { "value": $vcenter_vms_path }
}
else
.
end

# Configure UAA
+
{
  ".properties.oidc_selector": { "value": "disabled" }
}

# CEIP and Telemetry
+
{
  ".properties.telemetry_installation_purpose_selector": { "value": "not_provided" }
}
