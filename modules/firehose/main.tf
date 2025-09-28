locals {
  name_prefix = "${var.project_name}-${var.log_name}-${var.destination_name}-${var.environment}"
  
  common_tags = merge(
    {
      ProjectName     = var.project_name
      LogName         = var.log_name
      DestinationName = var.destination_name
      Environment     = var.environment
      ManagedBy       = "terraform"
    },
    var.tags
  )
}

# S3 Bucket
resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "${local.name_prefix}-firehose-data"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "firehose_bucket_versioning" {
  bucket = aws_s3_bucket.firehose_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firehose_bucket_encryption" {
  bucket = aws_s3_bucket.firehose_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "firehose_bucket_pab" {
  bucket = aws_s3_bucket.firehose_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  count             = var.enable_cloudwatch_logging ? 1 : 0
  name              = "/aws/kinesisfirehose/${local.name_prefix}"
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  count          = var.enable_cloudwatch_logging ? 1 : 0
  name           = "${local.name_prefix}-delivery-stream"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group[0].name
}

# IAM Role
resource "aws_iam_role" "firehose_delivery_role" {
  name = "${local.name_prefix}-firehose-delivery-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
  tags = local.common_tags
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "firehose_delivery_policy" {
  name = "${local.name_prefix}-s3-access-policy"
  role = aws_iam_role.firehose_delivery_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.firehose_bucket.arn,
          "${aws_s3_bucket.firehose_bucket.arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for CloudWatch Logs access
resource "aws_iam_role_policy" "firehose_cloudwatch_policy" {
  count = var.enable_cloudwatch_logging ? 1 : 0
  name  = "${local.name_prefix}-cloudwatch-logs-policy"
  role  = aws_iam_role.firehose_delivery_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = aws_cloudwatch_log_group.firehose_log_group[0].arn
      }
    ]
  })
}

# S3 Delivery Stream
resource "aws_kinesis_firehose_delivery_stream" "main" {
  count       = var.cribl_endpoint_url == "" ? 1 : 0
  name        = "${local.name_prefix}-delivery-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_delivery_role.arn
    bucket_arn = aws_s3_bucket.firehose_bucket.arn
    prefix     = "${var.project_name}/${var.log_name}/${var.environment}/${var.s3_prefix}"
    error_output_prefix = "${var.project_name}/${var.log_name}/${var.environment}/${var.error_output_prefix}"
    
    buffering_size     = var.buffer_size
    buffering_interval = var.buffer_interval
    compression_format = var.compression_format

    dynamic "cloudwatch_logging_options" {
      for_each = var.enable_cloudwatch_logging ? [1] : []
      content {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.firehose_log_group[0].name
        log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream[0].name
      }
    }
  }

  tags = local.common_tags
}

# HTTP Endpoint (Cribl) Delivery Stream
resource "aws_kinesis_firehose_delivery_stream" "cribl" {
  count       = var.cribl_endpoint_url != "" ? 1 : 0
  name        = "${local.name_prefix}-cribl-delivery-stream"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url        = var.cribl_endpoint_url
    name       = "${local.name_prefix}-cribl-endpoint"
    access_key = var.cribl_client_id

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_backup_mode = "FailedDataOnly"

    dynamic "cloudwatch_logging_options" {
      for_each = var.enable_cloudwatch_logging ? [1] : []
      content {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.firehose_log_group[0].name
        log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream[0].name
      }
    }

    s3_configuration {
      role_arn   = aws_iam_role.firehose_delivery_role.arn
      bucket_arn = aws_s3_bucket.firehose_bucket.arn
      prefix     = "${var.project_name}/${var.log_name}/${var.environment}/backup/${var.s3_prefix}"
      error_output_prefix = "${var.project_name}/${var.log_name}/${var.environment}/backup/${var.error_output_prefix}"
      
      buffering_size     = var.buffer_size
      buffering_interval = var.buffer_interval
      compression_format = var.compression_format

      dynamic "cloudwatch_logging_options" {
        for_each = var.enable_cloudwatch_logging ? [1] : []
        content {
          enabled         = true
          log_group_name  = aws_cloudwatch_log_group.firehose_log_group[0].name
          log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream[0].name
        }
      }
    }
  }

  tags = local.common_tags
}
