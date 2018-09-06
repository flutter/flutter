// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/logging.dart';

typedef void _RegisterServiceExtensionCallback(
    {@required String name, @required ServiceExtensionCallback callback});

/// Manages [Logger] services.
class LoggingService {
  /// The shared service instance.
  static final LoggingService instance = new LoggingService._();

  LoggingService._();

  /// All the [Logger]s.
  final Map<String, Logger> loggers = <String, Logger>{};

  _RegisterServiceExtensionCallback _registerServiceExtensionCallback;

  final Set<Logger> _subscriptions = new HashSet<Logger>();

  /// Return `true` if the given [logger] has subscriptions.
  bool hasSubscriptions(Logger logger) => _subscriptions.contains(logger);

  /// Called to register service extensions.
  void initServiceExtensions(
      _RegisterServiceExtensionCallback registerServiceExtensionCallback) {
    assert(registerServiceExtensionCallback != null);

    _registerServiceExtensionCallback = registerServiceExtensionCallback;

    _registerServiceExtension(
        name: 'loggers',
        callback: (Map<String, dynamic> parameters) async =>
            <String, dynamic>{'value': _getLoggers()});

    _registerServiceExtension(
        name: 'logger.subscribe',
        callback: (Map<String, Object> parameters) async {
          final String loggerName = parameters['loggerName'];
          if (loggerName != null) {
            LoggingService.instance
                .subscribe(loggerName, parameters['subscribe'] == 'true');
          }
          return <String, dynamic>{};
        });
  }

  /// Subscribe (or unsubscribe) to the given logger stream identified by
  /// [loggerName].
  void subscribe(String loggerName, bool subscribe) {
    final Logger logger = loggers[loggerName];
    if (logger != null) {
      if (subscribe) {
        _subscriptions.add(logger);
      } else {
        _subscriptions.remove(logger);
      }
    } else {
      // TODO(pq): consider reporting.
    }
  }

  Map<String, Map<String, String>> _getLoggers() {
    final Map<String, Map<String, String>> map =
        <String, Map<String, String>>{};
    for (Logger logger in loggers.values.toList()) {
      map[logger.name] = <String, String>{
        'enabled': hasSubscriptions(logger).toString(),
        'description': logger.description,
      };
    }
    return map;
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.logging.name").
  ///
  /// The given callback is called when the extension method is called. The
  /// callback must return a value that can be converted to JSON using
  /// `json.encode()` (see [JsonEncoder]). The return value is stored as a
  /// property named `result` in the JSON. In case of failure, the failure is
  /// reported to the remote caller and is dumped to the logs.
  @protected
  void _registerServiceExtension({
    @required String name,
    @required ServiceExtensionCallback callback,
  }) {
    _registerServiceExtensionCallback(
      name: 'logging.$name',
      callback: callback,
    );
  }
}
