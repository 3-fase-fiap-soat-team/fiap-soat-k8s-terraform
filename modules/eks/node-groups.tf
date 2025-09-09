# IAM Role para Node Groups
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-role"
  })
}

# Políticas necessárias para os nodes
resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# Security Group para Node Groups
resource "aws_security_group" "node_group" {
  name_prefix = "${var.cluster_name}-node-group-"
  vpc_id      = var.vpc_id

  # Permitir todo tráfego interno dentro do cluster
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  # Acesso SSH (comentado para segurança - descomente se necessário)
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }

  # CoreDNS
  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "udp"
    self      = true
  }

  # Todo tráfego de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-sg"
  })
}

# Comunicação Kubelet entre cluster e nodes
resource "aws_security_group_rule" "node_group_ingress_cluster_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node_group.id
}

# Comunicação HTTPS entre cluster e nodes
resource "aws_security_group_rule" "node_group_ingress_cluster_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node_group.id
}

# Launch Template para nodes (configurações otimizadas)
resource "aws_launch_template" "node_group" {
  name_prefix = "${var.cluster_name}-node-group-"

  # User data para otimização AWS Academy
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    cluster_name = var.cluster_name
  }))

  # Configurações de instância
  instance_type = var.node_groups.general.instance_types[0]

  vpc_security_group_ids = [aws_security_group.node_group.id]

  # Configurações de rede
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Monitoramento desabilitado para economia
  monitoring {
    enabled = false
  }

  # EBS otimizado para economia
  ebs_optimized = false

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-node"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-launch-template"
  })
}

# EKS Node Group
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "general"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = var.node_groups.general.capacity_type
  instance_types = var.node_groups.general.instance_types

  scaling_config {
    desired_size = var.node_groups.general.desired_size
    max_size     = var.node_groups.general.max_size
    min_size     = var.node_groups.general.min_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.node_group.id
    version = aws_launch_template.node_group.latest_version
  }

  # Labels importantes para workloads
  labels = {
    Environment = var.environment
    NodeGroup   = "general"
    Project     = "fiap-soat"
  }

  # Taints para controle de workloads (comentado para simplicidade)
  # taint {
  #   key    = "node-type"
  #   value  = "general"
  #   effect = "NO_SCHEDULE"
  # }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-general"
  })
}
