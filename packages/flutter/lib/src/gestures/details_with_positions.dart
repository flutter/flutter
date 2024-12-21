// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:ui';
library;

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// Details that contain positions at which the single pointer interacts
/// with the screen.
abstract class GestureDetailsWithPositions with Diagnosticable {
  /// Creates details with positions.
  const GestureDetailsWithPositions({this.globalPosition = Offset.zero, Offset? localPosition})
    : localPosition = localPosition ?? globalPosition;

  /// The global position at which the pointer interacts with the screen.
  ///  * For *start details, interact means contacting the screen.
  ///  * For *update details, interact means moving on the screen.
  ///  * For *end details, interact means lifted from the screen.
  ///
  /// Defaults to the origin if not specified in the constructor.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  final Offset globalPosition;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer interacts with the screen.
  ///  * For *start details, interact means contacting the screen.
  ///  * For *update details, interact means moving on the screen.
  ///  * For *end details, interact means lifted from the screen.
  ///
  /// Defaults to [globalPosition] if not specified in the constructor.
  final Offset localPosition;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
  }
}
