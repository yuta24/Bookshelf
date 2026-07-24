#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

SWIFTLINT_VERSION=0.65.0

if [ -x "${GIT_REPO}/tools/swiftlint" ]; then
  echo "swiftlint is already installed, skipping download"
  exit 0
fi

curl -L "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/portable_swiftlint.zip" -o /tmp/swiftlint.zip
unzip -oq /tmp/swiftlint.zip -d /tmp/swiftlint
cp -f /tmp/swiftlint/swiftlint ${GIT_REPO}/tools
