#!/bin/bash
set -e

mkdir -p reports

set +e
docker run \
  --name playwright-container \
  --env-file .env \
  playwright-test:latest \
  > reports/playwright.log 2>&1

EXIT_CODE=$?
set -e

echo "Docker exit code: $EXIT_CODE"

# Copy reports after container exits
mkdir -p reports/allure-report
docker cp playwright-container:/app/reports/allure-report ./reports/allure-report || echo "No Allure report found"
docker cp playwright-container:/app/reports/test_summary.txt ./reports/test_summary.txt || echo "No test_summary.txt found"

# Parse the summary safely (handle DOS line endings)
if [ -f "./reports/test_summary.txt" ]; then
  TOTAL=$(awk -F': ' '/Total tests/ {gsub("\r","",$2); print $2}' ./reports/test_summary.txt)
  PASSED=$(awk -F': ' '/Passed/ {gsub("\r","",$2); print $2}' ./reports/test_summary.txt)
  FAILED=$(awk -F': ' '/Failed/ {gsub("\r","",$2); print $2}' ./reports/test_summary.txt)
else
  TOTAL=0
  PASSED=0
  FAILED=1
fi

echo "Total: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

echo "=== Playwright Failure Log ==="

if [ -f "./reports/playwright.log" ]; then
  cat reports/playwright.log
else
  echo "No Playwright log found"
fi

# Determine result using both summary and exit code
if [ "$FAILED" -gt 0 ] || [ "$EXIT_CODE" -ne 0 ]; then
  RESULT_STATUS="⚠️ Status: Failure"
  EXIT_FINAL=1
else
  RESULT_STATUS="🎉 Status: Success"
  EXIT_FINAL=0
fi

# Output for GitHub Actions
echo "result_status=$RESULT_STATUS" >> $GITHUB_OUTPUT
echo "passed=$PASSED" >> $GITHUB_OUTPUT
echo "failed=$FAILED" >> $GITHUB_OUTPUT
echo "total=$TOTAL" >> $GITHUB_OUTPUT

# Remove container
docker rm -f playwright-container

exit $EXIT_FINAL
