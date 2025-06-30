#!/bin/bash

# Configuration
STORAGE_ACCOUNT_NAME="$AZURE_STORAGE_ACCOUNT"
CONTAINER_NAME="$CONTAINER_NAME"
STORAGE_ACCOUNT_KEY="$AZURE_STORAGE_ACCOUNT_ACCESS_KEY"

ROOT_PREFIX="kopia/"
CUTOFF_TIME=$(date -u -d '1 day ago' +%s)
TARGET_PREFIXES=("_log" "x" "q" "p")

echo "Cutoff time (UTC): $(date -u -d @$CUTOFF_TIME)"
echo "Scanning container: $CONTAINER_NAME, path: $ROOT_PREFIX"
echo "------------------------------------------------------"

# --------------------------------------------
# List all blobs under kopia/ recursively
# --------------------------------------------

BLOB_LIST=$(az storage blob list \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$STORAGE_ACCOUNT_KEY" \
    --container-name "$CONTAINER_NAME" \
    --prefix "$ROOT_PREFIX" \
    --query "[].{name:name, last_modified:properties.lastModified}" \
    -o tsv)

if [[ -z "$BLOB_LIST" ]]; then
    echo "No blobs found under '$ROOT_PREFIX'"
    exit 0
fi

# --------------------------------------------
# Filter and delete
# --------------------------------------------

while IFS=$'\t' read -r BLOB_NAME LAST_MODIFIED; do
    # Get the filename part after the last slash
    FILE_NAME=$(basename "$BLOB_NAME")

    # Check if the file starts with any of the target prefixes
    MATCH=0
    for PREFIX in "${TARGET_PREFIXES[@]}"; do
        if [[ "$FILE_NAME" == $PREFIX* ]]; then
            MATCH=1
            break
        fi
    done

    if [[ "$MATCH" -eq 0 ]]; then
        continue
    fi

    # Convert to epoch time
    BLOB_TIME=$(date -u -d "$LAST_MODIFIED" +%s 2>/dev/null)

    if [[ -z "$BLOB_TIME" ]]; then
        echo "⚠️  Could not parse date for: $BLOB_NAME"
        continue
    fi

    echo "Found blob: $BLOB_NAME (Modified: $LAST_MODIFIED)"
    if (( BLOB_TIME < CUTOFF_TIME )); then
        echo "✅ Deleting blob: $BLOB_NAME"
        az storage blob delete \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --account-key "$STORAGE_ACCOUNT_KEY" \
            --container-name "$CONTAINER_NAME" \
            --name "$BLOB_NAME"
    else
        echo "❌ Skipping blob (Newer than 1 day)"
    fi

done <<< "$BLOB_LIST"

echo ""
echo "✅ Script complete."
