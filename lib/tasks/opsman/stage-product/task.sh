#!/bin/bash

[[ -n "$TRACE" ]] && set -x
set -eu

PRODUCT_VERSION=$(cat ./pivnet-product/version)
DESIRED_VERSION=${PRODUCT_VERSION%%_*}
PRODUCT_NAME=${PRODUCT_VERSION#*_}

AVAILABLE=$(om \
  --skip-ssl-validation \
  --client-id "${OPSMAN_CLIENT_ID}" \
  --client-secret "${OPSMAN_CLIENT_SECRET}" \
  --username "${OPSMAN_USERNAME}" \
  --password "${OPSMAN_PASSWORD}" \
  --target "https://${OPSMAN_HOST}" \
  curl -path /api/v0/available_products)
STAGED=$(om \
  --skip-ssl-validation \
  --client-id "${OPSMAN_CLIENT_ID}" \
  --client-secret "${OPSMAN_CLIENT_SECRET}" \
  --username "${OPSMAN_USERNAME}" \
  --password "${OPSMAN_PASSWORD}" \
  --target "https://${OPSMAN_HOST}" \
  curl -path /api/v0/staged/products)

# Figure out which products are unstaged.
UNSTAGED_ALL=$(jq -n --argjson available "$AVAILABLE" --argjson staged "$STAGED" \
  '$available - ($staged | map({"name": .type, "product_version": .product_version}))')

UNSTAGED_PRODUCT=$(echo "$UNSTAGED_ALL" | jq \
  --arg product_name "$PRODUCT_NAME" \
  --arg product_version "$DESIRED_VERSION" \
  'map(select(.name == $product_name)) | map(select(.product_version | startswith($product_version)))'
)

# There should be only one such unstaged product.
if [ "$(echo $UNSTAGED_PRODUCT | jq '. | length')" -gt 0 ]; then

  if [ "$(echo $UNSTAGED_PRODUCT | jq '. | length')" -ne 1 ]; then
    echo "Need exactly one unstaged build for $PRODUCT_NAME version $DESIRED_VERSION"
    jq -n "$UNSTAGED_PRODUCT"
    exit 1
  fi

  full_version=$(echo "$UNSTAGED_PRODUCT" | jq -r '.[].product_version')

  if [[ $STAGE_AND_APPLY == true ]]; then

    INSTALLED_VERSION=$(om \
      --skip-ssl-validation \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      --username "${OPSMAN_USERNAME}" \
      --password "${OPSMAN_PASSWORD}" \
      --target "https://${OPSMAN_HOST}" \
      curl -path /api/installation_settings \
      | jq -r '.products[] | select(.identifier=="'$PRODUCT_NAME'") | select(.prepared==true) | .product_version')
  
    if [[ -n "$INSTALLED_VERSION" && "$INSTALLED_VERSION" !=  "$full_version" ]]; then
      om --target "https://${OPSMAN_HOST}" \
        --skip-ssl-validation \
        --client-id "${OPSMAN_CLIENT_ID}" \
        --client-secret "${OPSMAN_CLIENT_SECRET}" \
        --username "${OPSMAN_USERNAME}" \
        --password "${OPSMAN_PASSWORD}" \
        stage-product \
        --product-name "${PRODUCT_NAME}" \
        --product-version "${full_version}"

      ./automation/lib/tasks/opsman/apply-changes/task.sh
    else
      echo "Skipping staging and upgrade of $PRODUCT_NAME version $DESIRED_VERSION as a prior installed version was not found."
    fi

  else

    om --target "https://${OPSMAN_HOST}" \
      --skip-ssl-validation \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      --username "${OPSMAN_USERNAME}" \
      --password "${OPSMAN_PASSWORD}" \
      stage-product \
      --product-name "${PRODUCT_NAME}" \
      --product-version "${full_version}"
  fi
else
  echo "No unstaged builds for $PRODUCT_NAME version $DESIRED_VERSION found. Most likely this version has already been installed."
fi
