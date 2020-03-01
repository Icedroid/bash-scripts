#!/bin/bash

#set -u 
set -e
set -x 

# change yum repo
echo "change yum repo -> aliyun repo"
sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
sudo wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
sudo wget -P /etc/yum.repos.d/ http://mirrors.aliyun.com/repo/epel-7.repo 

# 1. install common tools,these commands are not required.
source /etc/profile
yum -y update && yum -y install chrony bridge-utils chrony ipvsadm ipset sysstat conntrack libseccomp wget tcpdump \
      vim nfs-utils bind-utils socat telnet sshpass net-tools sysstat lrzsz yum-utils \
      device-mapper-persistent-data lvm2 tree nc lsof strace nmon iptraf iftop rpcbind mlocate

# 2. disable IPv6
if [[ $(cat /etc/default/grub |grep 'ipv6.disable=1' |grep GRUB_CMDLINE_LINUX|wc -l) -eq 0 ]];then
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ipv6.disable=1 /' /etc/default/grub
    /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
fi

# 3. disable NetworkManager
systemctl stop NetworkManager
systemctl disable NetworkManager

# 3. time 
systemctl enable chronyd.service
systemctl start chronyd.service
# 4. add bridge-nf-call-ip6tables ,notice: You may need to run '/usr/sbin/modprobe br_netfilter' this commond after reboot.
cat > /etc/rc.sysinit << EOF
#!/bin/bash
for file in /etc/sysconfig/modules/*.modules ; do
[ -x $file ] && $file
done
EOF

cat > /etc/sysconfig/modules/br_netfilter.modules << EOF
modprobe br_netfilter
EOF

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
chmod 755 /etc/sysconfig/modules/br_netfilter.modules

# 5. add route forwarding
[ $(cat /etc/sysctl.conf | grep "net.ipv4.ip_forward=1" |wc -l) -eq 0 ] && echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "net.bridge.bridge-nf-call-iptables=1" |wc -l) -eq 0 ] && echo "net.bridge.bridge-nf-call-iptables=1" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "net.bridge.bridge-nf-call-ip6tables=1" |wc -l) -eq 0 ] && echo "net.bridge.bridge-nf-call-ip6tables=1" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "fs.may_detach_mounts=1" |wc -l) -eq 0 ] && echo "fs.may_detach_mounts=1" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "vm.overcommit_memory=1" |wc -l) -eq 0 ] && echo "vm.overcommit_memory=1" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "vm.panic_on_oom=0" |wc -l) -eq 0 ] && echo "vm.panic_on_oom=0" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "vm.swappiness=0" |wc -l) -eq 0 ] && echo "vm.swappiness=0" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "fs.inotify.max_user_watches=89100" |wc -l) -eq 0 ] && echo "fs.inotify.max_user_watches=89100" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "fs.file-max=52706963" |wc -l) -eq 0 ] && echo "fs.file-max=52706963" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "fs.nr_open=52706963" |wc -l) -eq 0 ] && echo "fs.nr_open=52706963" >>/etc/sysctl.conf
[ $(cat /etc/sysctl.conf | grep "net.netfilter.nf_conntrack_max=2310720" |wc -l) -eq 0 ] && echo "net.netfilter.nf_conntrack_max=2310720" >>/etc/sysctl.conf
/usr/sbin/sysctl -p


# 6. modify limit file
[ $(cat /etc/security/limits.conf|grep '* soft nproc 10240000'|wc -l) -eq 0 ] && echo '* soft nproc 10240000' >>/etc/security/limits.conf
[ $(cat /etc/security/limits.conf|grep '* hard nproc 10240000'|wc -l) -eq 0 ] && echo '* hard nproc 10240000' >>/etc/security/limits.conf
[ $(cat /etc/security/limits.conf|grep '* soft nofile 10240000'|wc -l) -eq 0 ] && echo '* soft nofile 10240000' >>/etc/security/limits.conf
[ $(cat /etc/security/limits.conf|grep '* hard nofile 10240000'|wc -l) -eq 0 ] && echo '* hard nofile 10240000' >>/etc/security/limits.conf

# 6. disable selinux
sed -i '/SELINUX=/s/enforcing/disabled/' /etc/selinux/config

# 6. Close the swap partition
/usr/sbin/swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab

# 7. disable firewalld
systemctl stop firewalld
systemctl disable firewalld

# 8. reset iptables
yum install -y iptables-services
/usr/sbin/iptables -P FORWARD ACCEPT
#/usr/sbin/iptables -X
/usr/sbin/iptables -F -t nat
/usr/sbin/iptables -F -t nat
echo "确认一下iptables filter表中FOWARD链的默认策略(policy)为ACCEPT"
iptables -nvL

# 9. install docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 
yum list docker-ce.x86_64 --showduplicates | sort -r
yum makecache fast && yum -y install docker-ce

# 使用systemd作为docker的cgroup driver可以确保服务器节点在资源紧张的情况更加稳定
echo "edit /etc/docker/daemon.json"
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF

systemctl daemon-reload
systemctl enable docker.service
systemctl start docker.service