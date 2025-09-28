output "firehose_delivery_stream_name" {
  description = "Name of the Kinesis Firehose delivery stream"
  value       = var.cribl_endpoint_url == "" ? aws_kinesis_firehose_delivery_stream.main[0].name : aws_kinesis_firehose_delivery_stream.cribl[0].name
}

output "firehose_delivery_stream_arn" {
  description = "ARN of the Kinesis Firehose delivery stream"
  value       = var.cribl_endpoint_url == "" ? aws_kinesis_firehose_delivery_stream.main[0].arn : aws_kinesis_firehose_delivery_stream.cribl[0].arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Firehose data"
  value       = aws_s3_bucket.firehose_bucket.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Firehose data"
  value       = aws_s3_bucket.firehose_bucket.arn
}

output "firehose_role_arn" {
  description = "ARN of the Firehose delivery IAM role"
  value       = aws_iam_role.firehose_delivery_role.arn
}

output "firehose_role_name" {
  description = "Name of the Firehose delivery IAM role"
  value       = aws_iam_role.firehose_delivery_role.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Firehose"
  value       = var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.firehose_log_group[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for Firehose"
  value       = var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.firehose_log_group[0].arn : null
}

output "resource_naming_pattern" {
  description = "The naming pattern used for all resources"
  value       = "${var.project_name}-${var.log_name}-${var.destination_name}-${var.environment}"
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = {
    ProjectName     = var.project_name
    LogName         = var.log_name
    DestinationName = var.destination_name
    Environment     = var.environment
    ManagedBy       = "terraform"
  }
}
