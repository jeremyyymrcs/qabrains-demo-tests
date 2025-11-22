#!/bin/bash
set -e

# URL to the current GitHub Actions run
run_url="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

# Prepare Slack JSON payload
json_payload=$(cat <<EOF
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Test Summary:*"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Status:* ${RESULT_STATUS}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "✅ *Passed:* ${PASSED}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "❌ *Failed:* ${FAILED}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "🧪 *Total Tests:* ${TOTAL}"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Details:*"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "📂 *Branch:* ${BRANCH}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "🔢 *Commit Hash:* \`${COMMIT_HASH}\`"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "💬 *Commit Message:* ${COMMIT_MESSAGE}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "👤 *Actor:* ${ACTOR}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "🕒 *Date/Time:* ${DATE_TIME}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "📄 <${run_url}|View Allure Report>"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "\n\n"
      }
    }
  ]
}
EOF
)

# Send payload to Slack
curl -X POST "$SLACK_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d "$json_payload"
