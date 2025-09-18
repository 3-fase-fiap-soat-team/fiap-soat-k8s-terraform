#!/bin/bash

echo "🔍 MONITORAMENTO DE LIMPEZA AWS"
echo "==============================="
echo "⏰ $(date)"
echo ""

echo "📋 Verificando recursos via CLI..."

# Verificar cluster EKS
echo "🎯 EKS Cluster:"
aws eks describe-cluster --name fiap-soat-cluster --region us-east-1 --query 'cluster.status' --output text 2>/dev/null || echo "   ❌ Cluster não encontrado/inacessível"

# Verificar instâncias EC2
echo ""
echo "💻 Instâncias EC2 com tag fiap-soat:"
aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Project,Values=fiap-soat-fase3" --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}' --output table 2>/dev/null || echo "   ❌ Nenhuma instância encontrada ou sem acesso"

# Verificar Launch Templates
echo ""
echo "🚀 Launch Templates:"
aws ec2 describe-launch-templates --region us-east-1 --filters "Name=tag:Project,Values=fiap-soat-fase3" --query 'LaunchTemplates[].{Name:LaunchTemplateName,ID:LaunchTemplateId}' --output table 2>/dev/null || echo "   ❌ Nenhum template encontrado ou sem acesso"

# Verificar Security Groups
echo ""
echo "🔒 Security Groups EKS:"
aws ec2 describe-security-groups --region us-east-1 --filters "Name=group-name,Values=fiap-soat-cluster-*" --query 'SecurityGroups[].{Name:GroupName,ID:GroupId}' --output table 2>/dev/null || echo "   ❌ Nenhum security group encontrado ou sem acesso"

echo ""
echo "🎯 Status da VPC (controlada pelo Terraform):"
aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Name,Values=fiap-soat-vpc" --query 'Vpcs[].{ID:VpcId,State:State,CIDR:CidrBlock}' --output table 2>/dev/null || echo "   ❌ VPC não encontrada ou sem acesso"

echo ""
echo "💰 Para verificar custos, monitore o billing no console AWS"
echo "⏰ Execute este script novamente após deletar no console"
