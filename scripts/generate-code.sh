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
    --args backend_base_url=\"${BACKEND_BASE_URL}\" \
    --args backend_api_key=\"${BACKEND_API_KEY}\"

${GIT_REPO}/tools/sourcery \
    --verbose \
    --sources ${GIT_REPO}/Infrastructure/Sources/SearchClientLive \
    --templates ${GIT_REPO}/Templates/Infrastructure \
    --output ${GIT_REPO}/Infrastructure/Sources/SearchClientLive/Generated \
    --args backend_base_url=\"${BACKEND_BASE_URL}\" \
    --args backend_api_key=\"${BACKEND_API_KEY}\"
