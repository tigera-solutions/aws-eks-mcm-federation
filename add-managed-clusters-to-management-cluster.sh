#! /usr/bin/env bash

MCMENDPOINT="demo.tigera-solutions.io:30449"

CLUSTERS="
cluster-a
cluster-b
cluster-c"

# Make sure kubectl is installed
if ! [ -x "$(command -v kubectl)" ]; then
  echo 'Error: kubectl is required and was not found' >&2
  exit 1
fi

# Create and test the remote cluster kubeconfig files
for CLUSTER in $CLUSTERS
do
echo "Adding Managed cluster $CLUSTER to management cluster"
kubectl -o jsonpath="{.spec.installationManifest}" > $CLUSTER.yaml create -f - <<EOF
apiVersion: projectcalico.org/v3
kind: ManagedCluster
metadata:
  name: $CLUSTER
EOF

sed -i "" s,\<your-management-cluster-address\>,$MCMENDPOINT,g ./$CLUSTER.yaml
kubectl apply -f ./$CLUSTER.yaml --context $CLUSTER
done
