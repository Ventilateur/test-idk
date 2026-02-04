output "cloudwatch_logs_role_arn" {
  description = "ARN of the CloudWatch Logs IAM role"
  value       = aws_iam_role.cloudwatch_logs.arn
}

