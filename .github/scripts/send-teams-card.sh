#!/bin/bash
set -e

run_url="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

json_payload=$(cat <<EOF
{
  "attachments": [
    {
      "contentType": "application/vnd.microsoft.card.adaptive",
      "content": {
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.2",
        "body": [
          {"type": "TextBlock", "text": "**Test Summary:**", "weight": "Bolder"},
          {"type": "TextBlock", "text": "${RESULT_STATUS}", "weight": "Bolder", "size": "Medium"},
          {"type": "TextBlock", "text": "✅ Passed: ${PASSED}"},
          {"type": "TextBlock", "text": "❌ Failed: ${FAILED}"},
          {"type": "TextBlock", "text": "🧪 Total Tests: ${TOTAL}"},
          {"type": "TextBlock", "text": "**Details:**", "weight": "Bolder"},
          {"type": "TextBlock", "text": "📂 Branch: ${BRANCH}"},
          {"type": "TextBlock", "text": "🔢 Commit Hash: ${COMMIT_HASH}"},
          {"type": "TextBlock", "text": "🔢 Commit Message: ${COMMIT_MESSAGE}"},
          {"type": "TextBlock", "text": "👤 Actor: ${ACTOR}"},
          {"type": "TextBlock", "text": "🕒 Date/Time: ${DATE_TIME}"},
          {"type": "TextBlock", "text": "📄 [View Allure Report](${run_url})", "wrap": true}
        ]
      }
    }
  ]
}
EOF
)

curl -X POST "$LOGIC_APP_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d "$json_payload"
