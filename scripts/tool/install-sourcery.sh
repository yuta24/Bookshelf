#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

SOURCERY_VERSION=2.3.0
SOURCERY_VERSION_FILE=${GIT_REPO}/tools/sourcery.version

if [ -x "${GIT_REPO}/tools/sourcery" ] && [ "$(cat "${SOURCERY_VERSION_FILE}" 2>/dev/null)" = "${SOURCERY_VERSION}" ]; then
  echo "sourcery ${SOURCERY_VERSION} is already installed, skipping download"
  exit 0
fi

curl -L "https://github.com/krzysztofzablocki/Sourcery/releases/download/${SOURCERY_VERSION}/Sourcery-${SOURCERY_VERSION}.zip" -o /tmp/sourcery.zip
unzip -oq /tmp/sourcery.zip -d /tmp/sourcery
cp -f /tmp/sourcery/bin/sourcery ${GIT_REPO}/tools
echo "${SOURCERY_VERSION}" > "${SOURCERY_VERSION_FILE}"
