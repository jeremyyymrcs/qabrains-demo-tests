#!/bin/bash

# Function to parse pytest output and generate summary
generate_test_summary() {
    local pytest_output_file=$1
    local summary_file=$2

    echo "Parsing pytest output for summary..."

    summary_line=$(grep -Eo '[0-9]+ (passed|failed|skipped|xfailed|xpassed|error)' "$pytest_output_file" | tr '\n' ' ')

    # Initialize counters
    passed=0
    failed=0
    skipped=0
    errors=0

    # Loop through summary items and set values
    for item in $summary_line; do
        if [[ $item =~ ^[0-9]+$ ]]; then
            count=$item
        else
            case $item in
                passed) passed=$count ;;
                failed) failed=$count ;;
                skipped) skipped=$count ;;
                error) errors=$count ;;
            esac
        fi
    done

    # Calculate total tests
    total=$((passed + failed + skipped + errors))

    # Save summary to file
    echo "Total tests: $total" > "$summary_file"
    echo "Passed: $passed" >> "$summary_file"
    echo "Failed: $failed" >> "$summary_file"
    echo "Skipped: $skipped" >> "$summary_file"
    echo "Errors: $errors" >> "$summary_file"

    echo "Summary saved in $summary_file"
}
