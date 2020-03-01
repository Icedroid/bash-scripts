#!/bin/bash

# CA签发根证书
# 1. download cfssl related files.
while true;
do
        echo "Download cfssl, please wait a monment." &&\
        curl -L -C - -O https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 && \
        curl -L -C - -O https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 && \
        curl -L -C - -O https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
        if [ $? -eq 0 ];then
                echo "cfssl download success."
                break
        else
                echo "cfssl download failed."
                break
        fi
done

# 2. Create a binary dirctory to store kubernetes related files.
if [ ! -d /usr/kubernetes/bin/ ];then
        mkdir -p /usr/kubernetes/bin/
fi

# 3. copy binary files to before create a binary dirctory.
mv cfssl_linux-amd64 /usr/kubernetes/bin/cfssl
mv cfssljson_linux-amd64 /usr/kubernetes/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/kubernetes/bin/cfssl-certinfo
chmod +x /usr/kubernetes/bin/{cfssl,cfssljson,cfssl-certinfo}

# 4. add environment variables
[ $(cat /etc/profile|grep 'PATH=/usr/kubernetes/bin'|wc -l ) -eq 0 ] && echo 'PATH=/usr/kubernetes/bin:$PATH' >>/etc/profile && source /etc/profile || source /etc/profile

# 5. create a CA certificate directory and access this directory
CA_SSL=/etc/kubernetes/ssl/ca
[ ! -d ${CA_SSL} ] && mkdir -p ${CA_SSL}
cd $CA_SSL

## cfssl print-defaults config > config.json
## cfssl print-defaults csr > csr.json
# 我们这里不使用上面两行命令生成

# 可以定义多个profiles,分别指定不同的过期时间,使用场景等参数,后续签名证书时使用某个profile;
# signing: 表示该证书可用于签名其它证书,生成的ca.pem证书中的CA=TRUE;
# server auth: 表示client 可以用该CA 对server 提供的证书进行校验;
# client auth: 表示server 可以用该CA 对client 提供的证书进行验证。
cat > ${CA_SSL}/ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF

# CN: Common Name, kube-apiserver从证书中提取该字段作为请求的用户名(User Name);浏览器使用该字段验证网站是否合法;
# O: Organization，kube-apiserver 从证书中提取该字段作为请求用户所属的组(Group)；

cat > ${CA_SSL}/ca-csr.json <<EOF
{
    "CN": "etcd CA",
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

# 6. generate ca.pem, ca-key.pem
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

[ $? -eq 0 ] && echo "CA certificate and private key generated successfully." || echo "CA certificate and private key generation failed."