#!/bin/bash

set -u
set -e
set -x

readonly WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly THIS_FILE="${WORKSPACE_DIR}/$(basename "${BASH_SOURCE[0]}")"

# ./get-token-kubeconfig.sh admin kube-system
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

KUBECONFIG=${user}.kubeconfig
# kubectl create ns ${namespace}
# kubectl apply -f ${WORKSPACE_DIR}/rbac.yaml

# kubectl create sa default -n ${namespace}
secret=$(kubectl get sa ${user} -n ${namespace} -o json | jq -r .secrets[].name)
kubectl get secret ${secret} -n ${namespace} -o json | jq -r '.data["ca.crt"]' | base64 -D > ca.crt

user_token=$(kubectl get secret ${secret} -n ${namespace} -o json | jq -r '.data["token"]' | base64 -D)
c=$(kubectl config current-context)
cluster_name=$(kubectl config get-contexts $c | awk '{print $3}' | tail -n 1)
endpoint=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"${cluster_name}\")].cluster.server}")

# Set up the config
KUBECONFIG=${KUBECONFIG} kubectl config set-cluster ${cluster_name} \
    --embed-certs=true \
    --server=${endpoint} \
    --certificate-authority=./ca.crt

KUBECONFIG=${KUBECONFIG} kubectl config set-credentials ${user}-${cluster_name#cluster-} --token=${user_token}
KUBECONFIG=${KUBECONFIG} kubectl config set-context ${user}-${cluster_name#cluster-} \
    --cluster=${cluster_name} \
    --user=${user}-${cluster_name#cluster-}
KUBECONFIG=${KUBECONFIG} kubectl config use-context ${user}-${cluster_name#cluster-}

rm -f ./ca.crt

echo "export KUBECONFIG=${KUBECONFIG}"
echo "kubectl get pods -n ${namespace}"
