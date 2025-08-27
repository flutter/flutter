// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show RootIsolateToken;
import 'binding.dart';

/// Stand-in for non-web platforms' [BackgroundIsolateBinaryMessenger].
class BackgroundIsolateBinaryMessenger {
  /// Throws an [UnsupportedError].
  static BinaryMessenger get instance {
    throw UnsupportedError('Isolates not supported on web.');
  }

  /// Throws an [UnsupportedError].
  static void ensureInitialized(ui.RootIsolateToken token) {
    throw UnsupportedError('Isolates not supported on web.');
  }
}
