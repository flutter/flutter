// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

part of reporting;

class DisabledUsage implements Usage {
  @override
  bool get suppressAnalytics => true;

  @override
  set suppressAnalytics(bool value) { }

  @override
  bool get enabled => false;

  @override
  set enabled(bool value) { }

  @override
  String get clientId => null;

  @override
  void sendCommand(String command, { Map<String, String> parameters }) { }

  @override
  void sendEvent(
    String category,
    String parameter, {
    String label,
    int value,
    Map<String, String> parameters,
  }) { }

  @override
  void sendTiming(String category, String variableName, Duration duration, { String label }) { }

  @override
  void sendException(dynamic exception) { }

  @override
  Stream<Map<String, dynamic>> get onSend => null;

  @override
  Future<void> ensureAnalyticsSent() => Future<void>.value();

  @override
  void printWelcome() { }
}
