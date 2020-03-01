

$ kubeadm init --config=kubeadm-config.yaml

```bash
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/


You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join 192.168.50.12:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:09e79b04ec0f7c8eefdf9b5eae37d32e9ec078d3de4bcf64bdfa4627fff99c80 \
    --control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.50.12:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:09e79b04ec0f7c8eefdf9b5eae37d32e9ec078d3de4bcf64bdfa4627fff99c80

```
