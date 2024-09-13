#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# exit on error, or usage of unset var
set -euo pipefail

# Run `dart ./xcode_backend.dart` with the dart from $FLUTTER_ROOT.
dart="${FLUTTER_ROOT}/bin/dart"
xcode_backend_dart="${BASH_SOURCE[0]%.sh}.dart"
exec "${dart}" "${xcode_backend_dart}" "$@"
