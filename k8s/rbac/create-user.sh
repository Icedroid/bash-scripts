#!/bin/bash

set -u
set -e
set -x

readonly WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly THIS_FILE="${WORKSPACE_DIR}/$(basename "${BASH_SOURCE[0]}")"

# source: https://github.com/rootsongjc/kubernetes-handbook/blob/master/tools/create-user/create-user.sh
# 生成的证书不能用！！！没有测试成功
# 每个对应一个namespace，用户名和namespace名称相同
# 注意修改KUBE_APISERVER为你的API Server的地址
KUBE_APISERVER=$1
USER=$2
USAGE="USAGE: create-user.sh <api_server> <username>\n
Example: https://172.22.1.1:6443 brand"

if [[ $KUBE_APISERVER == "" ]]; then
    echo -e $USAGE
    exit 1
fi
if [[ $USER == "" ]]; then
    echo -e $USAGE
    exit 1
fi

CSR_DIR=${WORKSPACE_DIR}/${USER}
CSR=${CSR_DIR}/user-csr.json
SSL_PATH="${WORKSPACE_DIR}/ssl/root-ca"
SSL_FILES=(ca-key.pem ca.pem ca-config.json)
CERT_FILES=(${USER}.csr $USER-key.pem ${USER}.pem)

# 创建用户的csr文件
function createCSR() {
    [ ! -d ${CSR_DIR} ] && mkdir ${CSR_DIR}

    cat >$CSR <<EOF
{
    "CN": "USER",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
    # 替换csr文件中的用户名
    sed -i '' "s/USER/$USER/g" $CSR
}

function ifExist() {
    if [ ! -f "$SSL_PATH/$1" ]; then
        echo "$SSL_PATH/$1 not found."
        exit 1
    fi
}

# 判断证书文件是否存在
for f in ${SSL_FILES[@]}; do
    echo "Check if ssl file $f exist..."
    ifExist $f
    echo "OK"
done

echo "Create CSR file..."
createCSR
echo "$CSR created"
echo "Create user's certificates and keys..."
cd "${CSR_DIR}"
cfssl gencert -ca="${SSL_PATH}/ca.pem" \
    -ca-key="${SSL_PATH}/ca-key.pem" \
    -config="${SSL_PATH}/ca-config.json" \
    -profile=kubernetes user-csr.json | cfssljson -bare $USER

# 校验证书
openssl x509 -noout -text -in ${CSR_DIR}/${USER}.pem

cd -

# 设置集群参数
kubectl config set-cluster kubernetes \
    --certificate-authority="${SSL_PATH}/ca.pem" \
    --embed-certs=true \
    --server="${KUBE_APISERVER}" \
    --kubeconfig="${USER}.kubeconfig"

# 设置客户端认证参数
kubectl config set-credentials "${USER}" \
    --client-certificate="$CSR_DIR/${USER}.pem" \
    --client-key="${CSR_DIR}/${USER}-key.pem" \
    --embed-certs=true \
    --kubeconfig="${USER}.kubeconfig"

# 设置上下文参数
kubectl config set-context kubernetes \
    --cluster=kubernetes \
    --user=$USER \
    --namespace=$USER \
    --kubeconfig=${USER}.kubeconfig

# 设置默认上下文
kubectl config use-context kubernetes --kubeconfig=${USER}.kubeconfig

# 创建 namespace
kubectl create ns $USER

# 绑定角色
kubectl create rolebinding ${USER}-admin-binding --clusterrole=admin --user=$USER --namespace=$USER --serviceaccount=$USER:default

kubectl config get-contexts --kubeconfig=${USER}.kubeconfig

echo "Congratulations!"
echo "Your kubeconfig file is ${USER}.kubeconfig"
