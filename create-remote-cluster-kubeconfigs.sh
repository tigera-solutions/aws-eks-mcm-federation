#! /usr/bin/env bash

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
echo "Create remote cluster kubeconfig for $CLUSTER"
cat > ./$CLUSTER-kubeconfig <<'EOF'
apiVersion: v1
kind: Config
users:
- name: tigera-federation-remote-cluster
  user:
    token: YOUR_SERVICE_ACCOUNT_TOKEN
clusters:
- name: tigera-federation-remote-cluster
  cluster:
    certificate-authority-data: YOUR_CERTIFICATE_AUTHORITY_DATA
    server: YOUR_SERVER_ADDRESS
contexts:
- name: tigera-federation-remote-cluster-ctx
  context:
    cluster: tigera-federation-remote-cluster
    user: tigera-federation-remote-cluster
current-context: tigera-federation-remote-cluster-ctx
EOF

YOUR_SERVICE_ACCOUNT_TOKEN=$(kubectl get secret -n kube-system --context $CLUSTER $(kubectl get sa -n kube-system --context $CLUSTER tigera-federation-remote-cluster -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep token) -o go-template='{{.data.token|base64decode}}'
)
YOUR_CERTIFICATE_AUTHORITY_DATA=$(kubectl config view --flatten --minify --context $CLUSTER -o jsonpath='{range .clusters[*]}{.cluster.certificate-authority-data}{"\n"}{end}')
YOUR_SERVER_ADDRESS=$(kubectl config view --flatten --minify --context $CLUSTER -o jsonpath='{range .clusters[*]}{.cluster.server}{"\n"}{end}')

sed -i "" s,YOUR_SERVICE_ACCOUNT_TOKEN,$YOUR_SERVICE_ACCOUNT_TOKEN,g ./$CLUSTER-kubeconfig
sed -i "" s,YOUR_CERTIFICATE_AUTHORITY_DATA,$YOUR_CERTIFICATE_AUTHORITY_DATA,g ./$CLUSTER-kubeconfig
sed -i "" s,YOUR_SERVER_ADDRESS,$YOUR_SERVER_ADDRESS,g ./$CLUSTER-kubeconfig

echo "Test remote cluster kubeconfig for $CLUSTER"
kubectl --kubeconfig ./$CLUSTER-kubeconfig get services
done
