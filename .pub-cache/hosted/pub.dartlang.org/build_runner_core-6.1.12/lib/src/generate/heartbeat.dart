// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../logging/human_readable_duration.dart';

var _logger = Logger('Heartbeat');

/// Base class for a heartbeat implementation.
///
/// Once [start]ed, if [waitDuration] passes between calls to [ping], then
/// [onTimeout] will be invoked with the duration.
abstract class Heartbeat {
  Stopwatch _intervalWatch;
  Timer _timer;

  /// The interval at which to check if [waitDuration] has passed.
  final Duration checkInterval;

  /// The amount of time between heartbeats.
  final Duration waitDuration;

  Heartbeat({Duration checkInterval, Duration waitDuration})
      : checkInterval = checkInterval ?? const Duration(milliseconds: 100),
        waitDuration = waitDuration ?? const Duration(seconds: 5);

  /// Invoked if [waitDuration] time has elapsed since the last call to [ping].
  void onTimeout(Duration elapsed);

  /// Resets the internal timers. If more than [waitDuration] elapses without
  /// this method being called, then [onTimeout] will be invoked with the
  /// duration since the last ping.
  void ping() {
    _intervalWatch.reset();
  }

  /// Starts this heartbeat logger, must not already be started.
  ///
  /// This method can be overridden to add additional logic for handling calls
  /// to [ping], but you must call `super.start()`.
  void start() {
    if (_intervalWatch != null || _timer != null) {
      throw StateError('HeartbeatLogger already started');
    }
    _intervalWatch = Stopwatch()..start();
    ping();
    _timer = Timer.periodic(checkInterval, _checkDuration);
  }

  /// Stops this heartbeat logger, must already be started.
  ///
  /// This method can be overridden to add additional logic for cleanup
  /// purposes, but you must call `super.stop()`.
  void stop() {
    if (_intervalWatch == null || _timer == null) {
      throw StateError('HeartbeatLogger was never started');
    }
    _intervalWatch.stop();
    _intervalWatch = null;
    _timer.cancel();
    _timer = null;
  }

  void _checkDuration(void _) {
    if (_intervalWatch.elapsed < waitDuration) return;
    onTimeout(_intervalWatch.elapsed);
    ping();
  }
}

/// Watches [Logger.root] and if there are no logs for [waitDuration] then it
/// will log a heartbeat message with the current elapsed time since [start] was
/// originally invoked.
class HeartbeatLogger extends Heartbeat {
  StreamSubscription<LogRecord> _listener;
  Stopwatch _totalWatch;

  /// Will be invoked with each original log message and the returned value will
  /// be logged instead.
  final String Function(String original) transformLog;

  HeartbeatLogger(
      {Duration checkInterval, Duration waitDuration, this.transformLog})
      : super(checkInterval: checkInterval, waitDuration: waitDuration);

  /// Start listening to logs.
  @override
  void start() {
    _totalWatch = Stopwatch()..start();
    super.start();
    _listener = Logger.root.onRecord.listen((_) => ping());
  }

  /// Stops listenting to the logger;
  @override
  void stop() {
    super.stop();
    _listener.cancel();
    _listener = null;
    _totalWatch.stop();
    _totalWatch = null;
  }

  /// Logs a heartbeat message if we reach the timeout.
  @override
  void onTimeout(void _) {
    var formattedTime = humanReadable(_totalWatch.elapsed);
    var message = '$formattedTime elapsed';
    if (transformLog != null) {
      message = transformLog(message);
    }
    _logger.info(message);
  }
}

class HungActionsHeartbeat extends Heartbeat {
  /// Returns a description of pending actions
  final String Function() listActions;

  HungActionsHeartbeat(this.listActions,
      {Duration checkInterval, Duration waitDuration})
      : super(
            checkInterval: checkInterval,
            waitDuration: waitDuration ?? Duration(seconds: 15));

  @override
  void onTimeout(Duration elapsed) {
    var formattedTime = humanReadable(elapsed);
    var message = 'No actions completed for $formattedTime, '
        'waiting on:\n${listActions()}';
    _logger.warning(message);
  }
}
