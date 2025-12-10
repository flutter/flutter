// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Do not import this file in production applications or packages published
// to pub.dev. Flutter will make breaking changes to this file, even in patch
// versions.
//
// All APIs in this file must be private or must:
//
// 1. Have the `@internal` attribute.
// 2. Throw an `UnsupportedError` if `isWindowingEnabled`
//    is `false`.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'package:flutter/foundation.dart';

import '_window.dart';

/// Creates a default [WindowingOwner] for web.
///
/// Returns `null` as web does not support multiple windows.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
WindowingOwner? createDefaultOwner() {
  return null;
}
