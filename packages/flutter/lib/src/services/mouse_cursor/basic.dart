// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';

/// TODOC
class MouseCursorActivateDetails {
  /// TODOC
  MouseCursorActivateDetails({
    this.device,
    this.mouseCursorChannel,
  });

  /// TODOC
  final int device;

  /// TODOC
  final MethodChannel mouseCursorChannel;
}

/// TODOC
@immutable
abstract class MouseCursor {
  /// TODOC
  const MouseCursor();

  /// TODOC
  Future<void> onActivate(MouseCursorActivateDetails details);

  /// TODOC
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
  Future<void> onActivate(MouseCursorActivateDetails details) async {
    return;
  }

  @override
  String describeCursor() => '';
}

/// TODOC
///
/// This is a collection of all system mouse cursors supported by all platforms
/// that Flutter is interested in. The implementation to these cursors are left
/// to platforms, which means multiple constants might result in the same
/// cursor, and the same constant might look different across platforms.
///
/// All cursors except for basic and none have a default implementation of basic.

enum SystemCursorShape {
  /// The shape that corresponds to [SystemCursors.releaseControl].
  releaseControl,

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
class UnsupportedSystemCursorCollection extends SystemCursorCollection {
  /// TODOC
  const UnsupportedSystemCursorCollection();

  @override
  MouseCursor get none => const NoopMouseCursor();

  @override
  MouseCursor get basic => const NoopMouseCursor();
}

/// TODOC
class MouseCursorManager {
  /// Create a [MouseCursorManager] by providing the channel.
  ///
  /// The `channel` must not be null.
  MouseCursorManager(this.channel) : assert(channel != null);

  /// The channel used to send messages. Typically [SystemChannels.mouseCursor].
  final MethodChannel channel;

  /// TODOC
  Future<void> setDeviceCursor(int device, MouseCursor cursor) async {
    throw UnimplementedError();
  }
}
