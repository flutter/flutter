// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_services/platform/system_sound.dart' as mojom;
import 'package:flutter_services/platform/system_sound.dart' show SystemSoundType;

import 'shell.dart';

export 'package:flutter_services/platform/system_sound.dart' show SystemSoundType;

mojom.SystemSoundProxy _initSystemSoundProxy() {
  return shell.connectToApplicationService('mojo:flutter_platform', mojom.SystemSound.connectToService);
}

final mojom.SystemSoundProxy _systemChromeProxy = _initSystemSoundProxy();

/// Allows easy access to the library of short system specific sounds for
/// common tasks.
class SystemSound {
  SystemSound._();

  /// Play the specified system sound. If that sound is not present on the
  /// system, this method is a no-op and returns `true`.
  ///
  /// Return Value:
  ///
  ///   boolean indicating if the intent to play the specified sound was
  ///   successfully conveyed to the embedder. No sound may actually play if the
  ///   device is muted or the sound was not available on the platform.
  static Future<bool> play(SystemSoundType type) {
    Completer<bool> completer = new Completer<bool>();
    _systemChromeProxy.play(type, (bool success) {
      completer.complete(success);
    });
    return completer.future;
  }
}
