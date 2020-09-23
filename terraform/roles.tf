#Firehose Roles
resource "aws_iam_role" "firehose" {
  name = "${var.name}-${local.environment}-firehose"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "firehose" {
  name        = "${var.name}-${local.environment}-firehose"
  description = "Kinesis policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
        ],
        "Resource": [
            "${aws_s3_bucket.data_lake.arn}*"
        ]
    },
    {
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListShards"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_kinesis_stream.trades.arn}"
      ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "glue:GetTable",
            "glue:GetTableVersion",
            "glue:GetTableVersions"
        ],
        "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}

#Glue Roles
resource "aws_iam_role" "glue" {
  name = "${var.name}-${local.environment}-glue"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "glue" {
  name        = "${var.name}-${local.environment}-glue"
  description = "Glue policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:PutObject"
        ],
        "Resource": [
            "${aws_s3_bucket.data_lake.arn}*"
        ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "glue" {
  role       = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.glue.arn
}

resource "aws_iam_role_policy_attachment" "AWSGlueServiceRole" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

#Data Analytics Roles
resource "aws_iam_role" "data_analytic" {
  name = "${var.name}-${local.environment}-data-analytic"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "kinesisanalytics.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "data_analytic" {
  name        = "${var.name}-${local.environment}-data-analytic"
  description = "Kinesis policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListShards"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_kinesis_stream.trades.arn}"
      ]
    },
    {
        "Sid": "Invoke",
        "Effect": "Allow",
        "Action": [
          "lambda:InvokeFunction"
        ],
        "Resource": "${aws_lambda_function.trade_anomaly.arn}"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "data_analytic" {
  role       = aws_iam_role.data_analytic.name
  policy_arn = aws_iam_policy.data_analytic.arn
}

#Lambda
resource "aws_iam_role" "trade_anomaly_lambda" {
  name = "${var.name}-${local.environment}-trade-anomaly-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "trade_anomaly_lambda" {
  name        = "${var.name}-${local.environment}-trade-anomaly-lambda"
  description = "Kinesis policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
    },
    {
      "Action": [
        "sns:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sns_topic.trade_anomaly.arn}"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "trade_anomaly_lambda" {
  role       = aws_iam_role.trade_anomaly_lambda.name
  policy_arn = aws_iam_policy.trade_anomaly_lambda.arn
}