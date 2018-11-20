#!/bin/bash

[[ -n "$TRACE" ]] && set -x

source ~/scripts/bosh-func.sh
set -euo pipefail

bosh::set_bosh_cli

echo "$GOOGLE_CREDENTIALS_JSON" > .gcp-service-account.json
export GOOGLE_CREDENTIALS=$(pwd)/.gcp-service-account.json
gcloud auth activate-service-account --key-file=$GOOGLE_CREDENTIALS

# Create a local s3 bucket for pcf automation data
mc config host add auto $AUTOS3_URL $AUTOS3_ACCESS_KEY $AUTOS3_SECRET_KEY
[[ "$(mc ls auto/ | awk '/pcf\/$/{ print $5 }')" == "pcf/" ]] || \
  mc mb auto/pcf

# Login to concourse
fly -t default login -c $CONCOURSE_URL -u ''$CONCOURSE_USER'' -p ''$CONCOURSE_PASSWORD''
fly -t default sync

#
# Setup pipeline paths
#

terraform_params_path=automation/deployments/pcf/${IAAS}/params
patch_job_notifications=automation/lib/inceptor/tasks/patches/patch_job_notifications.sh

download_products_pipeline_path=automation/lib/pipelines/pcf/download-products/pipeline
download_products_patches_path=automation/lib/pipelines/pcf/download-products/patches

install_and_upgrade_pipeline_path=automation/lib/pipelines/pcf/install-and-upgrade/pipeline
install_and_upgrade_patches_path=automation/lib/pipelines/pcf/install-and-upgrade/patches

backup_and_restore_pipeline_path=automation/lib/pipelines/pcf/backup-and-restore/pipeline
backup_and_restore_patches_path=automation/lib/pipelines/pcf/backup-and-restore/patches

start_and_stop_pipeline_path=automation/lib/pipelines/pcf/stop-and-start/pipeline
start_and_stop_patches_path=automation/lib/pipelines/pcf/stop-and-start/patches

#
# Configure pipeline for downloading products
#

terraform init $terraform_params_path

terraform apply -auto-approve \
  -var "bootstrap_state_bucket=$BOOTSTRAP_STATE_BUCKET" \
  -var "bootstrap_state_prefix=$BOOTSTRAP_STATE_PREFIX" \
  -var "params_template_file=$download_products_pipeline_path/${IAAS}/params.yml" \
  -var "params_file=download-products-params.yml" \
  -var "environment=" \
  $terraform_params_path >/dev/null

eval "echo \"$(cat $download_products_pipeline_path/${IAAS}/pipeline.yml)\"" \
  > download-products-pipeline0.yml

i=0 && j=1
for p in $(echo -e "$PRODUCTS"); do 
  product_name=$(echo $p | awk -F':' '{ print $1 }')
  slug_and_version=$(echo $p | awk -F':' '{ print $2 }')
  product_glob="'$(echo $p | awk -F':' '{ print $3 }')'"
  product_slug=${slug_and_version%/*}
  product_version=${slug_and_version#*/}

  eval "echo \"$(cat $download_products_patches_path/download-product-patch.yml)\"" \
    > download-${product_name}-patch.yml

  $bosh interpolate -o download-${product_name}-patch.yml \
    download-products-pipeline$i.yml > download-products-pipeline$j.yml

  i=$(($i+1)) && j=$(($j+1))
done

$patch_job_notifications download-products-pipeline$i.yml > download-products-pipeline.yml

fly -t default set-pipeline -n \
  -p download-products \
  -c download-products-pipeline.yml \
  -l download-products-params.yml \
  -v "trace=$TRACE" \
  -v "concourse_url=$CONCOURSE_URL" \
  -v "concourse_user=$CONCOURSE_USER" \
  -v "concourse_password=$CONCOURSE_PASSWORD" \
  -v "autos3_url=$AUTOS3_URL" \
  -v "autos3_access_key=$AUTOS3_ACCESS_KEY" \
  -v "autos3_secret_key=$AUTOS3_SECRET_KEY" \
  -v "pipeline_automation_path=$PIPELINE_AUTOMATION_PATH" \
  -v "iaas_type=$IAAS" \
  -v "vpc_name=$VPC_NAME" >/dev/null

fly -t default unpause-pipeline -p download-products

#
# Configure pipelines per environment
#

for e in $ENVIRONMENTS; do

  env=$(echo $e | awk '{print toupper($0)}')
  echo "\n*** Configuring pipelines for ${env} ***\n"

  # Install and upgrade pipeline base
  eval "echo \"$(cat $install_and_upgrade_pipeline_path/${IAAS}/pipeline.yml)\"" \
    > install-and-upgrade-pipeline0.yml
  
  # Backup and restore pipeline base
  eval "echo \"$(cat $backup_and_restore_pipeline_path/${IAAS}/pipeline.yml)\"" \
    > backup_and_restore_pipeline0.yml

  if [[ -n $PRODUCTS ]]; then

    #
    # Apply any patching required if at least one product is specified
    #

    # Patch install and upgrade pipeline
    eval "echo \"$(cat $install_and_upgrade_patches_path/install-and-upgrade-patch.yml)\"" \
      > install-and-upgrade-patch.yml

    $bosh interpolate -o install-and-upgrade-patch.yml \
      install-and-upgrade-pipeline0.yml > install-and-upgrade-pipeline1.yml

    # Patch backup and restore pipeline
    eval "echo \"$(cat $backup_and_restore_patches_path/backup-and-restore-patch.yml)\"" \
      > backup-and-restore-patch.yml

    $bosh interpolate -o backup-and-restore-patch.yml \
      backup_and_restore_pipeline0.yml > backup_and_restore_pipeline1.yml

    #
    # Apply patches of all the speficied products
    #

    i=1 && j=2
    for p in $(echo -e "$PRODUCTS"); do 
      product_name=$(echo $p | awk -F':' '{ print $1 }')
      slug_and_version=$(echo $p | awk -F':' '{ print $2 }')
      product_glob="'$(echo $p | awk -F':' '{ print $3 }')'"
      errands_to_disable=$(echo $p | awk -F':' '{ print $4 }')
      errands_to_enable=$(echo $p | awk -F':' '{ print $5 }')
      product_slug=${slug_and_version%/*}
      product_version=${slug_and_version#*/}

      # Patch install and upgrade pipeline
      if [[ -e $install_and_upgrade_patches_path/product-${product_name}-patch.yml ]]; then

        eval "echo \"$(cat $install_and_upgrade_patches_path/product-common-patch.yml)\"" \
          > install-and-upgrade-${product_name}-patch.yml
        eval "echo \"$(cat $install_and_upgrade_patches_path/product-${product_name}-patch.yml)\"" \
          >> install-and-upgrade-${product_name}-patch.yml
      else
        eval "echo \"$(cat $install_and_upgrade_patches_path/product-unknown-patch.yml)\"" \
          > install-and-upgrade-${product_name}-patch.yml
      fi

      $bosh interpolate -o install-and-upgrade-${product_name}-patch.yml \
        install-and-upgrade-pipeline$i.yml > install-and-upgrade-pipeline$j.yml

      # Patch backup and restore pipeline
      if [[ -e $backup_and_restore_patches_path/product-${product_name}-patch.yml ]]; then

        eval "echo \"$(cat $backup_and_restore_patches_path/product-common-patch.yml)\"" \
          > backup-and-restore-${product_name}-patch.yml
        eval "echo \"$(cat $backup_and_restore_patches_path/product-${product_name}-patch.yml)\"" \
          >> backup-and-restore-${product_name}-patch.yml
      else
        eval "echo \"$(cat $backup_and_restore_patches_path/product-unknown-patch.yml)\"" \
          > backup-and-restore-${product_name}-patch.yml
      fi

      $bosh interpolate -o backup-and-restore-${product_name}-patch.yml \
        backup_and_restore_pipeline$i.yml > backup_and_restore_pipeline$j.yml

      i=$(($i+1)) && j=$(($j+1))      
    done

  else
    i=0
  fi

  # Patch notifications to install and upgrade pipeline
  $patch_job_notifications install-and-upgrade-pipeline$i.yml > install-and-upgrade-pipeline.yml

  # Patch notifications to backup and restore pipeline
  $patch_job_notifications backup_and_restore_pipeline$i.yml > backup-and-restore-pipeline.yml

  #
  # Set install and upgrade pipeline
  #

  rm -fr .terraform/
  rm terraform.tfstate
  
  terraform init $terraform_params_path

  terraform apply -auto-approve \
    -var "bootstrap_state_bucket=$BOOTSTRAP_STATE_BUCKET" \
    -var "bootstrap_state_prefix=$BOOTSTRAP_STATE_PREFIX" \
    -var "params_template_file=$install_and_upgrade_pipeline_path/${IAAS}/params.yml" \
    -var "params_file=install-and-upgrade-params.yml" \
    -var "environment=${e}" \
    $terraform_params_path >/dev/null

  fly -t default set-pipeline -n \
    -p ${env}_deployment \
    -c install-and-upgrade-pipeline.yml \
    -l install-and-upgrade-params.yml \
    -v "trace=$TRACE" \
    -v "concourse_url=$CONCOURSE_URL" \
    -v "concourse_user=$CONCOURSE_USER" \
    -v "concourse_password=$CONCOURSE_PASSWORD" \
    -v "autos3_url=$AUTOS3_URL" \
    -v "autos3_access_key=$AUTOS3_ACCESS_KEY" \
    -v "autos3_secret_key=$AUTOS3_SECRET_KEY" \
    -v "smtp_host=$SMTP_HOST" \
    -v "smtp_port=$SMTP_PORT" \
    -v "automation_email=$EMAIL_FROM" \
    -v "notification_email=$EMAIL_TO" \
    -v "pipeline_automation_path=$PIPELINE_AUTOMATION_PATH" \
    -v "iaas_type=$IAAS" \
    -v "vpc_name=$VPC_NAME" >/dev/null

  #
  # Set backup and restore pipeline
  #

  rm -fr .terraform/
  rm terraform.tfstate

  terraform init $terraform_params_path

  terraform apply -auto-approve \
    -var "bootstrap_state_bucket=$BOOTSTRAP_STATE_BUCKET" \
    -var "bootstrap_state_prefix=$BOOTSTRAP_STATE_PREFIX" \
    -var "params_template_file=$backup_and_restore_pipeline_path/${IAAS}/params.yml" \
    -var "params_file=backup-and-restore-params.yml" \
    -var "environment=${e}" \
    $terraform_params_path >/dev/null

  fly -t default set-pipeline -n \
    -p ${env}_backup \
    -c backup-and-restore-pipeline.yml \
    -l backup-and-restore-params.yml \
    -v "trace=$TRACE" \
    -v "concourse_url=$CONCOURSE_URL" \
    -v "concourse_user=$CONCOURSE_USER" \
    -v "concourse_password=$CONCOURSE_PASSWORD" \
    -v "autos3_url=$AUTOS3_URL" \
    -v "autos3_access_key=$AUTOS3_ACCESS_KEY" \
    -v "autos3_secret_key=$AUTOS3_SECRET_KEY" \
    -v "smtp_host=$SMTP_HOST" \
    -v "smtp_port=$SMTP_PORT" \
    -v "automation_email=$EMAIL_FROM" \
    -v "notification_email=$EMAIL_TO" \
    -v "pipeline_automation_path=$PIPELINE_AUTOMATION_PATH" \
    -v "iaas_type=$IAAS" \
    -v "vpc_name=$VPC_NAME" >/dev/null

  #
  # Wait for deployment to reach an initial state
  #

  # Unpause the pipelines. The pipeline jobs will rerun in 
  # an idempotent manner if a prior installation is found.
  if [[ $UNPAUSE_INSTALL_PIPELINE == "true" ]]; then
    fly -t default unpause-pipeline -p ${env}_deployment

    if [[ -n $WAIT_ON_DEPLOYMENT_JOB ]]; then

      # Wait until given job is complete.
      set +e

      b=1
      while true; do
        r=$(fly -t default watch -j ${env}_deployment/$WAIT_ON_DEPLOYMENT_JOB -b $b 2>&1)
        [[ $? -eq 0 ]] && break

        s=$(echo "$r" | tail -1)
        if [[ "$s" == "failed" ]]; then
          echo -e "\n*** Job ${env}_deployment/$WAIT_ON_DEPLOYMENT_JOB FAILED! ***\n"
          echo -e "$r\n"
          b=$(($b+1))
        fi
        echo "Waiting for job ${env}_deployment/$WAIT_ON_DEPLOYMENT_JOB build $b to complete..."
        sleep 5
      done
      set -e
    fi

    fly -t default unpause-pipeline -p ${env}_backup
  fi

  #
  # Setup start and stop pipeline
  #

  rm -fr .terraform/
  rm terraform.tfstate

  terraform init $terraform_params_path

  terraform apply -auto-approve \
    -var "bootstrap_state_bucket=$BOOTSTRAP_STATE_BUCKET" \
    -var "bootstrap_state_prefix=$BOOTSTRAP_STATE_PREFIX" \
    -var "params_template_file=$start_and_stop_pipeline_path/${IAAS}/params.yml" \
    -var "params_file=stop-and-start-params.yml" \
    -var "environment=${e}" \
    $terraform_params_path >/dev/null

  if [[ $SET_START_STOP_SCHEDULE == true ]]; then

    $bosh interpolate -o $start_and_stop_patches_path/start-stop-schedule.yml \
      $start_and_stop_pipeline_path/${IAAS}/pipeline.yml > stop-and-start-pipeline.yml
  else
    cp $start_and_stop_pipeline_path/${IAAS}/pipeline.yml stop-and-start-pipeline.yml
  fi

  $patch_job_notifications stop-and-start-pipeline.yml > pipeline.yml

  fly -t default set-pipeline -n \
    -p ${env}_stop-and-start \
    -c pipeline.yml \
    -l stop-and-start-params.yml \
    -v "trace=$TRACE" \
    -v "concourse_url=$CONCOURSE_URL" \
    -v "concourse_user=$CONCOURSE_USER" \
    -v "concourse_password=$CONCOURSE_PASSWORD" \
    -v "autos3_url=$AUTOS3_URL" \
    -v "autos3_access_key=$AUTOS3_ACCESS_KEY" \
    -v "autos3_secret_key=$AUTOS3_SECRET_KEY" \
    -v "pipeline_automation_path=$PIPELINE_AUTOMATION_PATH" \
    -v "iaas_type=$IAAS" \
    -v "vpc_name=$VPC_NAME" >/dev/null
    
  fly -t default unpause-pipeline -p ${env}_stop-and-start

done
