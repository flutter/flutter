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
    .._padding = new WindowPadding._(
      top: top, right: right, bottom: bottom, left: left);
  if (window.onMetricsChanged != null)
    window.onMetricsChanged();
}

void _updateLocale(String languageCode, String countryCode) {
  window._locale = new Locale(languageCode, countryCode);
  if (window.onLocaleChanged != null)
    window.onLocaleChanged();
}

void _pushRoute(String route) {
  assert(window._defaultRouteName == null);
  window._defaultRouteName = route;
  // TODO(abarth): If we ever start calling _pushRoute other than before main,
  // we should add a change notification callback.
}

void _popRoute() {
  if (window.onPopRoute != null)
    window.onPopRoute();
}

void _dispatchPointerPacket(ByteData serializedPacket) {
  if (window.onPointerPacket != null)
    window.onPointerPacket(serializedPacket);
}

void _beginFrame(int microseconds) {
  if (window.onBeginFrame != null)
    window.onBeginFrame(new Duration(microseconds: microseconds));
}

void _onAppLifecycleStateChanged(int state) {
  if (window.onAppLifecycleStateChanged != null)
    window.onAppLifecycleStateChanged(AppLifecycleState.values[state]);
}
