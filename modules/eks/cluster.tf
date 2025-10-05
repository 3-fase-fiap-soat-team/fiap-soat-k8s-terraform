# EKS Cluster Configuration for AWS Academy
# Uses pre-created IAM roles: LabEksClusterRole and LabEksNodeRole

# Data sources para listar todas as roles e buscar as corretas
data "aws_iam_roles" "all" {
  name_regex = ".*Lab.*"
}

# Locals para encontrar as roles corretas dinamicamente
locals {
  # Buscar role do cluster (contém "LabEksClusterRole" no nome)
  cluster_role_name = try(
    [for role in data.aws_iam_roles.all.names : role if strcontains(role, "LabEksClusterRole")][0],
    var.cluster_role_name != null ? var.cluster_role_name : ""
  )
  
  # Buscar role dos nodes (contém "LabEksNodeRole" no nome)
  node_role_name = try(
    [for role in data.aws_iam_roles.all.names : role if strcontains(role, "LabEksNodeRole")][0],
    var.node_role_name != null ? var.node_role_name : ""
  )
}

# Data sources para obter detalhes das IAM roles descobertas
data "aws_iam_role" "cluster_role" {
  name = local.cluster_role_name
}

data "aws_iam_role" "node_role" {
  name = local.node_role_name
}

# Data source for current AWS region
data "aws_region" "current" {}

# Data source para Security Group do cluster existente (se fornecido)
data "aws_security_group" "cluster" {
  count = var.create_security_groups ? 0 : 1
  id    = var.cluster_security_group_id
}

# Data source para Security Group dos nodes existente (se fornecido)
data "aws_security_group" "node_group" {
  count = var.create_security_groups ? 0 : 1
  id    = var.node_security_group_id
}

# Local para determinar qual SG usar (existente ou novo)
locals {
  cluster_sg_id   = var.create_security_groups ? aws_security_group.cluster[0].id : data.aws_security_group.cluster[0].id
  node_group_sg_id = var.create_security_groups ? aws_security_group.node_group[0].id : data.aws_security_group.node_group[0].id
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = data.aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids              = var.use_public_subnets_for_nodes ? var.public_subnet_ids : var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [local.cluster_sg_id]
  }

  # Enable control plane logging (optional, can be disabled to save costs)
  enabled_cluster_log_types = []

  # Timeout configuration for EKS cluster creation/updates
  timeouts {
    create = "30m"  # EKS cluster can take up to 20-25 minutes to create
    update = "60m"
    delete = "15m"
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })

  depends_on = [
    data.aws_iam_role.cluster_role
  ]
}

# Security Group for EKS Cluster (criado apenas se create_security_groups = true)
resource "aws_security_group" "cluster" {
  count = var.create_security_groups ? 1 : 0
  
  name_prefix = "${var.cluster_name}-cluster-"
  vpc_id      = var.vpc_id

  # Egress rules for cluster
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NTP
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })
}

# Security Group for Node Groups (criado apenas se create_security_groups = true)
resource "aws_security_group" "node_group" {
  count = var.create_security_groups ? 1 : 0
  
  name_prefix = "${var.cluster_name}-node-group-"
  vpc_id      = var.vpc_id

  # Allow all traffic within the security group
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  # DNS
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

  # Allow all outbound traffic
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

# Security Group Rules for communication between cluster and nodes
resource "aws_security_group_rule" "cluster_ingress_node_https" {
  count = var.create_security_groups ? 1 : 0
  
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.node_group_sg_id
  security_group_id        = local.cluster_sg_id
}

resource "aws_security_group_rule" "node_group_ingress_cluster_https" {
  count = var.create_security_groups ? 1 : 0
  
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.cluster_sg_id
  security_group_id        = local.node_group_sg_id
}

resource "aws_security_group_rule" "node_group_ingress_cluster_kubelet" {
  count = var.create_security_groups ? 1 : 0
  
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = local.cluster_sg_id
  security_group_id        = local.node_group_sg_id
}

# Launch Template for Node Groups
resource "aws_launch_template" "node_group" {
  name_prefix   = "${var.cluster_name}-node-group-"
  instance_type = var.node_groups.general.instance_types[0]
  
  vpc_security_group_ids = [local.node_group_sg_id]
  
  # Sem user data - usar AMI otimizado do EKS padrão
  # user_data = base64encode(templatefile("${path.module}/userdata-simple.sh", {
  #   cluster_name = var.cluster_name
  # }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = false  # Disable detailed monitoring to save costs
  }

  # EBS optimization disabled for cost savings on smaller instances
  ebs_optimized = "false"

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
  node_role_arn   = data.aws_iam_role.node_role.arn
  subnet_ids      = var.use_public_subnets_for_nodes ? var.public_subnet_ids : var.private_subnet_ids

  # Use the launch template
  launch_template {
    id      = aws_launch_template.node_group.id
    version = aws_launch_template.node_group.latest_version
  }

  # Capacity configuration - optimized for AWS Academy
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_groups.general.desired_size
    max_size     = var.node_groups.general.max_size
    min_size     = var.node_groups.general.min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Timeout configuration for node group creation
  timeouts {
    create = "20m"  # Node groups typically take 10-15 minutes
    update = "20m"
    delete = "20m"
  }

  # Node group labels
  labels = {
    Environment = var.environment
    NodeGroup   = "general"
    Project     = "fiap-soat"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-general"
  })

  depends_on = [
    aws_eks_cluster.main,
    aws_launch_template.node_group
  ]
}

# EKS Add-ons (essential only to control costs)
resource "aws_eks_addon" "addons" {
  for_each = var.cluster_addons

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = each.key
  addon_version            = each.value.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_node_group.general
  ]
}
