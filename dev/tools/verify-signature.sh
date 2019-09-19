#!/bin/bash

if ! type spctl >/dev/null 2>&1; then
  echo 'This script requires Xcode (specifically the `spctl` binary)'
  exit 1
fi

if [ -z "$1" ]; then
  echo 'Please supply a path to a binary to verify as the first argument'
  exit 1
fi

# Note that for flutter's packaged command-line binaries, this tool will return
# an error, even if the file in question is signed, because it is not
# recognized as an app. Thus, we have to patter-match on the tool's stderr.
OUT=$(spctl -vvv --assess --type exec $1 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "$1 appears to be signed."
elif [[ "$OUT" =~ 'the code is valid but does not seem to be an app' ]]; then
  echo "$1 appears to be signed."
elif [[ "$OUT" =~ 'no usable signature' ]]; then
  echo "$1 does not appear to be signed."
  exit 1
else
  echo "Output of spctl not recognized:"
  echo
  echo "$OUT"
  exit 1
fi
