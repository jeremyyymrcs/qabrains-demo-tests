#!/bin/bash

# -------------------------
# Headless Mode Detection
# -------------------------

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source pytest summary functions
source "$SCRIPT_DIR/pytest_summary.sh"

_check_headless_mode() {
    export HEADLESS=True
    if [[ "$*" == *"-headed"* ]]; then
        export HEADLESS=False
    fi
    echo "Headless mode: $HEADLESS"
}

# -------------------------
# Number of Workers Detection
# ----------------------------
_check_number_of_workers() {
    local args="$*"
    export NUM_PROCESSES=""

    if [[ "$args" == *"-async"* ]]; then
        export NUM_PROCESSES="-n auto"
    else
      echo "No '-async' argument found. Defaulting to a synchronous mode."
    fi
}

# -------------------------
# Positive and Negative Testing Detection
# ----------------------------
_check_running_mode() {
    local args="$*"
    export MODE=""
    if [[ "$args" == *"-positive"* ]]; then
        export MODE="-m positive"
    elif [[ "$args" == *"-negative"* ]]; then
        export MODE="-m negative"
    else
      echo "No '-positive' or '-negative' argument found. Defaulting to standard mode."
    fi
}

# -------------------------
# Execute the test.py file with the following parameter
# -------------------------
_execution() {
    running_message="  Mode: ${MODE:-default}\n  Number of processes: ${NUM_PROCESSES:-default}"
    echo -e "$suite_name: Running tests with the following settings:\n$running_message"

    mkdir -p ../reports
    pytest "$test_file" $NUM_PROCESSES $MODE | tee ../reports/pytest_output.txt | grep -v "bringing up nodes"

    # Generate summary
    generate_test_summary "../reports/pytest_output.txt" "../reports/test_summary.txt"

    echo "$suite_name has been successfully run."
}
# -------------------------
# Allure Report Generator
# -------------------------
_generate_allure_report() {
    echo "Generating Allure report..."
    allure generate ../reports/allure-results --clean --single-file -o ../reports/allure-report
}

# -------------------------
# Main Reusable Test Runner
# -------------------------
run_tests() {
    printf '\e[8;60;200t'
    local suite_name="$SUITE_NAME"
    local test_file="$TEST_FILE"


    _check_headless_mode "${args[@]}"
    _check_number_of_workers "${args[@]}"
    _check_running_mode "${args[@]}"

    cd ..
    _execution "${args[@]}"
    _generate_allure_report

    # Wait for a key press or timeout after 60 seconds
    if ! read -t 60 -n 1 -s -p "Press any key to exit..."; then
        echo "Timeout reached. Exiting..."
    fi
}

