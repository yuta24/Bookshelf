#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

cd ${GIT_REPO}

set -o pipefail && env NSUnbufferedIO=YES \
  xcodebuild \
  -workspace ${GIT_REPO}/Bookshelf.xcworkspace \
  -scheme "Client Develop" \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  -derivedDataPath ${GIT_REPO}/build \
  -skipMacroValidation \
  clean build 2>&1 | ${GIT_REPO}/tools/xcbeautify

mv ${GIT_REPO}/build/Build/Products/Debug-iphonesimulator/Client.app ${GIT_REPO}/Simulator.app
