#!/bin/bash

# List of namespaces to scan
namespaces=$(kubectl get ns --no-headers -o custom-columns=":metadata.name")

for ns in $namespaces; do
  echo "Scanning namespace: $ns"
  
  # Get all pod names in the namespace
  pods=$(kubectl get pods -n $ns -o jsonpath="{.items[*].metadata.name}")

  for pod in $pods; do
    # Get volume names that are PVCs
    pvc_volumes=$(kubectl get pod $pod -n $ns -o json \
      | jq -r '.spec.volumes[] | select(.persistentVolumeClaim != null) | .name' | paste -sd "," -)

    if [ -n "$pvc_volumes" ]; then
      echo "Annotating pod $pod in namespace $ns with PVC volumes: $pvc_volumes"
      kubectl annotate pod $pod -n $ns backup.velero.io/backup-volumes="$pvc_volumes" --overwrite
    fi
  done
done