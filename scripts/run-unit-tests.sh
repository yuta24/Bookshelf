#!/bin/bash

set -euo pipefail

GIT_REPO=$(git rev-parse --show-toplevel)

# Use automatic simulator detection
TEST_DESTINATION=$("${GIT_REPO}/scripts/detect-simulator.sh")

# Extract device and OS info for logging (optional fallback for display)
TEST_DEVICE=$(echo "$TEST_DESTINATION" | sed -E 's/.*name=([^,]+).*/\1/')
TEST_OS=$(echo "$TEST_DESTINATION" | sed -E 's/.*OS=([^,]+).*/\1/')

rm -rf ${GIT_REPO}/test_output

cd ${GIT_REPO}

echo "Running unit tests for ${TEST_DEVICE} on ${TEST_OS}..."
echo "Full destination: ${TEST_DESTINATION}"

set -o pipefail && env NSUnbufferedIO=YES \
  xcodebuild \
  -workspace ${GIT_REPO}/Bookshelf.xcworkspace \
  -scheme "Client Develop" \
  -destination "${TEST_DESTINATION}" \
  -resultBundlePath ${GIT_REPO}/test_output/Tests.xcresult \
  -enableCodeCoverage YES \
  -skipMacroValidation \
  clean test 2>&1 | ${GIT_REPO}/tools/xcbeautify
