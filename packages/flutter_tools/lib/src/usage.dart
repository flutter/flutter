// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:usage/usage_io.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/utils.dart';
import 'globals.dart';
import 'version.dart';

const String _kFlutterUA = 'UA-67589403-6';
const String kEventReloadReasonParameterName = 'cd5';
const String kEventReloadFinalLibraryCount = 'cd6';
const String kEventReloadSyncedLibraryCount = 'cd7';
const String kEventReloadSyncedClassesCount = 'cd8';
const String kEventReloadSyncedProceduresCount = 'cd9';
const String kEventReloadSyncedBytes = 'cd10';
const String kEventReloadInvalidatedSourcesCount = 'cd11';
const String kEventReloadTransferTimeInMs = 'cd12';
const String kEventReloadOverallTimeInMs = 'cd13';

Usage get flutterUsage => Usage.instance;

class Usage {
  /// Create a new Usage instance; [versionOverride] and [configDirOverride] are
  /// used for testing.
  Usage({ String settingsName = 'flutter', String versionOverride, String configDirOverride}) {
    final FlutterVersion flutterVersion = FlutterVersion.instance;
    final String version = versionOverride ?? flutterVersion.getVersionString(redactUnknownBranches: true);
    _analytics = AnalyticsIO(_kFlutterUA, settingsName, version,
        documentDirectory: configDirOverride != null ? fs.directory(configDirOverride) : null);

    // Report a more detailed OS version string than package:usage does by default.
    _analytics.setSessionValue('cd1', os.name);
    // Send the branch name as the "channel".
    _analytics.setSessionValue('cd2', flutterVersion.getBranchName(redactUnknownBranches: true));
    // Record the host as the application installer ID - the context that flutter_tools is running in.
    if (platform.environment.containsKey('FLUTTER_HOST')) {
      _analytics.setSessionValue('aiid', platform.environment['FLUTTER_HOST']);
    }
    _analytics.analyticsOpt = AnalyticsOpt.optOut;

    // Many CI systems don't do a full git checkout.
    if (version.endsWith('/unknown') || isRunningOnBot) {
      // If we think we're running on a CI system, suppress sending analytics.
      suppressAnalytics = true;
    }
  }

  /// Returns [Usage] active in the current app context.
  static Usage get instance => context[Usage];

  Analytics _analytics;

  bool _printedWelcome = false;
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

  /// A stable randomly generated UUID used to deduplicate multiple identical
  /// reports coming from the same computer.
  String get clientId => _analytics.clientId;

  void sendCommand(String command, { Map<String, String> parameters }) {
    if (suppressAnalytics)
      return;

    parameters ??= const <String, String>{};

    _analytics.sendScreenView(command, parameters: parameters);
  }

  void sendEvent(
    String category,
    String parameter, {
    Map<String, String> parameters,
  }) {
    if (suppressAnalytics)
      return;

    parameters ??= const <String, String>{};

    _analytics.sendEvent(category, parameter, parameters: parameters);
  }

  void sendTiming(
    String category,
    String variableName,
    Duration duration, {
    String label,
  }) {
    if (!suppressAnalytics) {
      _analytics.sendTiming(
        variableName,
        duration.inMilliseconds,
        category: category,
        label: label,
      );
    }
  }

  void sendException(dynamic exception, StackTrace trace) {
    if (!suppressAnalytics)
      _analytics.sendException('${exception.runtimeType}\n${sanitizeStacktrace(trace)}');
  }

  /// Fires whenever analytics data is sent over the network.
  @visibleForTesting
  Stream<Map<String, dynamic>> get onSend => _analytics.onSend;

  /// Returns when the last analytics event has been sent, or after a fixed
  /// (short) delay, whichever is less.
  Future<void> ensureAnalyticsSent() async {
    // TODO(devoncarew): This may delay tool exit and could cause some analytics
    // events to not be reported. Perhaps we could send the analytics pings
    // out-of-process from flutter_tools?
    await _analytics.waitForLastPing(timeout: const Duration(milliseconds: 250));
  }

  void printWelcome() {
    // This gets called if it's the first run by the selected command, if any,
    // and on exit, in case there was no command.
    if (_printedWelcome)
      return;
    _printedWelcome = true;

    printStatus('');
    printStatus('''
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║                 Welcome to Flutter! - https://flutter.dev                  ║
  ║                                                                            ║
  ║ The Flutter tool anonymously reports feature usage statistics and crash    ║
  ║ reports to Google in order to help Google contribute improvements to       ║
  ║ Flutter over time.                                                         ║
  ║                                                                            ║
  ║ Read about data we send with crash reports:                                ║
  ║ https://github.com/flutter/flutter/wiki/Flutter-CLI-crash-reporting        ║
  ║                                                                            ║
  ║ See Google's privacy policy:                                               ║
  ║ https://www.google.com/intl/en/policies/privacy/                           ║
  ║                                                                            ║
  ║ Use "flutter config --no-analytics" to disable analytics and crash         ║
  ║ reporting.                                                                 ║
  ╚════════════════════════════════════════════════════════════════════════════╝
  ''', emphasis: true);
  }
}
