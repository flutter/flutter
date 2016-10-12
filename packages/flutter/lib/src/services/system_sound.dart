// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// A sound provided by the system
enum SystemSoundType {
  /// A short indication that a button was pressed.
  click,
}

/// Allows easy access to the library of short system specific sounds for
/// common tasks.
class SystemSound {
  SystemSound._();

  /// Play the specified system sound. If that sound is not present on the
  /// system, this method is a no-op.
  static Future<Null> play(SystemSoundType type) async {
    await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'SystemSound.play',
      'args': <String>[ type.toString() ],
    });
  }
}
