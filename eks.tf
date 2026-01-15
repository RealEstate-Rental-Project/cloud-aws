# eks.tf

# 1. Le Cluster
resource "aws_eks_cluster" "main" {
  name     = "estate-rental-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    # On utilise les 4 sous-réseaux pour que le control plane soit partout
    subnet_ids = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id,
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# 2. Le Node Group (Optimisé pour tes 100$ et la RAM Java)
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "estate-rental-nodes"
  node_role_arn   = aws_iam_role.eks_nodes_role.arn

  # On déploie les serveurs uniquement dans les zones privées
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  instance_types = ["m7i-flex.large"] # 2 vCPU, 8 Go RAM par instance
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 3 # Total: 24 Go RAM (suffisant pour tes 7 services + Monitoring)
    max_size     = 4
    min_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.nodes_amazon_ec2_container_registry_read_only,
  ]
}

# 3. OIDC Provider (CRUCIAL pour l'ALB Controller)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}