# db.tf

# 1. Groupe de sous-réseaux (RDS doit savoir où se placer)
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = { Name = "Main DB Subnet Group" }
}

# 2. Security Group pour la base de données (Autorise le trafic venant d'EKS)
resource "aws_security_group" "rds_sg" {
  name        = "allow-eks-to-rds"
  description = "Allow MySQL traffic from EKS nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "MySQL from EKS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # On autorise uniquement les serveurs du cluster EKS
    cidr_blocks = [aws_subnet.private_1.cidr_block, aws_subnet.private_2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. L'instance RDS MySQL
resource "aws_db_instance" "main" {
  allocated_storage      = 20
  db_name                = "estaterentaldb" # Le nom de ta base
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # Éligible Free Tier
  username               = "admin"
  password               = "votre_mot_de_passe_securise" # À changer !
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false # Sécurité : non accessible depuis internet

  tags = { Name = "estate-rental-db" }
}

# 4. Output pour récupérer l'adresse DNS de la base
output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}