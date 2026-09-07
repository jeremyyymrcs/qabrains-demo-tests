#!/bin/bash

set -e

echo "Preparing Slack notification..."

AI_CATEGORY="${AI_CATEGORY:-No AI analysis}"
AI_SUMMARY="${AI_SUMMARY:-No AI analysis available.}"

RUN_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${RUN_ID}"

# Safely JSON encode values
json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

AI_CATEGORY_JSON=$(printf '%s' "$AI_CATEGORY" | json_escape)
AI_SUMMARY_JSON=$(printf '%s' "$AI_SUMMARY" | json_escape)

COMMIT_MESSAGE_JSON=$(printf '%s' "${COMMIT_MESSAGE:-}" | json_escape)

PAYLOAD=$(cat <<EOF
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "Playwright Test Result"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Status:*\n${RESULT_STATUS}"
        },
        {
          "type": "mrkdwn",
          "text": "*Total:*\n${TOTAL}"
        },
        {
          "type": "mrkdwn",
          "text": "*Passed:*\n${PASSED}"
        },
        {
          "type": "mrkdwn",
          "text": "*Failed:*\n${FAILED}"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*AI Failure Category:*\n${AI_CATEGORY_JSON}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*AI Analysis:*\n${AI_SUMMARY_JSON}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Branch:* ${BRANCH}\n*Actor:* ${ACTOR}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Commit:*\n${COMMIT_MESSAGE_JSON}"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View GitHub Actions"
          },
          "url": "${RUN_URL}"
        }
      ]
    }
  ]
}
EOF
)

echo "Sending Slack notification..."

curl -sS \
  -X POST \
  -H "Content-Type: application/json" \
  --data "$PAYLOAD" \
  "$SLACK_WEBHOOK_URL"

echo ""
echo "Slack notification sent."