import boto3
import json
import base64

client = boto3.client('sns')
topic_arn = 'arn:aws:sns:us-east-1:714401593749:stonks-dev-trades-anomaly'
msg_attributes = {
    'AWS.SNS.SMS.SMSType': {
        'DataType': 'String',
        'StringValue': 'Transactional'
    }
}

def notify(event, context):
    output = []
    success = 0
    failure = 0

    records = event.get('records')
    if records is None:
        output.append({'result': 'Unable to find event.records.'})
        return {'records': output}

    for record in records:
        try:
            raw_data = record.get('data')
            if raw_data is None:
                continue
            data = json.loads(base64.b64decode(raw_data))

            symbol = data.get('symbol')
            price = data.get('price')
            volume = data.get('volume')
            score = data.get('anomaly_score')

            subject = 'Anomaly {0} {1:.2f}'.format(symbol, score)
            payload = 'price: {0:.2f} volume: {1:.2f}'.format(price, volume)
            client.publish(TopicArn=topic_arn, Message=payload, Subject=subject, MessageAttributes=msg_attributes)
            output.append({'recordId': record['recordId'], 'result': 'Ok'})
            success += 1
        except Exception as e:
            print(e)
            output.append({'recordId': record['recordId'], 'result': 'DeliveryFailed'})
            failure += 1

    print('Successfully delivered {0} records, failed to deliver {1} records'.format(success, failure))

    return {'records': output}
