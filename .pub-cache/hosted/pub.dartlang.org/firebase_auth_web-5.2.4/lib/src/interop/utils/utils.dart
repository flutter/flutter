// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_core_web/firebase_core_web_interop.dart'
    as core_interop;

/// Returns Dart representation from JS Object.
dynamic dartify(Object jsObject) {
  return core_interop.dartify(jsObject);
}

/// Returns the JS implementation from Dart Object.
dynamic jsify(
  Object dartObject, [
  Object? Function(Object? object)? customJsify,
]) {
  return core_interop.jsify(dartObject, customJsify);
}
