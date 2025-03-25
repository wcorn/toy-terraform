# FE Pipeline Artifact 저장소 S3
resource "aws_s3_bucket" "codepipeline_fe_bucket" {
  bucket = "codepipeline-artifact-bucket-fe-${random_id.bucket_suffix.hex}"
  force_destroy = true
}
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# FE Pipeline Artifact 저장소 S3 private ACL 지정
resource "aws_s3_bucket_ownership_controls" "static_site_oc" {
  bucket = aws_s3_bucket.codepipeline_fe_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "static_site_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.static_site_oc]

  bucket = aws_s3_bucket.codepipeline_fe_bucket.id
  acl    = "private"
}

# FE Pipeline Artifact 저장소 S3 버저닝 설정
resource "aws_s3_bucket_versioning" "codepipeline_versioning" {
  bucket = aws_s3_bucket.codepipeline_fe_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role 및 Policy: CodeBuild 설정
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-react-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild-react-policy"
  description = "Policy for CodeBuild project"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
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
resource "aws_iam_role_policy_attachment" "codebuild_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# CodeBuild Project: React 빌드 설정 
resource "aws_codebuild_project" "react_build" {
  name          = "react-build-project"
  description   = "Build project for React application"
  build_timeout = 20
  service_role  = aws_iam_role.codebuild_role.arn
  source_version = "main"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"

  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 1
    buildspec       = <<EOF
version: 0.2
phases:
  install:
    commands:
      - npm install
  build:
    commands:
      - npm run build
artifacts:
  base-directory: build
  files:
    - '**/*'
EOF
  }
}

# IAM Role 및 Policy: CodePipeline 설정
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-react-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_policy" "codepipeline_policy" {
  name        = "codepipeline-react-policy"
  description = "Policy for CodePipeline"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
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
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# github connection
resource "aws_codestarconnections_connection" "github" {
  name          = "wcorn"
  provider_type = "GitHub"
}

# CodePipeline: CI/CD 파이프라인 구성 
resource "aws_codepipeline" "react_pipeline" {
  name     = "react-codepipeline"
  pipeline_type = "V2"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_fe_bucket.bucket
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
        ConnectionArn     = aws_codestarconnections_connection.github.arn
        FullRepositoryId  = "wcorn/toy-project-fe"
        BranchName        = "main"
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
        ProjectName = aws_codebuild_project.react_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = var.fe_bucket
        Extract    = "true"
      }
    }
  }
}