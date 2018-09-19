// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer' as developer;

/// A callback that, when evaluated, returns a log message.  Log messages must
/// be encodable as JSON using `json.encode()`.
typedef DebugLogMessageCallback = Object Function();

/// Logs a message conditionally if the given identifying event [channel] is
/// enabled (if `debugShouldLogEvent(channel)` is true).
///
/// Messages are obtained by evaluating [messageCallback] and must be encodable
/// as JSON strings using `json.encode()`. In the event that logging is not
/// enabled for the given [channel], [messageCallback] will not be evaluated.
/// The cost of logging calls can be further mitigated at call sites by invoking
/// them in a function that is only evaluated in profile or debug modes. For
/// example,
///
/// ```dart
/// profile(() {
///   debugLogEvent(logGestures, () => <String, int> {
///    'x' : x,
///    'y' : y,
///    'z' : z,
///   });
/// });
///```
///
/// ignores logging entirely in release mode and no performance penalty is paid.
///
/// Logging for a given event channel can be enabled programmatically via
/// [debugEnableLogging] or using a VM service call.
///
void debugLogEvent(
    LoggingChannel channel, DebugLogMessageCallback messageCallback) {
  assert(channel != null);
  if (!debugShouldLogEvent(channel)) {
    return;
  }

  assert(messageCallback != null);
  final Object message = messageCallback();
  assert(message != null);

  developer.log(json.encode(message), name: channel.name);
}

final Set<LoggingChannel> _enabledEventChannels = Set<LoggingChannel>();

/// All logging event channels.
List<LoggingChannel> get debugLogEventChannels =>
    LoggingChannel._channels.values.toList(growable: false);

/// The set of all enabled logging event channels.
Set<LoggingChannel> get enabledDebugLogEventChannels => _enabledEventChannels;

/// Identifies a logging channel.
class LoggingChannel {
  static final Map<String, LoggingChannel> _channels =
      <String, LoggingChannel>{};

  /// A uniquely identifying stream name.
  final String name;

  /// An optional description, suitable for presentation by tools.
  final String description;

  /// Singleton constructor. Calling `LoggingChannel(name)` returns the same
  /// actual instance whenever it is called with the same string name.
  factory LoggingChannel(String name, {String description}) =>
      _getOrRegisterChannel(name, description ?? '');

  const LoggingChannel._(this.name, this.description);

  static LoggingChannel _getOrRegisterChannel(String name, String description) {
    assert(name != null);
    return _channels.putIfAbsent(
        name, () => LoggingChannel._(name, description));
  }
}

/// Get the logging channel registered to this name, or null if none exists.
LoggingChannel getRegisteredChannel(String name) =>
    LoggingChannel._channels[name];

/// Enable (or disable) logging for all events on the given [channel].
void debugEnableLogging(LoggingChannel channel, [bool enable = true]) {
  assert(channel != null);
  if (enable) {
    _enabledEventChannels.add(channel);
  } else {
    _enabledEventChannels.remove(channel);
  }
}

/// Returns true if events on the given event [channel] should be logged.
bool debugShouldLogEvent(LoggingChannel channel) {
  assert(channel != null);
  return _enabledEventChannels.contains(channel);
}
