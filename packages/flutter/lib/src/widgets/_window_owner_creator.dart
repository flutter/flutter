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
//    is `false.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../foundation/_features.dart';
import '_window.dart';

import '_window_ffi.dart' if (dart.library.js_util) '_window_web.dart' as window_impl;

const String _kWindowingDisabledErrorMessage = '''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

/// Creates default windowing owner for standard desktop embedders.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
WindowingOwner createDefaultOwner() {
  if (!isWindowingEnabled) {
    return _WindowingOwnerUnsupported(errorMessage: _kWindowingDisabledErrorMessage);
  }

  final WindowingOwner? owner = window_impl.createDefaultOwner();
  if (owner != null) {
    return owner;
  }

  return _WindowingOwnerUnsupported(errorMessage: 'Windowing is unsupported on this platform.');
}

/// Windowing delegate used on platforms that do not support windowing.
class _WindowingOwnerUnsupported extends WindowingOwner {
  _WindowingOwnerUnsupported({required this.errorMessage});

  final String errorMessage;

  @override
  RegularWindowController createRegularWindowController({
    required RegularWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  }) {
    throw UnsupportedError(errorMessage);
  }

  @override
  bool hasTopLevelWindows() {
    throw UnsupportedError(errorMessage);
  }
}
