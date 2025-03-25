output "fe_bucket" {
  description = "FE 버킷"
  value = aws_s3_bucket.static_site.bucket
}

output "fe_cdn_domain_name" {
  description = "CloudFront 배포의 Hosted Zone ID"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "fe_cdn_domain_zone_id" {
  description = "CloudFront 배포의 Hosted Zone ID"
  value       = aws_cloudfront_distribution.cdn.hosted_zone_id
}