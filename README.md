# stonks 
A stock portfolio advisor. Missing stock buying opportunities is easy when you're really busy. This system will allow you to track a set of stocks that you care about, and highlight opportunities to improve your positions.

NOTE: Very much a work and progress and mostly to practice using the target technologies.

## Data Sources
* Stock price data
* Twitter sentiment
* Google trends

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

## Draft Architecture
![High Level](/stonks-high-level-architecture.png?raw=true "High Level Architecture")

## Target Technologies
* Terraform for infrastructure setup (AWS)
    * Glue 
        * API poll/produce events **This may need to be EMR or EC2 (to produce events quickly)
        * Crawl S3 for data catalog
    * Kinesis Data Streams
        * realtime to multiple consumers
    * Kinesis Firehose
        * store as Parquet in S3
    * S3
        * raw data lake
    * DynamoDB
        * recent hot data, and user config for app
    * SageMaker
        * modeling, training, predictions
    * Athena 
        * big data query support 
* Python backend
* Kotlin cross-platform frontend: web, android, ios
