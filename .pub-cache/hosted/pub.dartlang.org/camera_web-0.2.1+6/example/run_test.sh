#!/usr/bin/env bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if pgrep -lf chromedriver > /dev/null; then
  echo "chromedriver is running."

  if [ $# -eq 0 ]; then
    echo "No target specified, running all tests..."
    find integration_test/ -iname *_test.dart | xargs -n1 -I{} -t flutter drive -d web-server --web-port=7357 --browser-name=chrome --driver=test_driver/integration_test.dart --target='{}'
  else
    echo "Running test target: $1..."
    set -x
    flutter drive -d web-server --web-port=7357 --browser-name=chrome --driver=test_driver/integration_test.dart --target=$1
  fi

  else
    echo "chromedriver is not running."
    echo "Please, check the README.md for instructions on how to use run_test.sh"
fi

