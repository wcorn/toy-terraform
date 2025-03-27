# FE 정적 웹호스팅 S3
resource "aws_s3_bucket" "static_site" {
  bucket = "peter-frontend-ds3szlfa9q"  # 고유한 버킷 이름 사용
  force_destroy = true
  tags = merge(var.common_tags, {
    Name = "fe-s3"
  })
}

# FE S3 private ACL 지정
resource "aws_s3_bucket_ownership_controls" "static_site_oc" {
  bucket = aws_s3_bucket.static_site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "static_site_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.static_site_oc]

  bucket = aws_s3_bucket.static_site.id
  acl    = "private"
}

# static web public 접근 차단
resource "aws_s3_bucket_public_access_block" "static_site_access_block" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# static web config 페이지 라우팅 설정
resource "aws_s3_bucket_website_configuration" "static_site_web_config" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# cloudfront에서 사용한 oac 
resource "aws_cloudfront_origin_access_control" "cdn_oac" {
  name                              = aws_s3_bucket.static_site.bucket_regional_domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution 생성
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    # S3 버킷의 Regional 도메인을 origin으로 사용 (S3 REST API 엔드포인트)
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.static_site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cdn_oac.id

  }

  aliases = [ var.fe_domain_name ]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "CloudFront distribution for static site"

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.static_site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  custom_error_response {
    error_code            = 403
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 0
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = var.cert_us_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  tags = merge(var.common_tags, {
    Name = "fe-cdn"
  })
}

# S3와 CloudFront 연결 (CloudFront에 S3 Get 권한 부여)
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

# CloudFront의 Fe S3의 Get 권한 조회
data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.static_site.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        "${aws_cloudfront_distribution.cdn.arn}"
      ]
    }
  }
}

# FE S3 버전 관리 활성화
resource "aws_s3_bucket_versioning" "codepipeline_versioning" {
  bucket = aws_s3_bucket.static_site.id
  versioning_configuration {
    status = "Enabled"
  }
}