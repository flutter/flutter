// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:usage/usage_io.dart';

import 'base/context.dart';
import 'globals.dart';
import 'runner/version.dart';

// TODO(devoncarew): We'll need to do some work on the user agent in order to
// correctly track usage by operating system (dart-lang/usage/issues/70).

// TODO(devoncarew): We'll want to find a way to send (sanitized) command parameters.

// TODO: replace with the real UA
const String _kFlutterUA = 'UA-00000000-0';

const Duration _kMaxExitDelayDuration = const Duration(milliseconds: 250);

class Usage {
  /// Returns [Usage] active in the current app context.
  static Usage get instance => context[Usage] ?? (context[Usage] = new Usage());

  Usage() {
    _ga = new AnalyticsIO(_kFlutterUA, 'flutter', FlutterVersion.getVersionString());

    // Check if this is the first run. If so, enable analytics. We show opt-out
    // methods (flutter config) the first time the tool is run.
    if (!_ga.hasSetOptIn) {
      _isFirstRun = true;
      _ga.optIn = true;
    }
  }

  bool _isFirstRun = false;

  bool get isFirstRun => _isFirstRun;

  Analytics _ga;

  /// Enable or disable reporting analytics.
  set enable(bool value) {
    _ga.optIn = value;
  }

  void sendCommand(String command) {
    printTrace('usage: $command');
    _ga.sendScreenView(command);
  }

  UsageTimer startTimer(String event) => new UsageTimer._(event, _ga.startTimer(event));

  void sendException(dynamic exception, StackTrace trace) {
    String message = '${exception.runtimeType}; ${sanitizeStacktrace(trace)}';
    printTrace('usage: $message');
    _ga.sendException(message);
  }

  Future<Null> waitForLastPing() {
    // TODO(devoncarew): This may delay tool exit and could cause some analytics
    // events to not be reported. Perhaps we could send the analytics pings
    // out-of-process from flutter_tools?
    return _ga.waitForLastPing(timeout: _kMaxExitDelayDuration);
  }
}

class UsageTimer {
  UsageTimer._(this.event, this._timer);

  final String event;
  final AnalyticsTimer _timer;

  void finish() {
    _timer.finish();
    printTrace('usage: ${_timer.currentElapsedMillis}ms for event \'$event\'');
  }
}
