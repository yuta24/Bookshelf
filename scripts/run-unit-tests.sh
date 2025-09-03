#!/bin/bash

set -euo pipefail

GIT_REPO=$(git rev-parse --show-toplevel)

TEST_DESTINATION="platform=iphonesimulator,OS=${TEST_OS},name=${TEST_DEVICE}"

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
