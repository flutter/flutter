// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

typedef void VoidCallback();
typedef void _FrameCallback(Duration duration);
typedef void _EventCallback(String eventType, double timeStamp);
typedef void _PointerPacketCallback(ByteData serializedPacket);

class WindowPadding {
  const WindowPadding._({ this.top, this.right, this.bottom, this.left });

  final double top;
  final double right;
  final double bottom;
  final double left;
}

class Locale {
  Locale(this.languageCode, this.countryCode);

  final String languageCode;
  final String countryCode;

  String toString() => '${languageCode}_$countryCode';
}

class Window {
  Window._();

  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;

  Size get size => _size;
  Size _size;

  WindowPadding get padding => _padding;
  WindowPadding _padding;

  Locale get locale => _locale;
  Locale _locale;

  _FrameCallback onBeginFrame;
  _EventCallback onEvent; // TODO(abarth): Remove.
  _PointerPacketCallback onPointerPacket;
  VoidCallback onMetricsChanged;
  VoidCallback onLocaleChanged;

  String defaultRouteName;
  VoidCallback onPopRoute;

  void scheduleFrame() native "Window_scheduleFrame";
  void render(Scene scene) native "Window_render";
}

final Window window = new Window._();
