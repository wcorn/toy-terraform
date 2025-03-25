output "cert_us_arn" {
  description = "MOABOA의 버지니아 북부 HTTPS Cert 인증서"
  value = aws_acm_certificate.cert_us.arn
}

output "cert_seoul_arn" {
  description = "MOABOA의 서울 HTTPS Cert 인증서"
  value = aws_acm_certificate.cert_seoul.arn
}