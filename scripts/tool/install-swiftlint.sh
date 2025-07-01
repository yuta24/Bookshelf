#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

SWIFTLINT_VERSION=0.59.1

curl -L "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/portable_swiftlint.zip" -o /tmp/swiftlint.zip
unzip -oq /tmp/swiftlint.zip -d /tmp/swiftlint
cp -f /tmp/swiftlint/swiftlint ${GIT_REPO}/tools
