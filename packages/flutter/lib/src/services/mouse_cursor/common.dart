// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A collection of all system mouse cursors supported by all platforms
// that Flutter is interested in. The implementation to these cursors are left
/// to platforms, which means multiple constants might result in the same cursor,
/// and the same constant might look different across platforms.
enum SystemCursorShape {
  /// The shape that corresponds to [SystemCursors.none].
  none,

  /// The shape that corresponds to [SystemCursors.basic].
  basic,

  /// The shape that corresponds to [SystemCursors.click].
  click,

  /// The shape that corresponds to [SystemCursors.text].
  text,

  /// The shape that corresponds to [SystemCursors.forbidden].
  forbidden,

  /// The shape that corresponds to [SystemCursors.grab].
  grab,

  /// The shape that corresponds to [SystemCursors.grabbing].
  grabbing,
}

/// TODOC
@immutable
class ActivateMouseCursorDetails {
  /// TODOC
  const ActivateMouseCursorDetails({
    @required this.device,
    @required this.delegate,
  }) : assert(device != null);

  /// TODOC
  final int device;

  /// TODOC
  final MouseCursorPlatformDelegate delegate;
}

/// TODOC
@immutable
abstract class MouseCursor {
  /// TODOC
  const MouseCursor();

  /// TODOC
  Future<void> activate(ActivateMouseCursorDetails details);

  /// TODOC
  /// Platform-independent
  String describeCursor();

  @override
  String toString() {
    return '$runtimeType(${describeCursor()})';
  }
}

/// TODOC
class NoopMouseCursor extends MouseCursor {
  /// TODOC
  const NoopMouseCursor();

  /// This method does nothing and immediately returns.
  @override
  Future<void> activate(ActivateMouseCursorDetails details) async {
    return;
  }

  @override
  String describeCursor() => '';
}

/// TODOC
abstract class MouseCursorPlatformDelegate {
  /// TODOC
  const MouseCursorPlatformDelegate();

  /// TODOC
  /// Returns whether the cursor was successfully set.
  Future<bool> activateSystemCursor(
    ActivateMouseCursorDetails details,
    SystemCursorShape shape,
  );
}

/// TODOC
class MouseCursorUnsupportedDelegate extends MouseCursorPlatformDelegate {
  /// TODOC
  const MouseCursorUnsupportedDelegate();

  @override
  Future<bool> activateSystemCursor(ActivateMouseCursorDetails details, SystemCursorShape shape) async {
    return true;
  }
}
