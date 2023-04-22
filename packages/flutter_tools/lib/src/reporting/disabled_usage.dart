// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'reporting.dart';

class DisabledUsage implements Usage {
  @override
  bool get suppressAnalytics => true;

  @override
  set suppressAnalytics(final bool value) { }

  @override
  bool get enabled => false;

  @override
  set enabled(final bool value) { }

  @override
  String get clientId => '';

  @override
  void sendCommand(final String command, { final CustomDimensions? parameters }) { }

  @override
  void sendEvent(
    final String category,
    final String parameter, {
    final String? label,
    final int? value,
    final CustomDimensions? parameters,
  }) { }

  @override
  void sendTiming(final String category, final String variableName, final Duration duration, { final String? label }) { }

  @override
  void sendException(final dynamic exception) { }

  @override
  Stream<Map<String, dynamic>> get onSend => const Stream<Map<String, dynamic>>.empty();

  @override
  Future<void> ensureAnalyticsSent() => Future<void>.value();

  @override
  void printWelcome() { }
}
