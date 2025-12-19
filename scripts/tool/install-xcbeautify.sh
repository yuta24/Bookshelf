#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

XCBEAUTIFY_VERSION=3.1.2

curl -L "https://github.com/cpisciotta/xcbeautify/releases/download/${XCBEAUTIFY_VERSION}/xcbeautify-${XCBEAUTIFY_VERSION}-universal-apple-macosx.zip" -o /tmp/xcbeautify.zip
unzip -oq /tmp/xcbeautify.zip -d /tmp/xcbeautify
cp -f /tmp/xcbeautify/release/xcbeautify ${GIT_REPO}/tools
