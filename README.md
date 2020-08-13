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
    * Kinesis Data Streams (realtime)
    * Kinesis Firehose (store as Parquet in S3)
    * S3 (raw data lake)
    * DynamoDB (recent hot data)
    * SageMaker (modeling, training, predictions)
* Python backend
* Kotlin Native frontend: web, android, ios
