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
        "text": "*Status:* ${RESULT_STATUS}\n✅ Passed: ${PASSED}\n❌ Failed: ${FAILED}\n🧪 Total Tests: ${TOTAL}"
      }
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
      "fields": [
        {
          "type": "mrkdwn",
          "text": "📂 *Branch:*\n${BRANCH}"
        },
        {
          "type": "mrkdwn",
          "text": "🔢 *Commit Hash:*\n${COMMIT_HASH}"
        },
        {
          "type": "mrkdwn",
          "text": "💬 *Commit Message:*\n${COMMIT_MESSAGE}"
        },
        {
          "type": "mrkdwn",
          "text": "👤 *Actor:*\n${ACTOR}"
        },
        {
          "type": "mrkdwn",
          "text": "🕒 *Date/Time:*\n${DATE_TIME}"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "📄 <${run_url}|View Allure Report>"
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
