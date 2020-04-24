// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';
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
  void onBeginFrame(Duration duration) {}

  /// Called by the program when the microtasks from [onBeginFrame] have been
  /// flushed.
  ///
  /// See [Window.onDrawFrame] for more details.
  void onDrawFrame() {}

  /// Called by the program when the window metrics have changed.
  ///
  /// See [Window.onMetricsChanged].
  void onMetricsChanged() {}

  /// Called by the program when a pointer event is received.
  ///
  /// See [Window.onPointerDataPacket].
  void onPointerDataPacket(PointerDataPacket packet) {}

  /// Called by the program when an engine side platform channel message is
  /// received.
  ///
  /// See [Window.onPlatformMessage].
  void onPlatformMessage(
    String name,
    ByteData data,
    PlatformMessageResponseCallback callback,
  ) {}
}
