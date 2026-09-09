#!/usr/bin/env bash
set -euo pipefail

# Configuration
MODEL="${OLLAMA_MODEL:-qwen2.5:3b}"
export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
REPORT_DIR="reports"
ANALYSIS_FILE="${REPORT_DIR}/ai-failure-analysis.md"
OLLAMA_LOG="${REPORT_DIR}/ollama.log"
PROMPT_FILE="${REPORT_DIR}/ai-failure-analysis.prompt"

OLLAMA_READY_TIMEOUT=60
MAX_LOG_BYTES=16000

mkdir -p "${REPORT_DIR}"

log() { echo "[AI Analysis] $*"; }

wait_for_ollama() {
    for ((i=0; i<OLLAMA_READY_TIMEOUT; i+=2)); do
        curl -fsS "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1 && return 0
        sleep 2
    done
    return 1
}

setup_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        log "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi

    if ! curl -fsS "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
        log "Starting Ollama server..."
        ollama serve >"${OLLAMA_LOG}" 2>&1 &
        OLLAMA_PID=$!
        trap 'kill "${OLLAMA_PID}" 2>/dev/null || true' EXIT
        wait_for_ollama || { log "Ollama failed to start"; exit 1; }
    fi

    log "Pulling model ${MODEL}..."
    ollama pull "${MODEL}"
}

build_prompt() {
    log "Building analysis prompt..."

    {
        cat <<'EOF'
# ROLE

You are a Senior QA Automation and CI/CD Troubleshooting Engineer specializing in:

- Playwright
- Python
- Docker
- GitHub Actions
- Web application testing
- CI/CD failure diagnosis

# OBJECTIVE

Analyze the provided CI/test evidence and identify the most likely root cause.

Your goal is to determine:

1. What failed
2. Why it most likely failed
3. The strongest evidence
4. The smallest practical fix
5. Your confidence level

# IMPORTANT RULES

- Use ONLY the evidence provided below.
- Do NOT invent missing information.
- Do NOT assume an application bug without evidence.
- If the evidence is insufficient, say so clearly.
- Prioritize actual errors, stack traces, assertions, failing locators, test names, and failed commands.
- If multiple failures exist, identify the PRIMARY failure first.
- Treat warnings as secondary unless evidence shows they caused the failure.
- Do NOT recommend increasing timeouts unless the evidence supports a timing issue.
- Do NOT provide generic Playwright troubleshooting advice.
- Recommend the smallest appropriate fix.
- Never expose, repeat, reconstruct, or infer passwords, tokens, API keys, cookies, or other secrets.

# FAILURE CLASSIFICATION

Choose ONE:

- Test defect
- Application defect
- Environment/configuration problem
- Timing/synchronization problem
- Network/external dependency problem
- CI/CD or Docker problem
- Unknown / insufficient evidence

# ANALYSIS PROCESS

Determine internally:

- What failed?
- What is the exact error?
- Which test, locator, file, function, command, or CI step is affected?
- What does the evidence directly prove?
- What is the most likely root cause?
- Is there a secondary or cascading failure?
- What is the smallest practical fix?

Do NOT output your internal reasoning.
Only provide the final diagnosis.

# OUTPUT RULES

- Be VERY concise.
- Focus only on the most important information.
- Do NOT write a long explanation.
- Do NOT repeat the full logs.
- Include only the strongest 1–3 pieces of evidence.
- Keep the entire response under 250 words whenever possible.
- Use short paragraphs and bullet points.
- If the root cause is obvious, state it directly.

# OUTPUT FORMAT

Return ONLY these sections:

## Failure classification
One category and the affected test/step.

## Probable root cause
1–3 sentences maximum.

## Evidence
1–3 short bullet points containing only the strongest evidence.

## Recommended fix
1–3 concise actionable steps.

## Secondary findings
Mention only important secondary issues.
If none exist, write: None.

## Confidence
Use exactly one: High, Medium, or Low.
Add one short reason.

# EVIDENCE

The following sections contain the available evidence.

EOF

        echo "=== DOCKER BUILD OUTPUT ==="

        if [[ -f "${REPORT_DIR}/docker_build.log" ]]; then
            tail -c "${MAX_LOG_BYTES}" "${REPORT_DIR}/docker_build.log"
        else
            echo "No Docker build output was produced."
        fi

        echo
        echo "=== TEST SUMMARY ==="

        if [[ -f "${REPORT_DIR}/test_summary.txt" ]]; then
            cat "${REPORT_DIR}/test_summary.txt"
        else
            echo "No test summary was produced."
        fi

        echo
        echo "=== TEST OUTPUT ==="

        if [[ -f "${REPORT_DIR}/test_output.log" ]]; then
            tail -c "${MAX_LOG_BYTES}" "${REPORT_DIR}/test_output.log" |
                sed -E \
                    -e 's/((PASSWORD|TOKEN|SECRET|API_KEY|WEBHOOK_URL)[[:space:]]*[=:])[[:space:]]*[^[:space:]]+/\1 [REDACTED]/Ig' \
                    -e 's/(Authorization:[[:space:]]*Bearer)[[:space:]]+[^[:space:]]+/\1 [REDACTED]/Ig'
        else
            echo "No captured test output was produced."
        fi

        echo
        echo "=== END OF EVIDENCE ==="

    } > "${PROMPT_FILE}"
}

run_analysis() {
    log "Analyzing with ${MODEL}..."
    echo -e "_Model: \`${MODEL}\` (local Ollama runner)_\n" > "${ANALYSIS_FILE}"

    if ! ollama run "${MODEL}" < "${PROMPT_FILE}" > "${REPORT_DIR}/raw.txt" 2>> "${OLLAMA_LOG}"; then
        echo "## AI Analysis Failed" >> "${ANALYSIS_FILE}"
        return 1
    fi

    # Remove ANSI escape codes and clean output
    sed -r 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g' "${REPORT_DIR}/raw.txt" >> "${ANALYSIS_FILE}"
}

main() {
    setup_ollama
    build_prompt
    run_analysis || true

    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        cat "${ANALYSIS_FILE}" >> "${GITHUB_STEP_SUMMARY}"
    fi
    log "Results written to ${ANALYSIS_FILE}"
}

main