#!/usr/bin/env bash

# install kubeadm kubelet
sudo tee /etc/yum.repos.d/kubernetes.repo >/dev/null <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

sudo swapoff -a
#sudo sed -i 's/\/dev\/mapper\/centos-swap/#\/dev\/mapper\/centos-swap/gp' /etc/fstab
sudo yum makecache fast
sudo yum install -y kubeadm kubelet
systemctl enable kubelet


docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.17.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.5

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.17.3 k8s.gcr.io/kube-proxy:v1.17.3
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1 k8s.gcr.io/pause:3.1
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.5 k8s.gcr.io/coredns:1.6.5

docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.17.3
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.5