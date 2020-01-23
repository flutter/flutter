#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $(basename $0) <engine_commit_hash>"
    exit 1
fi

ENGINE_COMMIT=$1
BUILDERS=$(curl 'https://ci.chromium.org/p/flutter/g/engine/builders' 2>/dev/null|sed -En 's:.*aria-label="builder buildbucket/luci\.flutter\.prod/([^/]+)".*:\1:p'|sort|uniq)

IFS=$'\n'
for BUILDER in $BUILDERS; do
    echo "Building $BUILDER..."
    bb add \
       -commit "https://chromium.googlesource.com/external/github.com/flutter/engine/+/$ENGINE_COMMIT" \
       "flutter/prod/$BUILDER"
    sleep 1
done
