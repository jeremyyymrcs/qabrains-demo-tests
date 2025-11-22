#!/bin/bash

# Suite name and test file
export SUITE_NAME="All Functional Test Suite"
export TEST_FILE=$(find . -type f -name "test_*.py")

# Get arguments passed to the script
args="$*"

# Source the common functions for headless mode and argument parsing
source ./test_runner_utility.sh

# Run tests with the provided suite name, test file, and arguments
run_tests "${args[@]}"
