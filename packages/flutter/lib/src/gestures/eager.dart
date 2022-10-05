// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'recognizer.dart';

export 'dart:ui' show PointerDeviceKind;

export 'events.dart' show PointerDownEvent, PointerEvent;

/// A gesture recognizer that eagerly claims victory in all gesture arenas.
///
/// This is typically passed in [AndroidView.gestureRecognizers] in order to immediately dispatch
/// all touch events inside the view bounds to the embedded Android view.
/// See [AndroidView.gestureRecognizers] for more details.
class EagerGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Create an eager gesture recognizer.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  EagerGestureRecognizer({
    @Deprecated(
      'Migrate to supportedDevices. '
      'This feature was deprecated after v2.3.0-1.0.pre.',
    )
    super.kind,
    super.supportedDevices,
  });

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
    stopTrackingPointer(event.pointer);
  }

  @override
  String get debugDescription => 'eager';

  @override
  void didStopTrackingLastPointer(int pointer) { }

  @override
  void handleEvent(PointerEvent event) { }
}
