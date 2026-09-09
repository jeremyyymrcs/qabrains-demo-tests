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
        echo "You are a senior Playwright and CI troubleshooting engineer. Analyze the failure logs below."
        echo "Rules: Base conclusions on evidence, distinguish between test/app/env/flaky defects, and redact secrets."
        echo "Respond in Markdown with: ## Probable root cause, ## Evidence, ## Recommended fix, ## Confidence"
        echo -e "\n--- Docker Build Output ---"
        [[ -f "${REPORT_DIR}/docker_build.log" ]] && tail -c "${MAX_LOG_BYTES}" "${REPORT_DIR}/docker_build.log" || echo "N/A"
        echo -e "\n--- Test Summary ---"
        [[ -f "${REPORT_DIR}/test_summary.txt" ]] && cat "${REPORT_DIR}/test_summary.txt" || echo "N/A"
        echo -e "\n--- Test Output ---"
        if [[ -f "${REPORT_DIR}/test_output.log" ]]; then
            tail -c "${MAX_LOG_BYTES}" "${REPORT_DIR}/test_output.log" | 
            sed -E 's/(PASSWORD|TOKEN|SECRET|API_KEY)[[:space:]]*[=:][[:space:]]*[^[:space:]]+/\1 [REDACTED]/Ig'
        else
            echo "N/A"
        fi
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