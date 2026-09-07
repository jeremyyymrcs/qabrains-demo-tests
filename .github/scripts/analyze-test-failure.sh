#!/usr/bin/env bash
set -euo pipefail

MODEL="${OLLAMA_MODEL:-qwen2.5:3b}"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
OLLAMA_LOG="reports/ollama.log"
ANALYSIS_FILE="reports/ai-failure-analysis.md"
PROMPT_FILE="reports/ai-failure-analysis.prompt"

mkdir -p reports

if ! command -v ollama >/dev/null 2>&1; then
  curl --fail --silent --show-error https://ollama.com/install.sh | sh
fi

if ! curl --fail --silent "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
  OLLAMA_HOST="${OLLAMA_HOST}" ollama serve >"${OLLAMA_LOG}" 2>&1 &
  OLLAMA_PID=$!
  trap 'kill "${OLLAMA_PID}" 2>/dev/null || true' EXIT

  for _ in {1..30}; do
    if curl --fail --silent "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
fi

curl --fail --silent "http://${OLLAMA_HOST}/api/tags" >/dev/null
ollama pull "${MODEL}"

{
  cat <<'EOF'
You are a senior Playwright and CI troubleshooting engineer.
Analyze the failed GitHub Actions test run below. Do not invent facts.

Respond in Markdown with exactly these sections:
## Probable root cause
## Evidence
## Recommended fix
## Confidence

Keep the analysis practical and concise. Distinguish test defects, application defects,
environment problems, and flaky timing/network problems. Include the failing test or
locator when the log provides it.

Test summary:
EOF
  if [[ -f reports/test_summary.txt ]]; then
    cat reports/test_summary.txt
  else
    printf '%s\n' "No test summary was produced."
  fi
  cat <<'EOF'

Relevant test output (credentials and common secret values have been redacted):
EOF
  if [[ -f reports/test_output.log ]]; then
    tail -c 16000 reports/test_output.log |
      sed -E 's/(PASSWORD|TOKEN|SECRET|WEBHOOK_URL)=([^[:space:]]+)/\1=[REDACTED]/Ig'
  else
    printf '%s\n' "No captured test output was produced."
  fi
} > "${PROMPT_FILE}"

{
  echo "# AI failure analysis"
  echo
  echo "_Model: \`${MODEL}\` (local Ollama runner; generated only after a test failure)._"
  echo
  OLLAMA_HOST="${OLLAMA_HOST}" ollama run "${MODEL}" < "${PROMPT_FILE}"
} > "${ANALYSIS_FILE}"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  cat "${ANALYSIS_FILE}" >> "${GITHUB_STEP_SUMMARY}"
fi

echo "AI failure analysis written to ${ANALYSIS_FILE}"
