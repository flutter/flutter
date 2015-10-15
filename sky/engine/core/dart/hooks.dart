// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

void _updateWindowMetrics(double devicePixelRatio,
                          double width,
                          double height,
                          double top,
                          double right,
                          double bottom,
                          double left) {
  window
    .._devicePixelRatio = devicePixelRatio
    .._size = new Size(width, height)
    .._padding = new Padding(
      top: top, right: right, bottom: bottom, left: left);
  if (window.onMetricsChanged != null)
    window.onMetricsChanged();
}

void _dispatchEvent(Event event) {
  if (window.onEvent != null)
    window.onEvent(event);
}

void _beginFrame(int microseconds) {
  if (window.onBeginFrame != null)
    window.onBeginFrame(new Duration(microseconds: microseconds));
}
