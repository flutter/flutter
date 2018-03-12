#!/bin/bash

if [[ $# -ne 1 ]]; then
  echo "Invalid test target arguments.

Please invoke test from VSCode via the workbench.action.tasks.test command."
  exit 1
fi

if [[ "$1" != *.dart ]]; then
  echo "Only .dart files can be tested by task in this repo."
  exit 1
fi

echo "Testing $1..."

if [[ "$1" == packages/flutter/test/* ]]; then
  cd packages/flutter
  ../../bin/flutter test ../../$1
elif [[ "$1" == packages/flutter_tools/test/* ]]; then
  bin/cache/dart-sdk/bin/dart $1
else
  echo "No test task configured for $1.

Please edit .vscode/test.sh to configure new test types."
  exit 1
fi
