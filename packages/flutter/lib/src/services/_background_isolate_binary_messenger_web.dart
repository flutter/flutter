// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'binding.dart';

// ignore: avoid_classes_with_only_static_members
/// Stand-in for non-web platforms' [BackgroundIsolateBinaryMessenger].
class BackgroundIsolateBinaryMessenger {
  /// Throws an [UnsupportedError].
  static BinaryMessenger get instance {
    throw UnsupportedError('Isolates not supported on web.');
  }
}
