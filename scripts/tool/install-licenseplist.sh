#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

LICENSEPLIST_VERSION=3.27.9
LICENSEPLIST_VERSION_FILE=${GIT_REPO}/tools/license-plist.version

if [ -x "${GIT_REPO}/tools/license-plist" ] && [ "$(cat "${LICENSEPLIST_VERSION_FILE}" 2>/dev/null)" = "${LICENSEPLIST_VERSION}" ]; then
  echo "license-plist ${LICENSEPLIST_VERSION} is already installed, skipping download"
  exit 0
fi

curl -L "https://github.com/mono0926/LicensePlist/releases/download/${LICENSEPLIST_VERSION}/portable_licenseplist.zip" -o /tmp/licenseplist.zip
unzip -oq /tmp/licenseplist.zip -d /tmp/licenseplist
cp -f /tmp/licenseplist/license-plist ${GIT_REPO}/tools
echo "${LICENSEPLIST_VERSION}" > "${LICENSEPLIST_VERSION_FILE}"
