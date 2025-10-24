#!/usr/bin/env python3
import os
import json
import urllib.request

try:
    import boto3
except Exception:
    boto3 = None


CLUSTER = os.environ.get("CLUSTER_NAME", "unknown")
ALERT_LEVEL = os.environ.get("ALERT_LEVEL", "ALERT")
SLACK_WEBHOOK = os.environ.get("SLACK_WEBHOOK_URL")
SLACK_SECRET_ARN = os.environ.get("SLACK_SECRET_ARN")


def _get_webhook_from_secrets():
    if not SLACK_SECRET_ARN or not boto3:
        return None
    try:
        client = boto3.client('secretsmanager')
        resp = client.get_secret_value(SecretId=SLACK_SECRET_ARN)
        secret = resp.get('SecretString')
        if not secret:
            return None
        # Expecting either raw webhook URL or JSON with {"webhook": "https://..."}
        try:
            parsed = json.loads(secret)
            if isinstance(parsed, dict):
                return parsed.get('webhook') or parsed.get('slack_webhook')
        except Exception:
            # not json, treat as raw
            return secret
    except Exception:
        return None


def handler(event, context):
    # collect messages
    messages = []
    if isinstance(event, dict) and 'Records' in event:
        for r in event['Records']:
            try:
                body = r.get('Sns', {}).get('Message', '')
                messages.append(body)
            except Exception:
                continue
    else:
        messages.append(json.dumps(event))

    text = f"[{ALERT_LEVEL}] {CLUSTER} - {len(messages)} alert(s)\n"
    for m in messages[:10]:
        text += "- " + (m if isinstance(m, str) else json.dumps(m)) + "\n"

    webhook = SLACK_WEBHOOK or _get_webhook_from_secrets()

    if webhook:
        payload = json.dumps({"text": text}).encode("utf-8")
        req = urllib.request.Request(webhook, data=payload, headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                return {"statusCode": resp.getcode(), "body": resp.read().decode('utf-8')}
        except Exception as e:
            # log to CloudWatch via return
            return {"statusCode": 500, "body": str(e)}

    # fallback: return payload so logs include the alert (and SNS will show it in console)
    return {"statusCode": 200, "body": text}
