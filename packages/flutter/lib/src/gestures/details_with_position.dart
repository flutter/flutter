// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ui';

/// Details object for gesture callbacks that provides local and global positions.
abstract class GestureDetailsWithPosition {
  /// The global position at which the pointer contacted the screen.
  Offset get globalPosition;

  /// The local position at which the pointer contacted the screen.
  Offset get localPosition;
}
