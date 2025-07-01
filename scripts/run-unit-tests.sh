#!/bin/bash

TEST_PLATFORM='iOS Simulator'
TEST_DEVICE=${TEST_DEVICE:-'iPhone 15'}
TEST_OS=${TEST_OS:-'18.5'}
TEST_DESTINATION="platform=${TEST_PLATFORM},name=${TEST_DEVICE},OS=${TEST_OS}"

GIT_REPO=$(git rev-parse --show-toplevel)

rm -rf ${GIT_REPO}/test_output

cd ${GIT_REPO}

echo "Running unit tests for ${TEST_DEVICE} on ${TEST_OS}..."

set -o pipefail && env NSUnbufferedIO=YES \
  xcodebuild \
  -workspace ${GIT_REPO}/Bookshelf.xcworkspace \
  -scheme "Client Develop" \
  -destination "${TEST_DESTINATION}" \
  -resultBundlePath ${GIT_REPO}/test_output/Tests.xcresult \
  -enableCodeCoverage YES \
  -skipMacroValidation \
  clean test 2>&1 | ${GIT_REPO}/tools/xcbeautify
