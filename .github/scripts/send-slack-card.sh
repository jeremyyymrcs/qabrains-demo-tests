#!/bin/bash

set -e

run_url="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

AI_ANALYSIS="No AI analysis available."

if [ -f "reports/ai-analysis.txt" ]; then
  AI_ANALYSIS=$(cat reports/ai-analysis.txt)
fi

export RUN_URL="$run_url"
export AI_ANALYSIS

python3 <<'PY' > /tmp/slack_payload.json
import json
import os

payload = {
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*🤖 QA Brains Test Summary*"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Status:* {os.environ.get('RESULT_STATUS', '')}"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": (
                    f"✅ *Passed:* {os.environ.get('PASSED', '0')}\n"
                    f"❌ *Failed:* {os.environ.get('FAILED', '0')}\n"
                    f"🧪 *Total Tests:* {os.environ.get('TOTAL', '0')}"
                )
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*📋 Details*"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": (
                    f"📂 *Branch:* {os.environ.get('BRANCH', '')}\n"
                    f"🔢 *Commit:* `{os.environ.get('COMMIT_HASH', '')}`\n"
                    f"💬 *Commit Message:* {os.environ.get('COMMIT_MESSAGE', '')}\n"
                    f"👤 *Actor:* {os.environ.get('ACTOR', '')}\n"
                    f"🕒 *Date/Time:* {os.environ.get('DATE_TIME', '')}"
                )
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*🤖 AI Failure Analysis*"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": os.environ.get("AI_ANALYSIS", "")
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"📄 <{os.environ.get('RUN_URL', '')}|View GitHub Actions Run>"
            }
        }
    ]
}

print(json.dumps(payload))
PY

curl -X POST "$SLACK_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     --data-binary @/tmp/slack_payload.json