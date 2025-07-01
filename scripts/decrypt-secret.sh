#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

gpg --quiet --batch --yes --decrypt --passphrase=$ENV_PASSPHRASE --output $GIT_REPO/.env $GIT_REPO/.env.gpg

gpg --quiet --batch --yes --decrypt --passphrase=$GOOGLE_SERVICE_PASSPHRASE --output $GIT_REPO/Develop/GoogleService-Info.plist $GIT_REPO/Develop/GoogleService-Info.plist.gpg
gpg --quiet --batch --yes --decrypt --passphrase=$GOOGLE_SERVICE_PASSPHRASE --output $GIT_REPO/Production/GoogleService-Info.plist $GIT_REPO/Production/GoogleService-Info.plist.gpg
