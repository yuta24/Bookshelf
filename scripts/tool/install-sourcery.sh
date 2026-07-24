#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

SOURCERY_VERSION=2.3.0

if [ -x "${GIT_REPO}/tools/sourcery" ]; then
  echo "sourcery is already installed, skipping download"
  exit 0
fi

curl -L "https://github.com/krzysztofzablocki/Sourcery/releases/download/${SOURCERY_VERSION}/Sourcery-${SOURCERY_VERSION}.zip" -o /tmp/sourcery.zip
unzip -oq /tmp/sourcery.zip -d /tmp/sourcery
cp -f /tmp/sourcery/bin/sourcery ${GIT_REPO}/tools
