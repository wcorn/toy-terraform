# S3 Bucket: Artifact 저장소 (Backend)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "codepipeline_backend_bucket" {
  bucket = "codepipeline-artifact-bucket-backend-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "backend_bucket_oc" {
  bucket = aws_s3_bucket.codepipeline_backend_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "backend_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.backend_bucket_oc]
  bucket     = aws_s3_bucket.codepipeline_backend_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "codepipeline_versioning" {
  bucket = aws_s3_bucket.codepipeline_backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ECR Repository
resource "aws_ecr_repository" "backend_repo" {
  name = "backend-springboot"
}

# IAM Role 및 Policy: CodeBuild
resource "aws_iam_role" "codebuild_backend_role" {
  name = "codebuild-backend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_policy" "codebuild_backend_policy" {
  name        = "codebuild-backend-policy"
  description = "Policy for CodeBuild project for Spring Boot backend"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "codebuild_backend_policy_attach" {
  role       = aws_iam_role.codebuild_backend_role.name
  policy_arn = aws_iam_policy.codebuild_backend_policy.arn
}

# ECR 접근을 위한 AWS 관리형 정책
resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy_attach" {
  role       = aws_iam_role.codebuild_backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role" "ecr_role" {
  name = "ecr-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_policy" "ecr_policy" {
  name        = "ecr-access-policy"
  description = "Policy granting necessary permissions to access and push to ECR"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecr_role_policy_attach" {
  role       = aws_iam_role.ecr_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

# CodeBuild Project: Backend Build
resource "aws_codebuild_project" "backend_build" {
  name           = "backend-build-project"
  description    = "Build project for Spring Boot backend application with Docker"
  build_timeout  = 20
  service_role   = aws_iam_role.codebuild_backend_role.arn
  source_version = "main"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "ECR_REPO_URI"
      value = aws_ecr_repository.backend_repo.repository_url
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "794038223418"
    }
    environment_variable {
      name  = "MYSQL_URL"
      value = var.db_instance_endpoint
    }
    environment_variable {
      name  = "MYSQL_USERNAME"
      value = var.db_instance_username
    }
    environment_variable {
      name  = "MYSQL_PASSWORD"
      value = var.db_instance_password
    }
  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }
}

# IAM Role 및 Policy: CodePipeline
resource "aws_iam_role" "codepipeline_backend_role" {
  name = "codepipeline-backend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_policy" "codepipeline_backend_policy" {
  name        = "codepipeline-backend-policy"
  description = "Policy for CodePipeline for backend deployment"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection",
          "codestar-connections:GetConnection",
          "codestar-connections:ListConnections"
        ],
        Resource = aws_codestarconnections_connection.github.arn
      },
      {
        Effect   = "Allow",
        Action   = "codedeploy:*",
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "codepipeline_backend_policy_attach" {
  role       = aws_iam_role.codepipeline_backend_role.name
  policy_arn = aws_iam_policy.codepipeline_backend_policy.arn
}

# IAM Role 및 Policy: CodeDeploy 설정
resource "aws_iam_role" "codedeploy_backend_role" {
  name = "codedeploy-backend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "codedeploy.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_policy" "codedeploy_autoscaling_policy" {
  name        = "codedeploy-autoscaling-policy"
  description = "Policy granting CodeDeploy permission to complete autoscaling lifecycle actions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "autoscaling:*",
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "codedeploy_autoscaling_policy_attach" {
  role       = aws_iam_role.codedeploy_backend_role.name
  policy_arn = aws_iam_policy.codedeploy_autoscaling_policy.arn
}
resource "aws_iam_role_policy_attachment" "codedeploy_backend_role_attach" {
  role       = aws_iam_role.codedeploy_backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# GitHub Connection (CodeStar)
resource "aws_codestarconnections_connection" "github" {
  name          = "wcorn"
  provider_type = "GitHub"
}

# CodeDeploy: Application 및 Deployment Group
resource "aws_codedeploy_app" "backend_deploy_app" {
  name             = "backend-codedeploy-app"
  compute_platform = "Server"
}

# ALB용 보안 그룹 (HTTP 80 포트 오픈)
resource "aws_security_group" "alb_deploy_sg" {
  name        = "alb_sg"
  description = "Allow inbound HTTP traffic for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

# Deploy ALB 
resource "aws_lb" "backend_deploy_alb" {
  name               = "backend-deploy-alb"
  load_balancer_type = "application"
  subnets            = var.private_subnet_ids
  security_groups    = [aws_security_group.alb_deploy_sg.id]
}

# Deploy ALB Target Group
resource "aws_lb_target_group" "backend_deploy_tg" {
  name     = "backend-deploy-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }
}

# Deploy ALB Listener
resource "aws_lb_listener" "backend_deploy_listener" {
  load_balancer_arn = aws_lb.backend_deploy_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_deploy_tg.arn
  }
}

resource "aws_codedeploy_deployment_group" "backend_deployment_group" {
  app_name              = aws_codedeploy_app.backend_deploy_app.name
  deployment_group_name = "backend-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_backend_role.arn
  autoscaling_groups = [var.backend_asg]

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  load_balancer_info {
    elb_info {
      name = aws_lb.backend_deploy_alb.name
    }
  }
}

# CodePipeline: CI/CD 파이프라인 구성 (Backend)
resource "aws_codepipeline" "backend_pipeline" {
  name          = "backend-codepipeline"
  pipeline_type = "V2"
  role_arn      = aws_iam_role.codepipeline_backend_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_backend_bucket.bucket
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = ["main"]
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "wcorn/toy-project-be" # GitHub 저장소 (필요 시 수정)
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.backend_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ApplicationName     = aws_codedeploy_app.backend_deploy_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.backend_deployment_group.deployment_group_name
      }
    }
  }
}
