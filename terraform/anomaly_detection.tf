resource "aws_sns_topic" "trade_anomaly" {
  name = "${var.name}-${local.environment}-trades-anomaly"
}

resource "aws_kinesis_analytics_application" "trade_anomaly" {
  name = "${var.name}-${local.environment}-trades-anomaly"

  code = <<EOF
-- ** Anomaly detection **
-- Detects sustained (averaged over an hour) trade anomalies.
CREATE OR REPLACE STREAM "temp_stream" (
   "symbol" VARCHAR(10),
   "price"  DOUBLE,
   "volume" DOUBLE,
   "ANOMALY_SCORE" DOUBLE);
CREATE OR REPLACE STREAM "output_stream" (
   "symbol" VARCHAR(10),
   "price" DOUBLE,
   "volume" DOUBLE,
   "anomaly_score" DOUBLE);

-- Compute an anomaly score for each record in the source stream
CREATE OR REPLACE PUMP "STREAM_PUMP" AS INSERT INTO "temp_stream"
SELECT STREAM "symbol", "price", "volume", "ANOMALY_SCORE" FROM
  TABLE(RANDOM_CUT_FOREST(
    CURSOR(
        SELECT STREAM "symbol", AVG("price") OVER w1 AS "price", AVG("volume") OVER w1 AS "volume"
        FROM "trades_stream_001"
        WINDOW w1 AS (PARTITION BY "symbol" RANGE INTERVAL '1' HOUR PRECEDING)
    )
  )
);
-- Sort records by descending anomaly score, insert into output stream
CREATE OR REPLACE PUMP "OUTPUT_PUMP" AS INSERT INTO "output_stream"
SELECT STREAM * FROM "temp_stream"
WHERE "ANOMALY_SCORE" > 3.0
ORDER BY FLOOR("temp_stream".ROWTIME TO SECOND), "ANOMALY_SCORE" DESC;
EOF

  inputs {
    name_prefix = "trades_stream"

    kinesis_stream {
      resource_arn = aws_kinesis_stream.trades.arn
      role_arn     = aws_iam_role.data_analytic.arn
    }

    parallelism {
      count = 1
    }

    schema {
      record_columns {
        mapping  = "$.traded_at"
        name     = "traded_at"
        sql_type = "TIMESTAMP"
      }

      record_columns {
        mapping  = "$.symbol"
        name     = "symbol"
        sql_type = "VARCHAR(10)"
      }

      record_columns {
        mapping  = "$.price"
        name     = "price"
        sql_type = "DOUBLE"
      }

      record_columns {
        mapping  = "$.volume"
        name     = "volume"
        sql_type = "DOUBLE"
      }

      record_encoding = "UTF-8"

      record_format {
        mapping_parameters {
          json {
            record_row_path = "$"
          }
        }
      }
    }
  }

  outputs {
    name = "output_stream"
    schema {
        record_format_type = "JSON"
    }
    lambda {
      resource_arn = aws_lambda_function.trade_anomaly.arn
      role_arn     = aws_iam_role.data_analytic.arn
    }
  }
}

resource "aws_lambda_function" "trade_anomaly" {
    filename = data.archive_file.lambda.output_path
    function_name = "${var.name}-${local.environment}-trades-anomaly"
    handler       = "trade_anomaly.notify"
    runtime = "python3.8"
    source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
    role          = aws_iam_role.trade_anomaly_lambda.arn
}