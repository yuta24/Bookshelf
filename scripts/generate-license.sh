#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

${GIT_REPO}/tools/license-plist \
    --output-path ${GIT_REPO}/Client/Client/Resources/Settings.bundle
