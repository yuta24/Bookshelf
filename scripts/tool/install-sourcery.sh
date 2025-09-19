#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

SOURCERY_VERSION=2.3.0

curl -L "https://github.com/krzysztofzablocki/Sourcery/releases/download/${SOURCERY_VERSION}/Sourcery-${SOURCERY_VERSION}.zip" -o /tmp/sourcery.zip
unzip -oq /tmp/sourcery.zip -d /tmp/sourcery
cp -f /tmp/sourcery/bin/sourcery ${GIT_REPO}/tools
