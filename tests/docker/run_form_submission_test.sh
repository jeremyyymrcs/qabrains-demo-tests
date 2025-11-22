#!/bin/bash

# Suite name and test file
export SUITE_NAME="Form Submission Test Suite"
export TEST_FILE="test_form_submission.py"

# Get arguments passed to the script
args="$*"

# Source the common functions for headless mode and argument parsing
source ./test_runner_utility.sh

# Run tests with the provided suite name, test file, and arguments
run_tests "${args[@]}"
