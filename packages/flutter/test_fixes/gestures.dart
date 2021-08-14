// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

void main() {
  // Change made in https://github.com/flutter/flutter/pull/28602
  final PointerEnterEvent enterEvent = PointerEnterEvent.fromHoverEvent(PointerHoverEvent());

  // Change made in https://github.com/flutter/flutter/pull/28602
  final PointerExitEvent exitEvent = PointerExitEvent.fromHoverEvent(PointerHoverEvent());

  // Changes made in https://github.com/flutter/flutter/pull/66043
  VelocityTracker tracker = VelocityTracker();
  tracker = VelocityTracker(PointerDeviceKind.mouse);

  // Changes made in https://github.com/flutter/flutter/pull/81858
  DragGestureRecognizer();
  DragGestureRecognizer(kind: PointerDeviceKind.touch);
  VerticalDragGestureRecognizer();
  VerticalDragGestureRecognizer(kind: PointerDeviceKind.touch);
  HorizontalDragGestureRecognizer();
  HorizontalDragGestureRecognizer(kind: PointerDeviceKind.touch);
  GestureRecognizer();
  GestureRecognizer(kind: PointerDeviceKind.touch);
  OneSequenceGestureRecognizer();
  OneSequenceGestureRecognizer(kind: PointerDeviceKind.touch);
  PrimaryPointerGestureRecognizer();
  PrimaryPointerGestureRecognizer(kind: PointerDeviceKind.touch);
  EagerGestureRecognizer();
  EagerGestureRecognizer(kind: PointerDeviceKind.touch);
  ForcePressGestureRecognizer();
  ForcePressGestureRecognizer(kind: PointerDeviceKind.touch);
  LongPressGestureRecognizer();
  LongPressGestureRecognizer(kind: PointerDeviceKind.touch);
  MultiDragGestureRecognizer();
  MultiDragGestureRecognizer(kind: PointerDeviceKind.touch);
  ImmediateMultiDragGestureRecognizer();
  ImmediateMultiDragGestureRecognizer(kind: PointerDeviceKind.touch);
  HorizontalMultiDragGestureRecognizer();
  HorizontalMultiDragGestureRecognizer(kind: PointerDeviceKind.touch);
  VerticalMultiDragGestureRecognizer();
  VerticalMultiDragGestureRecognizer(kind: PointerDeviceKind.touch);
  DelayedMultiDragGestureRecognizer();
  DelayedMultiDragGestureRecognizer(kind: PointerDeviceKind.touch);
  DoubleTapGestureRecognizer();
  DoubleTapGestureRecognizer(kind: PointerDeviceKind.touch);
  MultiTapGestureRecognizer();
  MultiTapGestureRecognizer(kind: PointerDeviceKind.touch);
  ScaleGestureRecognizer();
  ScaleGestureRecognizer(kind: PointerDeviceKind.touch);
}
