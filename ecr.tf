# Liste de tous tes services (Java Core + FastAPI AI)
variable "repository_names" {
  type    = list(string)
  default = [
    "auth-server",
    "gateway-service",
    "user-management",
    "property-service",
    "rental-agreement",
    "notification-service",
    "public-app",
    "ai-heatmap",
    "ai-recommendation",
    "ai-scoring"
  ]
}

# Création automatique des dépôts
resource "aws_ecr_repository" "microservices" {
  for_each             = toset(var.repository_names)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true # Analyse de sécurité automatique (très bien pour ton CV !)
  }
}

# Règle de nettoyage (Lifecycle Policy)
# Garde seulement les 5 dernières images pour ne pas payer de stockage inutile
resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = aws_ecr_repository.microservices
  repository = each.value.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 5 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}