// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';

/// All platforms that Flutter support mouse cursor on.
// TODO(dkwingsmt): Merge to [TargetPlatform] when possible
enum MouseCursorTargetPlatform {
  android,

  linux,
}

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
class CreateMouseCursorDetails {
  /// TODOC
  const CreateMouseCursorDetails({
  });
}

/// TODOC
@immutable
class ActivateMouseCursorDetails {
  /// TODOC
  const ActivateMouseCursorDetails({
    @required this.device,
    @required this.mouseCursorChannel,
  }) : assert(device != null), assert(mouseCursorChannel != null);

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
@immutable
abstract class PlatformDependentCursor extends MouseCursor {
  /// TODOC
  const PlatformDependentCursor();

  static void _ensureCalculatedPlatform() {
    if (_platformIsSupported == null) {
      _platformIsSupported = true;
      if (Platform.isLinux) {
        _platform = MouseCursorTargetPlatform.linux;
      } else if (Platform.isAndroid) {
        _platform = MouseCursorTargetPlatform.android;
      } else {
        _platformIsSupported = false;
      }
    }
  }
  static MouseCursorTargetPlatform _platform;
  static bool _platformIsSupported;

  @override
  Future<void> activate(ActivateMouseCursorDetails details) {
    _ensureCalculatedPlatform();
    if (!_platformIsSupported)
      return onActivateOnUnsupportedPlatform(details);
    assert(_platform != null);
    return activateOnPlatform(_platform, details);
  }

  /// TODOC
  /// platform is never null
  @protected
  Future<void> activateOnPlatform(
    MouseCursorTargetPlatform platform,
    ActivateMouseCursorDetails details,
  );

  /// TODOC
  @protected
  Future<void> onActivateOnUnsupportedPlatform(ActivateMouseCursorDetails details) async {
    return;
  }
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

  /// TODOC
  /// Returns a cursor handle. Can be null.
  Future<int> createCursor(
    CreateMouseCursorDetails details,
  );
}

/// TODOC
class UnsupportedSystemCursorCollection extends MouseCursorPlatformDelegate {
  /// TODOC
  const UnsupportedSystemCursorCollection();

  @override
  Future<bool> activateSystemCursor(ActivateMouseCursorDetails details, SystemCursorShape shape) async {
    return true;
  }

  @override
  Future<int> createCursor(CreateMouseCursorDetails details) {
    return null;
  }
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
    return cursor.activate(ActivateMouseCursorDetails(
      device: device,
      mouseCursorChannel: channel,
    ));
  }
}
