# Database 보안 그룹
resource "aws_security_group" "database" {
  name        = "database-subnet-security-group"
  description = "Security group for database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "db_subnet_group"
  }
}

# 랜덤 비밀번호 생성 
resource "random_password" "db" {
  length  = 16
  special = false
}
resource "random_password" "db_password_name" {
  length  = 16
  special = false
}
# Secrets Manager를 사용해 DB 접속 정보 저장
resource "aws_secretsmanager_secret" "db_password" {
  name = "db/password-${random_password.db_password_name.result}"
}
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db.result
  })
}

# db 인스턴스 생성
resource "aws_db_instance" "mydb" {
  identifier             = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = jsondecode(aws_secretsmanager_secret_version.db_password_version.secret_string)["password"]
  db_name = "test"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
}