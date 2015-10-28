// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

final Tracing tracing = new Tracing();

class View {
  View._();

  double get devicePixelRatio => window.devicePixelRatio;

  double get paddingTop => window.padding.top;
  double get paddingRight => window.padding.right;
  double get paddingBottom => window.padding.bottom;
  double get paddingLeft => window.padding.left;

  double get width => window.size.width;
  double get height => window.size.height;

  Scene get scene => null;
  void set scene(Scene value) {
    window.render(value);
  }

  void setEventCallback(EventCallback callback) {
    window.onEvent = callback;
  }

  void setMetricsChangedCallback(VoidCallback callback) {
    window.onMetricsChanged = callback;
  }

  void setFrameCallback(FrameCallback callback) {
    window.onBeginFrame = (Duration duration) {
      callback(duration.inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND);
    };
  }

  void scheduleFrame() => window.scheduleFrame();
}

final View view = new View._();

typedef EventListener(Event event);
