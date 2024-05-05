#!/bin/sh

set -xe

echo "Running on $(node -v)"

# Cleanup
rm -rf node_modules build-tmp-* lib/binding

# Install build dependencies
if [ -f /etc/alpine-release ]; then
  apk add --no-cache --virtual .build-deps make gcc g++ python3
fi

su node -c "npm test; npx node-pre-gyp package"
