# stonks 
A stock portfolio advisor. Missing stock buying opportunities is easy when you're really busy. This system will allow you to track a set of stocks that you care about, and highlight opportunities to improve your positions.

> NOTE: 
The pipeline is designed to practice using target technologies. It will prepare me for the AWS Data Analytics certification, and advance my quest -- to become a full-stack data scientist.

## Data Sources
* Stock price data
* Twitter sentiment (future)
* Google trends (future)

## Features
* Provides daily advice each morning on stocks to buy or sell.
* Sends realtime alert when prices jump quickly
* Predicts the fair value for a stock based on:
    * Expert opinions
    * Financial performance 
* Forecasts the future market price for a stock.
    * Momentum
    * Company sentiment or events
    * Past history
* Shows metrics such as rolling averages, PE ratio, ect...

## Repos
* [stonks](https://github.com/mronemous/stonks) - architecture and terraform scripts
* [stonks-sample-app](https://github.com/mronemous/stonks-sample-app) - public facing web site to practice ingress into Fargate
* [stonks-trade-ingest-app](https://github.com/mronemous/stonks-trade-ingest-app) - websocket adapter into Kinesis data stream

## High Level Architecture
![High Level](docs//stonks-high-level-architecture.png?raw=true "High Level Architecture")

### Components

EKS Cluster - consisting of Fargate pods which:
* transform stock trade websocket into stream
* validate, and transform into data for app and ML
* micro-services for the app
* ingress controller which allows public facing inet pods 
* IAM policies control what AWS services pods can use

Glue 
* crawl S3 for data catalog

Kinesis Data Streams
* realtime to multiple consumers

Kinesis Firehose
* store as Parquet in S3

Kinesis Analytics
* anomaly detection for price and volume

S3
* raw data lake
* logs for debugging 

DynamoDB
* recent hot data, and user config for app

SageMaker
* modeling, training, predictions

Athena 
* big data query support 

AWS Secret Manager 
* manages secrets and terraform ingests into Kub cluster.

ECR / Jenkins / Github
* Docker image storage and CI

### Code
* Python backend
* Kotlin cross-platform frontend: web, android, ios
* AWS Terraform for infrastructure as code
