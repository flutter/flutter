#!/bin/bash

set -e

COMPILE_COMMANDS="out/compile_commands.json"
if [ ! -f $COMPILE_COMMANDS ]; then
  ./flutter/tools/gn
fi

dart flutter/ci/lint.dart $COMPILE_COMMANDS flutter/
