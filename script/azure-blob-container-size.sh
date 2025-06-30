#!/bin/bash

# Loop over each container
for container in $(az storage container list \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --account-key "$AZURE_STORAGE_KEY" \
    --query "[].name" \
    --output tsv); do

  # Sum blob sizes in each container
  size=$(az storage blob list \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --account-key "$AZURE_STORAGE_KEY" \
    --container-name "$container" \
    --query "[].properties.contentLength" \
    --output tsv | \
    awk '{sum+=$1} END {print sum}')

  # Convert to human-readable format
  hr_size=$(echo $size | numfmt --to=iec --suffix=B 2>/dev/null)

  # Print container name and size
  printf "%-30s %10s\n" "$container" "${hr_size:-$size B}"

done
