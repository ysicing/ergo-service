#!/bin/bash

set -e

nfspath="/k8sdata"

[ -d ${nfspath} ] && exit 1

# 安装
apt update
apt install -y nfs-kernel-server
# 配置
mkdir ${nfspath}
echo "${nfspath}/ *(insecure,rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
# 启动nfs
systemctl enable rpcbind
systemctl enable nfs-server
systemctl start rpcbind
systemctl start nfs-server
exportfs -r
# 测试
showmount -e 127.0.0.1

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

nfsip=$(kubectl get node -o wide | grep $HOSTNAME | awk '{print $6}')

helm upgrade -i nfs-subdir-external-provisioner -n kube-system nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set image.repository=ccr.ccs.tencentyun.com/k7scn/nfs-subdir-external-provisioner \
    --set image.tag=v4.0.2 \
    --set nfs.server=${nfsip} \
    --set nfs.path=${nfspath} \
    --set storageClass.defaultClass=true \
    --set storageClass.name=opencfs