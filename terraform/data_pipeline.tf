#Kinesis Data Streams
resource "aws_kinesis_stream" "trades" {
  name             = "${var.name}-${local.environment}-trades"
  shard_count      = 1
  retention_period = 24

  tags = merge(var.default_tags, {
    Name        = "${var.name}-${local.environment}-trades"
  })
}

#S3
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.unique_slug}-${var.name}-${local.environment}"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = merge(var.default_tags, {
    Name        = "${var.name}-${local.environment}-s3"
  })
}

#Kinesis Firehose Delivery
resource "aws_kinesis_firehose_delivery_stream" "trades" {
  name        = "${var.name}-${local.environment}-trades"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.trades.arn
    role_arn = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.data_lake.arn

    buffer_size = 128
    buffer_interval = 300
    prefix = "trades/!{timestamp:yyyy/MM/dd}/"
    error_output_prefix = "trades-error/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_table.trades.database_name
        role_arn      = aws_iam_role.firehose.arn
        table_name    = aws_glue_catalog_table.trades.name
      }
    }
  }
}