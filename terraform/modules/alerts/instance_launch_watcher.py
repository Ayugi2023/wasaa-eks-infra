#!/usr/bin/env python3
import os
import json
import time
import boto3
from datetime import datetime, timedelta

DDB_TABLE = os.environ.get('DDB_TABLE')
CLUSTER_TAG_KEY = os.environ.get('CLUSTER_TAG_KEY', 'kubernetes.io/cluster/')
CLUSTER_NAME = os.environ.get('CLUSTER_NAME')
THRESHOLD = int(os.environ.get('THRESHOLD', '3'))
WINDOW_MIN = int(os.environ.get('WINDOW_MIN', '5'))
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

ddb = boto3.resource('dynamodb')
ec2 = boto3.client('ec2')
sns = boto3.client('sns')


def iso_now():
    return datetime.utcnow().isoformat()


def handler(event, context):
    # EventBridge EC2 instance state-change events
    # We'll inspect the instance's tags and only proceed if the cluster tag matches
    try:
        detail = event.get('detail', {})
        instance_id = detail.get('instance-id') or detail.get('instanceId')
        state = detail.get('state') or detail.get('state')
        if not instance_id or state != 'running':
            return {'status': 'ignored', 'reason': 'no-instance-or-not-running'}

        # Describe instance to get tags
        resp = ec2.describe_instances(InstanceIds=[instance_id])
        reservations = resp.get('Reservations', [])
        if not reservations:
            return {'status': 'no-reservation'}

        inst = reservations[0]['Instances'][0]
        tags = {t['Key']: t['Value'] for t in inst.get('Tags', [])}

        # cluster tag convention: kubernetes.io/cluster/<name> = owned
        cluster_tag_key = f"kubernetes.io/cluster/{CLUSTER_NAME}"
        if tags.get(cluster_tag_key) != 'owned':
            return {'status': 'not-cluster-instance', 'instance': instance_id}

        # record event into DynamoDB
        table = ddb.Table(DDB_TABLE)
        now_ts = int(time.time())
        item = {
            'cluster': CLUSTER_NAME,
            'ts': now_ts,
            'instance_id': instance_id
        }
        table.put_item(Item=item)

        # count items in window
        window_start = now_ts - (WINDOW_MIN * 60)
        # Query by cluster requires a GSI or primary key design; we'll do a scan with filter (small scale)
        resp = table.scan(
            FilterExpression="#c = :c AND #ts >= :start",
            ExpressionAttributeNames={'#c': 'cluster', '#ts': 'ts'},
            ExpressionAttributeValues={':c': CLUSTER_NAME, ':start': window_start}
        )
        items = resp.get('Items', [])
        if len(items) > THRESHOLD:
            # publish an alert
            msg = {
                'alert': 'autoscaler_burst',
                'cluster': CLUSTER_NAME,
                'window_minutes': WINDOW_MIN,
                'threshold': THRESHOLD,
                'count': len(items),
                'instances': [i.get('instance_id') for i in items]
            }
            sns.publish(TopicArn=SNS_TOPIC_ARN, Message=json.dumps(msg), Subject='Autoscaler burst detected')

        return {'status': 'recorded', 'count': len(items)}

    except Exception as e:
        return {'status': 'error', 'error': str(e)}
