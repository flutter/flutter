// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'pointer_scroll_details.dart';

/// Interface for objects that receive updates about pointer device scroll
/// gestures (e.g., from trackpad).
///
/// The scrolling infrastructure in the widgets library uses this interface to
/// notify the [PointerScrollActivity] when the user sends a scroll gesture to
/// the scrollable.
abstract class PointerScroll {
  /// The scroll gesture has continued.
  void update(PointerScrollUpdateDetails details) {}

  /// The scroll gesture has ended.
  ///
  /// The velocity at which the pointer was moving when it stopped contacting
  /// the screen is available in the `details`.
  void end(PointerScrollEndDetails details) {}

  /// The scroll gesture is no longer directed towards this receiver.
  ///
  /// For example, the user might have been interrupted by a system-modal dialog
  /// in the middle of the scroll.
  void cancel() {}
}
