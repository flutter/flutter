// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:usage/src/usage_impl_io.dart'; // ignore: implementation_imports
import 'package:usage/usage.dart';

import 'base/context.dart';
import 'base/utils.dart';
import 'globals.dart';
import 'version.dart';

// TODO(devoncarew): We'll want to find a way to send (sanitized) command parameters.

const String _kFlutterUA = 'UA-67589403-6';

Usage get flutterUsage => Usage.instance;

class Usage {
  /// Create a new Usage instance; [versionOverride] is used for testing.
  Usage({ String settingsName: 'flutter', String versionOverride }) {
    String version = versionOverride ?? FlutterVersion.getVersionString(whitelistBranchName: true);
    _analytics = new AnalyticsIO(_kFlutterUA, settingsName, version);

    bool runningOnCI = false;

    // Many CI systems don't do a full git checkout.
    if (version.endsWith('/unknown'))
      runningOnCI = true;

    // Check for common CI systems.
    if (isRunningOnBot)
      runningOnCI = true;

    // If we think we're running on a CI system, default to not sending analytics.
    _analytics.analyticsOpt = runningOnCI ? AnalyticsOpt.optIn : AnalyticsOpt.optOut;
  }

  /// Returns [Usage] active in the current app context.
  static Usage get instance => context[Usage];

  Analytics _analytics;

  bool _printedUsage = false;
  bool _suppressAnalytics = false;

  bool get isFirstRun => _analytics.firstRun;

  bool get enabled => _analytics.enabled;

  bool get suppressAnalytics => _suppressAnalytics || _analytics.firstRun;

  /// Suppress analytics for this session.
  set suppressAnalytics(bool value) {
    _suppressAnalytics = value;
  }

  /// Enable or disable reporting analytics.
  set enabled(bool value) {
    _analytics.enabled = value;
  }

  void sendCommand(String command) {
    if (!suppressAnalytics)
      _analytics.sendScreenView(command);
  }

  void sendEvent(String category, String parameter) {
    if (!suppressAnalytics)
      _analytics.sendEvent(category, parameter);
  }

  void sendTiming(String category, String variableName, Duration duration) {
    _analytics.sendTiming(variableName, duration.inMilliseconds, category: category);
  }

  UsageTimer startTimer(String event) {
    if (suppressAnalytics)
      return new _MockUsageTimer();
    else
      return new UsageTimer._(event, _analytics.startTimer(event, category: 'flutter'));
  }

  void sendException(dynamic exception, StackTrace trace) {
    if (!suppressAnalytics)
      _analytics.sendException(_shorten('${exception.runtimeType}; ${sanitizeStacktrace(trace)}'));
  }

  /// Shorten the exception information that is sent to Google Analytics
  /// to get more information because Google Analytics truncates this to 100 char.
  String _shorten(String text) {
    /// TODO(danrubel) Gather more information about https://github.com/flutter/flutter/issues/5137
    /// remove this code once that issue is resolved.
    const String prefix = 'FileSystemException; dart:io/file_impl.dart 807 _RandomAccessFile.writeFromSync dart:io/stdio.dart ';
    if (text.startsWith(prefix))
      text = 'FSE:807 ' + text.substring(prefix.length);
    return text;
  }

  /// Fires whenever analytics data is sent over the network; public for testing.
  Stream<Map<String, dynamic>> get onSend => _analytics.onSend;

  /// Returns when the last analytics event has been sent, or after a fixed
  /// (short) delay, whichever is less.
  Future<Null> ensureAnalyticsSent() async {
    // TODO(devoncarew): This may delay tool exit and could cause some analytics
    // events to not be reported. Perhaps we could send the analytics pings
    // out-of-process from flutter_tools?
    await _analytics.waitForLastPing(timeout: new Duration(milliseconds: 250));
  }

  void printUsage() {
    if (_printedUsage)
      return;
    _printedUsage = true;

    printStatus('');
    printStatus('''
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║                 Welcome to Flutter! - https://flutter.io                   ║
  ║                                                                            ║
  ║ The Flutter tool anonymously reports feature usage statistics and basic    ║
  ║ crash reports to Google in order to help Google contribute improvements to ║
  ║ Flutter over time. See Google's privacy policy:                            ║
  ║ https://www.google.com/intl/en/policies/privacy/                           ║
  ║                                                                            ║
  ║ Use "flutter config --no-analytics" to disable analytics reporting.        ║
  ╚════════════════════════════════════════════════════════════════════════════╝
  ''', emphasis: true);
  }
}

class UsageTimer {
  UsageTimer._(this.event, this._timer);

  final String event;
  final AnalyticsTimer _timer;

  void finish() {
    _timer.finish();
  }
}

class _MockUsageTimer implements UsageTimer {
  @override
  String event;
  @override
  AnalyticsTimer _timer;

  @override
  void finish() { }
}
