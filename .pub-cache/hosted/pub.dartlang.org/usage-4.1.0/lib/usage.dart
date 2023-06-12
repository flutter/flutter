// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// `usage` is a wrapper around Google Analytics for both command-line apps
/// and web apps.
///
/// In order to use this library as a web app, import the `analytics_html.dart`
/// library and instantiate the [AnalyticsHtml] class.
///
/// In order to use this library as a command-line app, import the
/// `analytics_io.dart` library and instantiate the [AnalyticsIO] class.
///
/// For both classes, you need to provide a Google Analytics tracking ID, the
/// application name, and the application version.
///
/// Your application should provide an opt-in option for the user. If they
/// opt-in, set the [optIn] field to `true`. This setting will persist across
/// sessions automatically.
///
/// For more information, please see the Google Analytics Measurement Protocol
/// [Policy](https://developers.google.com/analytics/devguides/collection/protocol/policy).
library usage;

import 'dart:async';

// Matches file:/, non-ws, /, non-ws, .dart
final RegExp _pathRegex = RegExp(r'file:/\S+/(\S+\.dart)');

// Match multiple tabs or spaces.
final RegExp _tabOrSpaceRegex = RegExp(r'[\t ]+');

/// An interface to a Google Analytics session.
///
/// [AnalyticsHtml] and [AnalyticsIO] are concrete implementations of this
/// interface. [AnalyticsMock] can be used for testing or for some variants of
/// an opt-in workflow.
///
/// The analytics information is sent on a best-effort basis. So, failures to
/// send the GA information will not result in errors from the asynchronous
/// `send` methods.
abstract class Analytics {
  /// Tracking ID / Property ID.
  String get trackingId;

  /// The application name.
  String? get applicationName;

  /// The application version.
  String? get applicationVersion;

  /// Is this the first time the tool has run?
  bool get firstRun;

  /// Whether the [Analytics] instance is configured in an opt-in or opt-out
  /// manner.
  AnalyticsOpt analyticsOpt = AnalyticsOpt.optOut;

  /// Will analytics data be sent.
  bool get enabled;

  /// Enable or disable sending of analytics data.
  set enabled(bool value);

  /// Anonymous client ID in UUID v4 format.
  ///
  /// The value is randomly-generated and should be reasonably stable for the
  /// computer sending analytics data.
  String get clientId;

  /// Sends a screen view hit to Google Analytics.
  ///
  /// [parameters] can be any analytics key/value pair. Useful
  /// for custom dimensions, etc.
  Future sendScreenView(String viewName, {Map<String, String>? parameters});

  /// Sends an Event hit to Google Analytics. [label] specifies the event label.
  /// [value] specifies the event value. Values must be non-negative.
  ///
  /// [parameters] can be any analytics key/value pair. Useful
  /// for custom dimensions, etc.
  Future sendEvent(String category, String action,
      {String? label, int? value, Map<String, String>? parameters});

  /// Sends a Social hit to Google Analytics.
  ///
  /// [network] specifies the social network, for example Facebook or Google
  /// Plus. [action] specifies the social interaction action. For example on
  /// Google Plus when a user clicks the +1 button, the social action is 'plus'.
  /// [target] specifies the target of a
  /// social interaction. This value is typically a URL but can be any text.
  Future sendSocial(String network, String action, String target);

  /// Sends a Timing hit to Google Analytics. [variableName] specifies the
  /// variable name of the timing. [time] specifies the user timing value (in
  /// milliseconds). [category] specifies the category of the timing. [label]
  /// specifies the label of the timing.
  Future sendTiming(String variableName, int time,
      {String? category, String? label});

  /// Start a timer. The time won't be calculated, and the analytics information
  /// sent, until the [AnalyticsTimer.finish] method is called.
  AnalyticsTimer startTimer(String variableName,
      {String? category, String? label});

  /// In order to avoid sending any personally identifying information, the
  /// [description] field must not contain the exception message. In addition,
  /// only the first 100 chars of the description will be sent.
  Future sendException(String description, {bool? fatal});

  /// Gets a session variable value.
  dynamic getSessionValue(String param);

  /// Sets a session variable value. The value is persistent for the life of the
  /// [Analytics] instance. This variable will be sent in with every analytics
  /// hit. A list of valid variable names can be found here:
  /// https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters.
  void setSessionValue(String param, dynamic value);

  /// Fires events when the usage library sends any data over the network. This
  /// will not fire if analytics has been disabled or if the throttling
  /// algorithm has been engaged.
  ///
  /// This method is public to allow library clients to more easily test their
  /// analytics implementations.
  Stream<Map<String, dynamic>> get onSend;

  /// Wait for all of the outstanding analytics pings to complete. The returned
  /// `Future` will always complete without errors. You can pass in an optional
  /// `Duration` to specify to only wait for a certain amount of time.
  ///
  /// This method is particularly useful for command-line clients. Outstanding
  /// I/O requests will cause the VM to delay terminating the process.
  /// Generally, users won't want their CLI app to pause at the end of the
  /// process waiting for Google analytics requests to complete. This method
  /// allows CLI apps to delay for a short time waiting for GA requests to
  /// complete, and then do something like call `dart:io`'s `exit()` explicitly
  /// themselves (or the [close] method below).
  Future waitForLastPing({Duration? timeout});

  /// Free any used resources.
  ///
  /// The [Analytics] instance should not be used after this call.
  void close();
}

enum AnalyticsOpt {
  /// Users must opt-in before any analytics data is sent.
  optIn,

  /// Users must opt-out for analytics data to not be sent.
  optOut
}

/// An object, returned by [Analytics.startTimer], that is used to measure an
/// asynchronous process.
class AnalyticsTimer {
  final Analytics analytics;
  final String variableName;
  final String? category;
  final String? label;

  late final int _startMillis;
  int? _endMillis;

  AnalyticsTimer(this.analytics, this.variableName,
      {this.category, this.label}) {
    _startMillis = DateTime.now().millisecondsSinceEpoch;
  }

  int get currentElapsedMillis {
    if (_endMillis == null) {
      return DateTime.now().millisecondsSinceEpoch - _startMillis;
    } else {
      return _endMillis! - _startMillis;
    }
  }

  /// Finish the timer, calculate the elapsed time, and send the information to
  /// analytics. Once this is called, any future invocations are no-ops.
  Future finish() {
    if (_endMillis != null) return Future.value();

    _endMillis = DateTime.now().millisecondsSinceEpoch;
    return analytics.sendTiming(variableName, currentElapsedMillis,
        category: category, label: label);
  }
}

/// A no-op implementation of the [Analytics] class. This can be used as a
/// stand-in for that will never ping the GA server, or as a mock in test code.
class AnalyticsMock implements Analytics {
  @override
  String get trackingId => 'UA-0';
  @override
  String get applicationName => 'mock-app';
  @override
  String get applicationVersion => '1.0.0';

  final bool logCalls;

  /// Events are never added to this controller for the mock implementation.
  final StreamController<Map<String, dynamic>> _sendController =
      StreamController.broadcast();

  /// Create a new [AnalyticsMock]. If [logCalls] is true, all calls will be
  /// logged to stdout.
  AnalyticsMock([this.logCalls = false]);

  @override
  bool get firstRun => false;

  @override
  AnalyticsOpt analyticsOpt = AnalyticsOpt.optOut;

  @override
  bool enabled = true;

  @override
  String get clientId => '00000000-0000-4000-0000-000000000000';

  @override
  Future sendScreenView(String viewName, {Map<String, String>? parameters}) {
    parameters ??= <String, String>{};
    parameters['viewName'] = viewName;
    return _log('screenView', parameters);
  }

  @override
  Future sendEvent(String category, String action,
      {String? label, int? value, Map<String, String>? parameters}) {
    parameters ??= <String, String>{};
    return _log(
        'event',
        {'category': category, 'action': action, 'label': label, 'value': value}
          ..addAll(parameters));
  }

  @override
  Future sendSocial(String network, String action, String target) =>
      _log('social', {'network': network, 'action': action, 'target': target});

  @override
  Future sendTiming(String variableName, int time,
      {String? category, String? label}) {
    return _log('timing', {
      'variableName': variableName,
      'time': time,
      'category': category,
      'label': label
    });
  }

  @override
  AnalyticsTimer startTimer(String variableName,
      {String? category, String? label}) {
    return AnalyticsTimer(this, variableName, category: category, label: label);
  }

  @override
  Future sendException(String description, {bool? fatal}) =>
      _log('exception', {'description': description, 'fatal': fatal});

  @override
  dynamic getSessionValue(String param) => null;

  @override
  void setSessionValue(String param, dynamic value) {}

  @override
  Stream<Map<String, dynamic>> get onSend => _sendController.stream;

  @override
  Future waitForLastPing({Duration? timeout}) => Future.value();

  @override
  void close() {}

  Future _log(String hitType, Map m) {
    if (logCalls) {
      print('analytics: $hitType $m');
    }

    return Future.value();
  }
}

/// Sanitize a stacktrace. This will shorten file paths in order to remove any
/// PII that may be contained in the full file path. For example, this will
/// shorten `file:///Users/foobar/tmp/error.dart` to `error.dart`.
///
/// If [shorten] is `true`, this method will also attempt to compress the text
/// of the stacktrace. GA has a 100 char limit on the text that can be sent for
/// an exception. This will try and make those first 100 chars contain
/// information useful to debugging the issue.
String sanitizeStacktrace(dynamic st, {bool shorten = true}) {
  var str = '$st';

  Iterable<Match> iter = _pathRegex.allMatches(str);
  iter = iter.toList().reversed;

  for (var match in iter) {
    var replacement = match.group(1)!;
    str =
        str.substring(0, match.start) + replacement + str.substring(match.end);
  }

  if (shorten) {
    // Shorten the stacktrace up a bit.
    str = str.replaceAll(_tabOrSpaceRegex, ' ');
  }

  return str;
}
