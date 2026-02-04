# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/eks/${var.cluster_name}/chaotic-backend"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-app-logs"
  }
}

