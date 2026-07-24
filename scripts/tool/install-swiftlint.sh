#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

SWIFTLINT_VERSION=0.65.0
SWIFTLINT_VERSION_FILE=${GIT_REPO}/tools/swiftlint.version

if [ -x "${GIT_REPO}/tools/swiftlint" ] && [ "$(cat "${SWIFTLINT_VERSION_FILE}" 2>/dev/null)" = "${SWIFTLINT_VERSION}" ]; then
  echo "swiftlint ${SWIFTLINT_VERSION} is already installed, skipping download"
  exit 0
fi

curl -L "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/portable_swiftlint.zip" -o /tmp/swiftlint.zip
unzip -oq /tmp/swiftlint.zip -d /tmp/swiftlint
cp -f /tmp/swiftlint/swiftlint ${GIT_REPO}/tools
echo "${SWIFTLINT_VERSION}" > "${SWIFTLINT_VERSION_FILE}"
