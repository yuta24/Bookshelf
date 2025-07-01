#!/bin/bash

GIT_REPO=$(git rev-parse --show-toplevel)

set -a;
source ${GIT_REPO}/.env
set +a;

${GIT_REPO}/tools/sourcery \
    --verbose \
    --sources ${GIT_REPO}/Infrastructure/Sources/BookClientLive \
    --templates ${GIT_REPO}/Templates/Infrastructure \
    --output ${GIT_REPO}/Infrastructure/Sources/BookClientLive/Generated \
    --args rakuten_app_id=\"${RAKUTEN_APP_ID}\" \
    --args rakuten_affiliate_id=\"${RAKUTEN_AFFILIATE_ID}\"

${GIT_REPO}/tools/sourcery \
    --verbose \
    --sources ${GIT_REPO}/Infrastructure/Sources/SearchClientLive \
    --templates ${GIT_REPO}/Templates/Infrastructure \
    --output ${GIT_REPO}/Infrastructure/Sources/SearchClientLive/Generated \
    --args rakuten_app_id=\"${RAKUTEN_APP_ID}\" \
    --args rakuten_affiliate_id=\"${RAKUTEN_AFFILIATE_ID}\"
