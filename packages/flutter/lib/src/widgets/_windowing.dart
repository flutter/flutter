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
// 2. Throw an  `UnsupportedError` if `isWindowingEnabled`
//    is `false.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'package:flutter/foundation.dart';

import '../foundation/_features.dart';

/// Create a new window.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
void createWindow() {
  _throwIfWindowingDisabled();

  // TODO(team-windows): Add logic.
}

/// Resize a window.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
void resizeWindow() {
  _throwIfWindowingDisabled();

  // TODO(team-windows): Add logic.
}

void _throwIfWindowingDisabled() {
  if (!isWindowingEnabled) {
    throw UnsupportedError('''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:

1. Switch to Flutter's main release channel.
2. Turn on the multi-window feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''');
  }
}
