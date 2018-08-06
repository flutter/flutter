#!/bin/bash

if git remote get-url upstream >/dev/null 2>&1; then
  UPSTREAM=upstream/master
else
  UPSTREAM=master
fi;

FLUTTER_VERSION="$(curl -s https://raw.githubusercontent.com/flutter/flutter/master/bin/internal/engine.version)"
BEHIND="$(git rev-list $FLUTTER_VERSION..$UPSTREAM --oneline | wc -l)"
MAX_BEHIND=16 # no more than 4 bisections to identify the issue

if [[ $BEHIND -le $MAX_BEHIND ]]; then
  echo "OK, the flutter/engine to flutter/flutter roll is only $BEHIND commits behind."
else
  echo "ERROR: The flutter/engine to flutter/flutter roll is $BEHIND commits behind!"
  echo "       It exceeds our max allowance of $MAX_BEHIND. Unless that this commit fixes the roll,"
  echo "       please roll engine into flutter first before merging more commits into engine."
  exit 1
fi

