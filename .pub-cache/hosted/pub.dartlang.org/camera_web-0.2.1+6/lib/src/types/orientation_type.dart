// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

/// A screen orientation type.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ScreenOrientation/type
abstract class OrientationType {
  /// The primary portrait mode orientation.
  /// Corresponds to [DeviceOrientation.portraitUp].
  static const String portraitPrimary = 'portrait-primary';

  /// The secondary portrait mode orientation.
  /// Corresponds to [DeviceOrientation.portraitSecondary].
  static const String portraitSecondary = 'portrait-secondary';

  /// The primary landscape mode orientation.
  /// Corresponds to [DeviceOrientation.landscapeLeft].
  static const String landscapePrimary = 'landscape-primary';

  /// The secondary landscape mode orientation.
  /// Corresponds to [DeviceOrientation.landscapeRight].
  static const String landscapeSecondary = 'landscape-secondary';
}
