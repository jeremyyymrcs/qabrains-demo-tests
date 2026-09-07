#!/usr/bin/env bash
set -euo pipefail

MODEL="${OLLAMA_MODEL:-qwen2.5:3b}"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
OLLAMA_LOG="reports/ollama.log"
ANALYSIS_FILE="reports/ai-failure-analysis.md"
PROMPT_FILE="reports/ai-failure-analysis.prompt"

mkdir -p reports
cat > "${ANALYSIS_FILE}" <<'EOF'
# AI failure analysis

Ollama analysis did not complete. See the `ollama.log`, Docker build log, and test
output in the `test-failure-analysis` artifact for details.
EOF

find_ollama() {
  local candidate

  for candidate in \
    "$(command -v ollama 2>/dev/null || true)" \
    /usr/local/bin/ollama \
    /usr/bin/ollama \
    "${HOME}/.ollama/bin/ollama" \
    "${HOME}/.local/bin/ollama" \
    "${RUNNER_TEMP:-/tmp}/ollama/bin/ollama"; do
    if [[ -n "${candidate}" && -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  find /usr/local /usr/bin "${HOME}/.ollama" "${HOME}/.local" "${RUNNER_TEMP:-/tmp}/ollama" \
    -type f -name ollama -perm -111 -print -quit 2>/dev/null || true
}

OLLAMA_BIN="$(find_ollama)"
if [[ -z "${OLLAMA_BIN}" ]]; then
  curl --fail --silent --show-error https://ollama.com/install.sh |
    sh 2>&1 | tee reports/ollama-install.log || true
  hash -r 2>/dev/null || true
  export PATH="/usr/local/bin:/usr/bin:${HOME}/.ollama/bin:${HOME}/.local/bin:${PATH}"
  OLLAMA_BIN="$(find_ollama)"
fi

if [[ -z "${OLLAMA_BIN}" ]]; then
  OLLAMA_INSTALL_DIR="${RUNNER_TEMP:-/tmp}/ollama"
  OLLAMA_ARCHIVE="${RUNNER_TEMP:-/tmp}/ollama-linux-amd64.tar.zst"
  mkdir -p "${OLLAMA_INSTALL_DIR}"

  download_ollama() {
    local url="$1"
    rm -f "${OLLAMA_ARCHIVE}"
    curl --fail --location --retry 4 --retry-delay 3 --silent --show-error \
      "${url}" --output "${OLLAMA_ARCHIVE}" &&
      [[ -s "${OLLAMA_ARCHIVE}" ]] &&
      tar --zstd -tf "${OLLAMA_ARCHIVE}" >/dev/null 2>&1
  }

  if ! download_ollama "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tar.zst"; then
    echo "Unable to download a valid Ollama Linux archive from either source." >&2
    exit 1
  fi

  if [[ ! -s "${OLLAMA_ARCHIVE}" ]] || ! tar --zstd -tf "${OLLAMA_ARCHIVE}" >/dev/null 2>&1; then
    echo "Unable to download a valid Ollama Linux archive." >&2
    exit 1
  fi

  tar --zstd -xf "${OLLAMA_ARCHIVE}" -C "${OLLAMA_INSTALL_DIR}"
  chmod +x "${OLLAMA_INSTALL_DIR}/bin/ollama" 2>/dev/null || true
  OLLAMA_BIN="$(find_ollama)"
fi

if [[ -z "${OLLAMA_BIN}" ]]; then
  echo "Ollama installation completed, but no executable was found in standard install locations." >&2
  echo "PATH=${PATH}" >&2
  exit 1
fi

if ! curl --fail --silent "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
  OLLAMA_HOST="${OLLAMA_HOST}" "${OLLAMA_BIN}" serve >"${OLLAMA_LOG}" 2>&1 &
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
"${OLLAMA_BIN}" pull "${MODEL}"

{
  cat <<'EOF'
You are a senior Playwright and CI troubleshooting engineer.
Analyze the failed GitHub Actions Docker build or Playwright test run below.
Do not invent facts.

Respond in Markdown with exactly these sections:
## Probable root cause
## Evidence
## Recommended fix
## Confidence

Keep the analysis practical and concise. Distinguish test defects, application defects,
environment problems, and flaky timing/network problems. Include the failing test or
locator when the log provides it.

Docker build output:
EOF
  if [[ -f reports/docker_build.log ]]; then
    tail -c 16000 reports/docker_build.log
  else
    printf '%s\n' "No Docker build output was produced."
  fi
  cat <<'EOF'

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
  OLLAMA_HOST="${OLLAMA_HOST}" "${OLLAMA_BIN}" run "${MODEL}" < "${PROMPT_FILE}"
} > "${ANALYSIS_FILE}"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  cat "${ANALYSIS_FILE}" >> "${GITHUB_STEP_SUMMARY}"
fi

echo "AI failure analysis written to ${ANALYSIS_FILE}"
