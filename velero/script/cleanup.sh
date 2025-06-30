#!/bin/bash
set -euo pipefail

echo "🔐 Logging in with Managed Identity..."
az login --federated-token "$(cat "$AZURE_FEDERATED_TOKEN_FILE")" \
         --service-principal \
         --username "$AZURE_CLIENT_ID" \
         --tenant "$AZURE_TENANT_ID" > /dev/null

STORAGE_ACCOUNT_NAME="${AZURE_STORAGE_ACCOUNT}"
CONTAINER_NAME="${AZURE_CONTAINER_NAME}"
ROOT_PREFIX="kopia/"
CUTOFF_TIME=$(date -u -d '1 day ago' +%s)
TARGET_PREFIXES=("_log" "xn" "q")

echo "📦 Scanning: ${STORAGE_ACCOUNT_NAME}/${CONTAINER_NAME}/${ROOT_PREFIX}"

# Get the list of blobs under the ROOT_PREFIX
BLOB_LIST=$(az storage blob list \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --container-name "$CONTAINER_NAME" \
  --auth-mode login \
  --prefix "$ROOT_PREFIX" \
  --query "[].{name:name, last_modified:properties.lastModified}" \
  -o tsv)

if [[ -z "$BLOB_LIST" ]]; then
  echo "✅ No blobs found."
  exit 0
fi

# Process each blob
while IFS=$'\t' read -r BLOB_NAME LAST_MODIFIED; do
  FILE_NAME=$(basename "$BLOB_NAME")
  MATCH=0
  for PREFIX in "${TARGET_PREFIXES[@]}"; do
    if [[ "$FILE_NAME" == "$PREFIX"* ]]; then
      MATCH=1
      break
    fi
  done

  # Skip if prefix doesn't match
  [[ "$MATCH" -eq 0 ]] && continue

  # Convert timestamp and check age
  BLOB_TIME=$(date -u -d "$LAST_MODIFIED" +%s 2>/dev/null || echo 0)

  if (( BLOB_TIME < CUTOFF_TIME )); then
    echo "🧹 Deleting: $BLOB_NAME"
    az storage blob delete \
      --account-name "$STORAGE_ACCOUNT_NAME" \
      --container-name "$CONTAINER_NAME" \
      --name "$BLOB_NAME" \
      --auth-mode login \
      --only-show-errors
  else
    echo "⏩ Skipping newer blob: $BLOB_NAME"
  fi
done <<< "$BLOB_LIST"

echo "✅ Done."
