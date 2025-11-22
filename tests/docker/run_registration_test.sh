#!/bin/bash

# Suite name and test file
export SUITE_NAME="Registration Test Suite"
export TEST_FILE="test_registration.py"

# Get arguments passed to the script
args="$*"

# Source the common functions for headless mode and argument parsing
source ./test_runner_utility.sh

# Run tests with the provided suite name, test file, and arguments
run_tests "${args[@]}"
