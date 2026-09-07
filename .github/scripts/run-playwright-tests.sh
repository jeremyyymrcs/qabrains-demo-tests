#!/bin/bash

set -e

CONTAINER_NAME="playwright-container"

echo "======================================"
echo "Starting Playwright tests"
echo "======================================"

rm -rf reports
mkdir -p reports

set +e

docker run \
  --name "$CONTAINER_NAME" \
  --env-file .env \
  playwright-test:latest

EXIT_CODE=$?

set -e

echo "Docker exit code: $EXIT_CODE"

# ------------------------------------------------------------
# Copy reports from container
# ------------------------------------------------------------

docker cp "$CONTAINER_NAME:/app/reports/." reports/ 2>/dev/null || true

# ------------------------------------------------------------
# Parse test summary
# ------------------------------------------------------------

TOTAL=0
PASSED=0
FAILED=0

if [ -f reports/test_summary.txt ]; then

  TOTAL=$(awk -F: '/Total/ {
    gsub(/ /,"",$2);
    print $2
  }' reports/test_summary.txt)

  PASSED=$(awk -F: '/Passed/ {
    gsub(/ /,"",$2);
    print $2
  }' reports/test_summary.txt)

  FAILED=$(awk -F: '/Failed/ {
    gsub(/ /,"",$2);
    print $2
  }' reports/test_summary.txt)

fi

TOTAL=${TOTAL:-0}
PASSED=${PASSED:-0}
FAILED=${FAILED:-0}

echo ""
echo "======================================"
echo "PLAYWRIGHT RESULTS"
echo "======================================"
echo "Total  : $TOTAL"
echo "Passed : $PASSED"
echo "Failed : $FAILED"
echo "======================================"

# ------------------------------------------------------------
# Determine status
# ------------------------------------------------------------

if [ "$FAILED" -gt 0 ] || [ "$EXIT_CODE" -ne 0 ]; then
  RESULT_STATUS="FAILED"
else
  RESULT_STATUS="PASSED"
fi

# ------------------------------------------------------------
# GitHub outputs
# ------------------------------------------------------------

echo "result_status=$RESULT_STATUS" >> "$GITHUB_OUTPUT"
echo "passed=$PASSED" >> "$GITHUB_OUTPUT"
echo "failed=$FAILED" >> "$GITHUB_OUTPUT"
echo "total=$TOTAL" >> "$GITHUB_OUTPUT"

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

docker rm "$CONTAINER_NAME" 2>/dev/null || true

# ------------------------------------------------------------
# Fail job AFTER reports have been collected
# ------------------------------------------------------------

if [ "$FAILED" -gt 0 ] || [ "$EXIT_CODE" -ne 0 ]; then
  echo "Playwright tests failed."
  exit 1
fi

echo "Playwright tests passed."