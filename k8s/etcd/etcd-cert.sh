#!/bin/bash

# 使用私有CA为ETCD签发证书和私钥
# 2. create csr file.
source /etc/profile

ETCD_SSL="/etc/kubernetes/ssl/etcd/"

[ ! -d ${ETCD_SSL} ] && mkdir ${ETCD_SSL}
cat >$ETCD_SSL/etcd-csr.json << EOF
{
    "CN": "etcd",
    "hosts": [
    "192.168.50.12"
    ],
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

# 3. Determine if the ca required file exits.
[ ! -f /etc/kubernetes/ssl/ca/ca.pem ] && echo "no ca.pem file." && exit 0
[ ! -f /etc/kubernetes/ssl/ca/ca-key.pem ] && echo "no ca-key.pem file" && exit 0
[ ! -f /etc/kubernetes/ssl/ca/ca-config.json ] && echo "no ca-config.json file" && exit 0

# 4. generate etcd private key and public key.
cd $ETCD_SSL
cfssl gencert -ca=/etc/kubernetes/ssl/ca/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca/ca-config.json \
  -profile=kubernetes etcd-csr.json | cfssljson -bare etcd

[ $? -eq 0 ] && echo "Etcd certificate and private key generated successfully." || echo "Etcd certificate and private key generation failed."