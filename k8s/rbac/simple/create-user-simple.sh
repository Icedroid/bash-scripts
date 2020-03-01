#!/bin/bash

set -e 
set -u
set -x

if [[ -z "$1" ]] ;then
  echo "usage: $0 <namespace>"
  exit 1
fi
if [[ -z "$1" ]] ;then
  echo "usage: $0 <username> <namespace>"
  exit 1
fi

user=$1
namespace=$2
kubectl create ns ${namespace}
# kubectl create sa default -n ${namespace}
secret=$(kubectl get sa default -n ${namespace} -o json | jq -r .secrets[].name)
kubectl get secret ${secret} -n ${namespace} -o json | jq -r '.data["ca.crt"]' | base64 -D > ca.crt

user_token=$(kubectl get secret ${secret} -n ${namespace} -o json | jq -r '.data["token"]' | base64 -D)
c=$(kubectl config current-context)
cluster_name=$(kubectl config get-contexts $c | awk '{print $3}' | tail -n 1)
endpoint=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"${cluster_name}\")].cluster.server}")

# Set up the config
KUBECONFIG=k8s-${user}-conf kubectl config set-cluster ${cluster_name} \
    --embed-certs=true \
    --server=${endpoint} \
    --certificate-authority=./ca.crt

KUBECONFIG=k8s-${user}-conf kubectl config set-credentials ${user}-${cluster_name#cluster-} --token=${user_token}
KUBECONFIG=k8s-${user}-conf kubectl config set-context ${user}-${cluster_name#cluster-} \
    --cluster=${cluster_name} \
    --user=${user}-${cluster_name#cluster-}
KUBECONFIG=k8s-${user}-conf kubectl config use-context ${user}-${cluster_name#cluster-}

cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${user}-admin-binding
subjects:
- kind: ServiceAccount
  name: default
  namespace: ${namespace}
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io

EOF


echo "done! Test with: "
echo "export KUBECONFIG=k8s-${user}-conf"
echo "kubectl get pods -n ${namespace}"
