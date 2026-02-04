# Security Module

Creates IAM role for CloudWatch Logs (IRSA).

## Resources

- IAM role for service account (CloudWatch Logs permissions)
- IRSA setup (OIDC provider)

## Usage

Annotate service account with role ARN:
```yaml
annotations:
  eks.amazonaws.com/role-arn: <role-arn>
```

## Outputs

- `cloudwatch_logs_role_arn`
