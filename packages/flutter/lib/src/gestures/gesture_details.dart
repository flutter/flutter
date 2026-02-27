// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Offset;

/// An abstract interface representing gesture details that include positional information.
///
/// This class serve as a common interface for gesture details that involve positional data,
/// such as dragging and tapping. It simplifies gesture handling by enabling the use of shared logic
/// across multiple gesture types, users can create a method to handle a single gesture details
/// with this position information. For example:
///
/// ```dart
/// void handlePositionedGestures(PositionedGestureDetails details) {
///   // Handle the positional information of the gesture details.
/// }
/// ```
abstract interface class PositionedGestureDetails {
  /// Creates details with positions.
  const PositionedGestureDetails({required this.globalPosition, required this.localPosition});

  /// {@template flutter.gestures.gesturedetails.PositionedGestureDetails.globalPosition}
  /// The global position at which the pointer interacts with the screen.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  /// {@endtemplate}
  final Offset globalPosition;

  /// {@template flutter.gestures.gesturedetails.PositionedGestureDetails.localPosition}
  /// The local position in the coordinate system of the event receiver at
  /// which the pointer interacts with the screen.
  ///
  /// See also:
  ///
  ///  * [globalPosition], which is the global position at which the pointer
  ///    interacts with the screen.
  /// {@endtemplate}
  final Offset localPosition;
}
