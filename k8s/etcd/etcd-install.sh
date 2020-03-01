#!/bin/bash

# 1. env info
source /etc/profile
declare -A dict

dict=(['etcd01']=172.17.173.15 ['etcd02']=172.17.173.16 ['etcd03']=172.17.173.17)
IP=`ip a |grep inet|grep -v 127.0.0.1|grep -v 172.17|gawk -F/ '{print $1}'|gawk '{print $NF}'`
#IP=`ip a |grep inet|grep -v 127.0.0.1|gawk -F/ '{print $1}'|gawk '{print $NF}'`

for key in ${!dict[*]};do
    if [[ "$IP" == "${dict[$key]}" ]];then
        LOCALIP=$IP
        LOCAL_ETCD_NAME=$key
    fi
done

if [[ "$LOCALIP" == "" || "$LOCAL_ETCD_NAME" == "" ]];then
    echo "Get localhost IP failed." && exit 1
fi

# 2. download etcd source code and decompress.
CURRENT_DIR=`pwd`
cd $CURRENT_DIR
#curl -L -C - -O https://github.com/etcd-io/etcd/releases/download/v3.3.18/etcd-v3.3.18-linux-amd64.tar.gz
#( [ $? -eq 0 ] && echo "etcd source code download success." ) || ( echo "etcd source code download failed." && exit 1 )

/usr/bin/tar -zxf etcd-v3.3.18-linux-amd64.tar.gz
cp etcd-v3.3.18-linux-amd64/etc* /usr/local/bin/
#rm -rf etcd-v3.3.18-linux-amd64*

# 3. deploy etcd config and enable etcd.service.

ETCD_SSL="/etc/kubernetes/ssl/etcd/"
ETCD_CONF=/etc/etcd/etcd.conf
ETCD_SERVICE=/usr/lib/systemd/system/etcd.service

[ ! -d /data/etcd/ ] && mkdir -p /data/etcd/
[ ! -d /etc/etcd/ ] && mkdir -p /etc/etcd/

# 3.1 create /etc/etcd/etcd.conf configure file.
cat > $ETCD_CONF << EOF
#[Member]
ETCD_NAME="${LOCAL_ETCD_NAME}"
ETCD_DATA_DIR="/data/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://${LOCALIP}:2380"
ETCD_LISTEN_CLIENT_URLS="https://${LOCALIP}:2379"
ETCD_LISTEN_CLIENT_URLS2="http://127.0.0.1:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://${LOCALIP}:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://${LOCALIP}:2379"
ETCD_INITIAL_CLUSTER="etcd01=https://${dict['etcd01']}:2380,etcd02=https://${dict['etcd02']}:2380,etcd03=https://${dict['etcd03']}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

# 3.2 create etcd.service
cat>$ETCD_SERVICE<<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target


[Service]
Type=notify
EnvironmentFile=$ETCD_CONF
ExecStart=/usr/local/bin/etcd \
--name=\${ETCD_NAME} \
--data-dir=\${ETCD_DATA_DIR} \
--listen-peer-urls=\${ETCD_LISTEN_PEER_URLS} \
--listen-client-urls=\${ETCD_LISTEN_CLIENT_URLS},\${ETCD_LISTEN_CLIENT_URLS2} \
--advertise-client-urls=\${ETCD_ADVERTISE_CLIENT_URLS} \
--initial-advertise-peer-urls=\${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
--initial-cluster=\${ETCD_INITIAL_CLUSTER} \
--initial-cluster-token=\${ETCD_INITIAL_CLUSTER_TOKEN} \
--initial-cluster-state=new \
--cert-file=/etc/kubernetes/ssl/etcd/etcd.pem \
--key-file=/etc/kubernetes/ssl/etcd/etcd-key.pem \
--peer-cert-file=/etc/kubernetes/ssl/etcd/etcd.pem \
--peer-key-file=/etc/kubernetes/ssl/etcd/etcd-key.pem \
--trusted-ca-file=/etc/kubernetes/ssl/ca/ca.pem \
--peer-trusted-ca-file=/etc/kubernetes/ssl/ca/ca.pem
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# 4. enable etcd.service and start
systemctl daemon-reload
systemctl enable etcd.service
systemctl start etcd.service
systemctl status etcd.service