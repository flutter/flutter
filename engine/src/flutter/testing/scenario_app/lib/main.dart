// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'src/animated_color_square.dart';
import 'src/scenario.dart';

Map<String, Scenario> _scenarios = <String, Scenario>{
  'animated_color_square': AnimatedColorSquareScenario(window),
};

Scenario _currentScenario = _scenarios['animated_color_square'];

void main() {
  window
    ..onPlatformMessage = _handlePlatformMessage
    ..onBeginFrame = _onBeginFrame
    ..onDrawFrame = _onDrawFrame
    ..onMetricsChanged = _onMetricsChanged
    ..scheduleFrame();
  final ByteData data = ByteData(1);
  data.setUint8(0, 1);
  window.sendPlatformMessage('scenario_status', data, null);
}

void _handlePlatformMessage(String name, ByteData data, PlatformMessageResponseCallback callback) {
  if (name == 'set_scenario' && data != null) {
    final String scenarioName = utf8.decode(data.buffer.asUint8List());
    final Scenario candidateScenario = _scenarios[scenarioName];
    if (candidateScenario != null) {
      _currentScenario = candidateScenario;
      window.scheduleFrame();
    }
    if (callback != null) {
      final ByteData data = ByteData(1);
      data.setUint8(0, candidateScenario == null ? 0 : 1);
      callback(data);
    }
  }
}

void _onBeginFrame(Duration duration) {
  _currentScenario.onBeginFrame(duration);
}

void _onDrawFrame() {
  _currentScenario.onDrawFrame();
}

void _onMetricsChanged() {
  _currentScenario.onMetricsChanged();
}
