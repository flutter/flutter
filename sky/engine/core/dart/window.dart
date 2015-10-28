// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

typedef void _VoidCallback();
typedef void _FrameCallback(Duration duration);
typedef void _EventCallback(Event event);

class WindowPadding {
  const WindowPadding._({ this.top, this.right, this.bottom, this.left });

  final double top;
  final double right;
  final double bottom;
  final double left;
}

class Window {
  Window._();

  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;

  Size get size => _size;
  Size _size;

  WindowPadding get padding => _padding;
  WindowPadding _padding;

  _FrameCallback onBeginFrame;
  _EventCallback onEvent;
  _VoidCallback onMetricsChanged;

  void scheduleFrame() native "Window_scheduleFrame";
  void render(Scene scene) native "Window_render";
}

final Window window = new Window._();
