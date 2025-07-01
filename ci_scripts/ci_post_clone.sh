#!/bin/bash

defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

brew install -q gpg

GIT_REPO=$(git rev-parse --show-toplevel)

${GIT_REPO}/scripts/tool/install-sourcery.sh

${GIT_REPO}/scripts/decrypt-secret.sh
${GIT_REPO}/scripts/generate-code.sh
