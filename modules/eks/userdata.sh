#!/bin/bash

# User Data Script para EKS Nodes - AWS Academy Optimized
# Configurações de otimização para reduzir custos

set -e

# Configurações básicas do sistema
echo "=== Configurando sistema ==="

# Desabilitar swappiness para otimização K8s
echo 'vm.swappiness=1' >> /etc/sysctl.conf
sysctl -w vm.swappiness=1

# Configurar limits para containers
echo '* soft nofile 65536' >> /etc/security/limits.conf
echo '* hard nofile 65536' >> /etc/security/limits.conf

# Otimizar configurações de rede
echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

# Aplicar configurações de sysctl
sysctl --system

# Bootstrap do EKS (será executado automaticamente pelo AMI)
echo "=== Configurando EKS Node ==="

# O bootstrap do EKS será chamado automaticamente
# /etc/eks/bootstrap.sh ${cluster_name}

# Configurações adicionais de otimização
echo "=== Configurações de otimização ==="

# Desabilitar serviços desnecessários para economia de recursos
systemctl disable amazon-ssm-agent || true
systemctl stop amazon-ssm-agent || true

# Configurar log rotation mais agressivo para economizar espaço
cat > /etc/logrotate.d/docker-containers << EOF
/var/lib/docker/containers/*/*.log {
    rotate 2
    daily
    compress
    size 10M
    missingok
    delaycompress
    copytruncate
}
EOF

# Configurar kubelet com otimizações
mkdir -p /etc/kubernetes/kubelet
cat > /etc/kubernetes/kubelet/kubelet-config.json << EOF
{
    "kind": "KubeletConfiguration",
    "apiVersion": "kubelet.config.k8s.io/v1beta1",
    "address": "0.0.0.0",
    "port": 10250,
    "readOnlyPort": 0,
    "cgroupDriver": "systemd",
    "hairpinMode": "hairpin-veth",
    "serializeImagePulls": false,
    "featureGates": {
        "RotateKubeletServerCertificate": true
    },
    "maxPods": 17,
    "failSwapOn": false,
    "containerLogMaxSize": "10Mi",
    "containerLogMaxFiles": 3,
    "systemReserved": {
        "cpu": "100m",
        "memory": "100Mi",
        "ephemeral-storage": "1Gi"
    },
    "kubeReserved": {
        "cpu": "100m",
        "memory": "100Mi",
        "ephemeral-storage": "1Gi"
    },
    "evictionHard": {
        "memory.available": "100Mi",
        "nodefs.available": "5%",
        "nodefs.inodesFree": "5%",
        "imagefs.available": "5%"
    }
}
EOF

echo "=== User Data Script Completed ==="
