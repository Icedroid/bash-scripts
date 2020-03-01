#!/bin/bash

declare -A dict
dict=(['etcd01']=172.17.173.15 ['etcd02']=172.17.173.16 ['etcd03']=172.17.173.17)

cd /usr/local/bin
etcdctl --ca-file=/etc/kubernetes/ssl/ca/ca.pem \
--cert-file=/etc/kubernetes/ssl/etcd/etcd.pem \
--key-file=/etc/kubernetes/ssl/etcd/etcd-key.pem \
--endpoints="https://${dict['etcd01']}:2379,https://${dict['etcd02']}:2379,https://${dict['etcd03']}:2379" cluster-health

etcdctl --ca-file=/etc/kubernetes/ssl/ca/ca.pem \
--cert-file=/etc/kubernetes/ssl/etcd/etcd.pem \
--key-file=/etc/kubernetes/ssl/etcd/etcd-key.pem \
--endpoints="https://${dict['etcd01']}:2379,https://${dict['etcd02']}:2379,https://${dict['etcd03']}:2379" member list

ETCDCTL_API=3 etcdctl --cacert=/etc/kubernetes/ssl/ca/ca.pem \
--cert=/etc/kubernetes/ssl/etcd/etcd.pem \
--key=/etc/kubernetes/ssl/etcd/etcd-key.pem \
--endpoints="https://192.168.50.12:2379" \
get "" --prefix=true

ETCDCTL_API=3 etcdctl --cacert=/etc/kubernetes/ssl/ca/ca.pem \
--cert=/etc/kubernetes/ssl/etcd/etcd.pem \
--key=/etc/kubernetes/ssl/etcd/etcd-key.pem \
--endpoints="https://192.168.50.12:2379" \
get "" --from-key

# ETCDCTL_API=3 etcdctl --cacert=/etc/kubernetes/ssl/ca/ca.pem \
# --cert=/etc/kubernetes/ssl/etcd/etcd.pem \
# --key=/etc/kubernetes/ssl/etcd/etcd-key.pem \
# --endpoints="https://192.168.50.12:2379" \
# del "" --prefix=true