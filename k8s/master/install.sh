#!/usr/bin/env bash

# install kubeadm kubelet kubectl
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
sudo yum install -y kubeadm kubelet kubectl
systemctl enable kubelet

docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.17.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.17.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.17.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.17.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
#docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.3-0
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.5

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.17.3 k8s.gcr.io/kube-apiserver:v1.17.3
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.17.3 k8s.gcr.io/kube-controller-manager:v1.17.3
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.17.3 k8s.gcr.io/kube-scheduler:v1.17.3
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.17.3 k8s.gcr.io/kube-proxy:v1.17.3
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1 k8s.gcr.io/pause:3.1
#docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.3-0 k8s.gcr.io/etcd:3.4.3-0
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.5 k8s.gcr.io/coredns:1.6.5

docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.17.3
dcoker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.17.3
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.17.3
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.17.3
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.5

# install calico after kubeadm init 
# wget  https://docs.projectcalico.org/v3.11/manifests/calico.yaml
# kubectl apply -f calico.yaml