#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runner for dart tests. It expects a single parameter with the full
# path to the start folder where tests will be run.

set -e

dir=$(dirname $0)

pushd $dir > /dev/null
dart validate_json.dart engine_try_builders.json
dart validate_json.dart engine_prod_builders.json

popd > /dev/null


