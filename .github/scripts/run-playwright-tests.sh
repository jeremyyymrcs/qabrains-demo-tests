#!/bin/bash

set -u

echo "======================================"
echo "Starting Playwright Docker container"
echo "======================================"

mkdir -p reports

# Run container and capture output
docker run \
  --name playwright-container \
  --env-file .env \
  -e OLLAMA_HOST=http://host.docker.internal:11434 \
  --add-host=host.docker.internal:host-gateway \
  playwright-test:latest \
  2>&1 | tee reports/playwright-output.log

EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "Docker exit code: $EXIT_CODE"

# ======================================
# COPY REPORTS
# ======================================

echo "Copying test reports..."

docker cp playwright-container:/app/reports/allure-report \
  ./reports/allure-report \
  2>/dev/null || echo "No Allure report found"

docker cp playwright-container:/app/reports/test_summary.txt \
  ./reports/test_summary.txt \
  2>/dev/null || echo "No test_summary.txt found"

# ======================================
# PARSE SUMMARY
# ======================================

if [ -f "./reports/test_summary.txt" ]; then

  TOTAL=$(awk -F': ' '/Total tests/ {
    gsub("\r","",$2);
    print $2
  }' ./reports/test_summary.txt)

  PASSED=$(awk -F': ' '/Passed/ {
    gsub("\r","",$2);
    print $2
  }' ./reports/test_summary.txt)

  FAILED=$(awk -F': ' '/Failed/ {
    gsub("\r","",$2);
    print $2
  }' ./reports/test_summary.txt)

else

  echo "test_summary.txt not found."

  TOTAL=0
  PASSED=0
  FAILED=1

fi

# Protect against empty values
TOTAL=${TOTAL:-0}
PASSED=${PASSED:-0}
FAILED=${FAILED:-0}

echo ""
echo "======================================"
echo "TEST SUMMARY"
echo "======================================"
echo "Total:  $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "======================================"

# ======================================
# DETERMINE RESULT
# ======================================

if [ "$FAILED" -gt 0 ] || [ "$EXIT_CODE" -ne 0 ]; then

  RESULT_STATUS="⚠️ Status: Failure"
  EXIT_FINAL=1

else

  RESULT_STATUS="🎉 Status: Success"
  EXIT_FINAL=0

fi

# ======================================
# GITHUB ACTIONS OUTPUT
# ======================================

echo "result_status=$RESULT_STATUS" >> "$GITHUB_OUTPUT"
echo "passed=$PASSED" >> "$GITHUB_OUTPUT"
echo "failed=$FAILED" >> "$GITHUB_OUTPUT"
echo "total=$TOTAL" >> "$GITHUB_OUTPUT"

# ======================================
# CLEANUP
# ======================================

docker rm -f playwright-container 2>/dev/null || true

echo ""
echo "Final result: $RESULT_STATUS"

exit $EXIT_FINAL