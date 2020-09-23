resource "aws_glue_catalog_database" "main" {
  name = "${var.name}-${local.environment}"
}

resource "aws_glue_crawler" "trades" {
  database_name = aws_glue_catalog_database.main.name
  name          = "${var.name}-${local.environment}-trades"
  role          = aws_iam_role.glue.arn

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.bucket}/trades"
  }
}

#Uncrawlable Schemas
resource "aws_glue_catalog_table" "trades" {
  name          = "trades-stream"
  database_name = aws_glue_catalog_database.main.name
  storage_descriptor {
    location = "kinesis:${aws_kinesis_stream.trades.name}"

    columns {
      name    = "traded_at"
      type    = "timestamp"
    }

    columns {
      name = "symbol"
      type = "string"
    }

    columns {
      name = "price"
      type = "double"
    }

    columns {
      name    = "volume"
      type    = "double"
    }
  }
}
