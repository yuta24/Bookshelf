#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

PERIPHERY_VERSION=2.17.0

curl -L "https://github.com/peripheryapp/periphery/releases/download/${PERIPHERY_VERSION}/periphery-${PERIPHERY_VERSION}.zip" -o /tmp/periphery.zip
unzip -oq /tmp/periphery.zip -d ${GIT_REPO}/tools/periphery
