# 버지니아 북부 리전
provider "aws" {
  alias  = "alias_us_east_1"
  region = "us-east-1"
}

# 서울 리전
provider "aws" {
  alias  = "alias_seoul"
  region = "ap-northeast-2"
}

# US East 인증서 요청 (DNS 검증 방식)
resource "aws_acm_certificate" "cert_us" {
  provider          = aws.alias_us_east_1
  domain_name       = var.domain_name_prefix
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(var.common_tags, {
    Name = "route53-cert_us"
  })
}

# 서울 인증서 요청 (DNS 검증 방식)
resource "aws_acm_certificate" "cert_seoul" {
  provider          = aws.alias_seoul
  domain_name       = var.domain_name_prefix
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(var.common_tags, {
    Name = "route53-cert_seoul"
  })
}

# Route53 Hosted Zone 데이터 조회 (공용)
data "aws_route53_zone" "public" {
  name = var.domain_name
}

locals {
  combined_validation_options = merge(
    {
      for dvo in aws_acm_certificate.cert_us.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    },
    {
      for dvo in aws_acm_certificate.cert_seoul.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }
  )
}

# 공통 인증서 DNS 검증 레코드 생성
resource "aws_route53_record" "cert_validation" {
  for_each = local.combined_validation_options
  
  zone_id = data.aws_route53_zone.public.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

# US 인증서 검증 완료 처리
resource "aws_acm_certificate_validation" "cert_validation_us" {
  provider = aws.alias_us_east_1
  certificate_arn         = aws_acm_certificate.cert_us.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# 서울 인증서 검증 완료 처리
resource "aws_acm_certificate_validation" "cert_validation_seoul" {
  provider = aws.alias_seoul
  certificate_arn         = aws_acm_certificate.cert_seoul.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route53에 FE Record 추가 (CloueFront 연결)
resource "aws_route53_record" "alias_fe_record" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.fe_domain_name
  type    = "A"

  alias {
    name                   = var.fe_cdn_domain_name
    zone_id                = var.fe_cdn_domain_zone_id
    evaluate_target_health = false
  }
}

# Route53에 BE Record 추가 (BE ALB 연결)
resource "aws_route53_record" "alias_be_ecord" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.be_domain_name
  type    = "A"

  alias {
    name                   = var.be_alb_dns_name
    zone_id                = var.be_alb_zone_id
    evaluate_target_health = false
  }
}