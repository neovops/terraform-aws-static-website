output "s3_bucket_name" {
  value = aws_s3_bucket.website.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.distribution.arn
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.distribution.id
}

output "basic_auth_secret_arn" {
  value = var.enable_basic_auth ? aws_secretsmanager_secret.basic_auth.0.arn : null
}

output "basic_auth_secret_name" {
  value = var.enable_basic_auth ? aws_secretsmanager_secret.basic_auth.0.name : null
}
