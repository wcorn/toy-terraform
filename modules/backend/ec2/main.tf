# BE ALB용 보안 그룹
resource "aws_security_group" "backend_alb_sg" {
  name        = "backend_alb_sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, {
    Name = "be-alb-sg"
  })
}

# BE 인스턴스용 보안 그룹: ALB에서 오는 트래픽 허용 (8080 포트)
resource "aws_security_group" "backend_sg" {
  name        = "backend_sg"
  description = "Allow traffic from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, {
    Name = "be-sg"
  })
}

# BE ALB
resource "aws_lb" "backend_alb" {
  name               = "backend-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.backend_alb_sg.id]
  tags = merge(var.common_tags, {
    Name = "be-alb"
  })
}

# BE ALB Target Group (포트 8080)
resource "aws_lb_target_group" "backend_tg" {
  name     = "back-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/api/time"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }
  tags = merge(var.common_tags, {
    Name = "be-tg"
  })
}

# BE ALB Listener (포트 443)
resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.cert_souel_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
  tags = merge(var.common_tags, {
    Name = "be-alb-listner"
  })
}
resource "random_password" "ssh_key" {
  length  = 16
  special = false
}
# BE SSH Key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "backend_key" {
  key_name   = "backend_key"
  public_key = tls_private_key.ssh_key.public_key_openssh
  tags = merge(var.common_tags, {
    Name = "be-key"
  })
}
resource "aws_secretsmanager_secret" "be_private_key" {
  name = "be_private_key-${random_password.ssh_key.result}"
  tags = merge(var.common_tags, {
    Name = "be-key-secret"
  })
}

resource "aws_secretsmanager_secret_version" "be_private_key_version" {
  secret_id     = aws_secretsmanager_secret.be_private_key.id
  secret_string = tls_private_key.ssh_key.private_key_pem
}

# BE 인스턴스 런치 템플릿 (Amazon Linux 2 AMI 사용, docker 및 codedeploy-agent 설치)
resource "aws_launch_template" "app_lt" {
  name_prefix   = "backend-"
  instance_type = "t3.medium"
  # 실제 사용하는 리전의 최신 Amazon Linux 2 AMI ID로 변경 필요
  image_id = "ami-062cddb9d94dcf95d"
  key_name = aws_key_pair.backend_key.key_name
  # EC2 인스턴스 보안 그룹 연결
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  user_data = base64encode(<<EOF
#!/bin/bash
sudo yum update -y
sudo yum install ruby -y
sudo yum install wget -y
sudo yum install docker -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user

cd /home/ec2-user
wget https://aws-codedeploy-ap-northeast-2.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo systemctl enable codedeploy-agent
sudo systemctl start codedeploy-agent
EOF
  )
  tags = merge(var.common_tags, {
    Name = "be-lt"
  })
}

# BE Auto Scaling Group: 최소 2대, 최대 4대로 두 개의 서브넷에 배포하며 ALB Target Group 연결
resource "aws_autoscaling_group" "backend_asg" {
  name                = "backend-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.backend_tg.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "be-ec2"
    propagate_at_launch = true
  }
}

# CodeDeploy를 위한 BE instance Role 
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-instance-role-for-codedeploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge(var.common_tags, {
    Name = "be-role"
  })
}

# S3 Artifact에 접근하기 위한 BE instance Role
resource "aws_iam_policy" "s3_artifact_policy" {
  name        = "s3-artifact-access-policy"
  description = "Allow EC2 instances to access CodePipeline artifact bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ],
        Resource = "*"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name = "be-s3-policy"
  })
}
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.s3_artifact_policy.arn
}
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile-for-codedeploy"
  role = aws_iam_role.ec2_instance_role.name
  tags = merge(var.common_tags, {
    Name = "be-iam-profile"
  })
}

# BE가 ECR에 접근하기 위한 정책
resource "aws_iam_policy" "ecr_auth_policy" {
  name        = "ECRGetAuthPolicy"
  description = "Allow getting ECR authorization token"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ecr:*",
        Resource = "*"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name = "be-ecr-policy"
  })
}
resource "aws_iam_role_policy_attachment" "ecr_auth_policy_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ecr_auth_policy.arn
}

