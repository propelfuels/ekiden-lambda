# ekiden-lambda

AWS EventBridge to Slack webhook integration; written in Ruby for as a Lambda function.

## Setup

1. Create a *Lambda function*
1. Create an *event bus*
1. Attach a *rule* to send events to the function
   - Event pattern: `{"source":["prpl.ekiden.it"]}`

### Lambda Environment Variables

- `NEKO_LOG_LEVEL`
- `EKIDEN_SSMPS_CHANNELS_PATH`: where the Slack inbound webhook URLs are stored
- `EKIDEN_DETAILTYPE_PREFIX`: e.g., `slack-alert:`

### System Manager Parameter Store

Use Slack channel name as the parameter name and store the inbound webhook URL.

## Usage

### Sending an Event

```json
{
  "detail-type": "slack-alert:<CHANNEL_NAME>", 
  "source": "prpl.ekiden.it", 
  "detail": "<JSON_SLACK_MESSAGE>"
}
```
