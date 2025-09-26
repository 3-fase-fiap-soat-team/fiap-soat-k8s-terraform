# Subnets para EKS - AWS Academy optimized
# Configuração mínima para economia de custos

# Public Subnets (para Load Balancers e NAT se necessário)
# Subnets públicas
resource "aws_subnet" "public" {
  count = length(local.availability_zones) # Usar zonas fixas

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-${count.index + 1}"
    Environment = var.environment
    Type        = "public"
    Project     = "fiap-soat-fase3"
    # Tags obrigatórias para EKS
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

# Private Subnets (para EKS nodes)
# Subnets privadas
resource "aws_subnet" "private" {
  count = length(local.availability_zones) # Usar zonas fixas

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-private-${count.index + 1}"
    Environment = var.environment
    Type        = "private"
    Project     = "fiap-soat-fase3"
    # Tags obrigatórias para EKS
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# NAT Gateway (apenas 1 para economia - AWS Academy)
# Descomentado mas controlado por variável enable_nat_gateway
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
    Project     = "fiap-soat-fase3"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.project_name}-nat"
    Environment = var.environment
    Project     = "fiap-soat-fase3"
  }

  depends_on = [aws_internet_gateway.main]
}
