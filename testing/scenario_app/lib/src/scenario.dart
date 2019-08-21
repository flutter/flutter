// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

/// A scenario to run for testing.
abstract class Scenario {
  /// Creates a new scenario using a specific Window instance.
  const Scenario(this.window);

  /// The window used by this scenario. May be mocked.
  final Window window;

  /// Called by the program when a frame is ready to be drawn.
  ///
  /// See [Window.onBeginFrame] for more details.
  void onBeginFrame(Duration duration);

  /// Called by the program when the microtasks from [onBeginFrame] have been
  /// flushed.
  ///
  /// See [Window.onDrawFrame] for more details.
  void onDrawFrame() {}

  /// Called by the program when the window metrics have changed.
  ///
  /// See [Window.onMetricsChanged].
  void onMetricsChanged() {}
}
