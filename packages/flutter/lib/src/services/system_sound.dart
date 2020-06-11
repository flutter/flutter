// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'system_channels.dart';

/// A sound provided by the system.
enum SystemSoundType {
  /// A short indication that a button was pressed.
  click,
}

/// Provides access to the library of short system specific sounds for common
/// tasks.
class SystemSound {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  SystemSound._();

  /// Play the specified system sound. If that sound is not present on the
  /// system, the call is ignored.
  static Future<void> play(SystemSoundType type) async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemSound.play',
      type.toString(),
    );
  }
}
