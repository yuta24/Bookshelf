#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

LICENSEPLIST_VERSION=3.27.2

curl -L "https://github.com/mono0926/LicensePlist/releases/download/${LICENSEPLIST_VERSION}/portable_licenseplist.zip" -o /tmp/licenseplist.zip
unzip -oq /tmp/licenseplist.zip -d /tmp/licenseplist
cp -f /tmp/licenseplist/license-plist ${GIT_REPO}/tools
