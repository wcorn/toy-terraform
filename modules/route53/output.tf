output "cert_us_arn" {
  value = aws_acm_certificate.cert_us.arn
}

output "cert_seoul_arn" {
  value = aws_acm_certificate.cert_seoul.arn
}