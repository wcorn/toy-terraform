# ALB용 보안 그룹: HTTP 80 포트 오픈
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
}

# EC2 인스턴스용 보안 그룹: ALB에서 오는 트래픽 허용 (8080 포트)
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
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.openvpn_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer 생성
resource "aws_lb" "backend_alb" {
  name               = "backend-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.backend_alb_sg.id]
}

# ALB Target Group 설정 (포트 8080)
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
}

# ALB Listener: 443 포트에 요청이 오면 Target Group으로 포워딩
resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.cert_souel_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# SSH Key 생성 (TLS provider 사용)
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "backend_key" {
  key_name   = "backend_key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_backend_key" {
  filename        = "backend_key.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}

# EC2 인스턴스 런치 템플릿 (Amazon Linux 2 AMI 사용, docker 설치 및 컨테이너 실행)
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
}

# Auto Scaling Group: 최소 2대, 최대 4대로 두 개의 서브넷에 배포하며 ALB Target Group 연결
resource "aws_autoscaling_group" "backend_asg" {
  name                      = "backend-asg"
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4
  vpc_zone_identifier       = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.backend_tg.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "backend-instance"
    propagate_at_launch = true
  }
}


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
}

resource "aws_iam_policy" "s3_artifact_policy" {
  name        = "s3-artifact-access-policy"
  description = "Allow EC2 instances to access CodePipeline artifact bucket"
  policy      = jsonencode({
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
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.s3_artifact_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile-for-codedeploy"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_policy" "ecr_auth_policy" {
  name        = "ECRGetAuthPolicy"
  description = "Allow getting ECR authorization token"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "ecr:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_auth_policy_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ecr_auth_policy.arn
}

