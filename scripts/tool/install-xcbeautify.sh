#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

XCBEAUTIFY_VERSION=3.2.1
XCBEAUTIFY_VERSION_FILE=${GIT_REPO}/tools/xcbeautify.version

if [ -x "${GIT_REPO}/tools/xcbeautify" ] && [ "$(cat "${XCBEAUTIFY_VERSION_FILE}" 2>/dev/null)" = "${XCBEAUTIFY_VERSION}" ]; then
  echo "xcbeautify ${XCBEAUTIFY_VERSION} is already installed, skipping download"
  exit 0
fi

curl -L "https://github.com/cpisciotta/xcbeautify/releases/download/${XCBEAUTIFY_VERSION}/xcbeautify-${XCBEAUTIFY_VERSION}-universal-apple-macosx.zip" -o /tmp/xcbeautify.zip
unzip -oq /tmp/xcbeautify.zip -d /tmp/xcbeautify
cp -f /tmp/xcbeautify/release/xcbeautify ${GIT_REPO}/tools
echo "${XCBEAUTIFY_VERSION}" > "${XCBEAUTIFY_VERSION_FILE}"
