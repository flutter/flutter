// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/instrumentation/logger.dart';
import 'package:analyzer/instrumentation/plugin_data.dart';
import 'package:analyzer/instrumentation/service.dart';

/// A class to adapt an [InstrumentationService] into a log using an [InstrumentationLogger].
class InstrumentationLogAdapter implements InstrumentationService {
  static const String TAG_ERROR = 'Err';
  static const String TAG_EXCEPTION = 'Ex';
  static const String TAG_INFO = 'Info';
  static const String TAG_LOG_ENTRY = 'Log';
  static const String TAG_NOTIFICATION = 'Noti';
  static const String TAG_PLUGIN_ERROR = 'PluginErr';
  static const String TAG_PLUGIN_EXCEPTION = 'PluginEx';
  static const String TAG_PLUGIN_NOTIFICATION = 'PluginNoti';
  static const String TAG_PLUGIN_REQUEST = 'PluginReq';
  static const String TAG_PLUGIN_RESPONSE = 'PluginRes';
  static const String TAG_PLUGIN_TIMEOUT = 'PluginTo';
  static const String TAG_REQUEST = 'Req';
  static const String TAG_RESPONSE = 'Res';
  static const String TAG_VERSION = 'Ver';
  static const String TAG_WATCH_EVENT = 'Watch';

  /// A logger used to log instrumentation in string format.
  final InstrumentationLogger _instrumentationLogger;

  /// Initialize a newly created instrumentation service to communicate with the
  /// given [_instrumentationLogger].
  InstrumentationLogAdapter(this._instrumentationLogger);

  /// The current time, expressed as a decimal encoded number of milliseconds.
  String get _timestamp => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void logError(String message) => _log(TAG_ERROR, message);

  @override
  void logException(
    dynamic exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {
    String message = _toString(exception);
    String trace = _toString(stackTrace);
    _instrumentationLogger.log(_join([TAG_EXCEPTION, message, trace]));
  }

  @override
  void logInfo(String message, [dynamic exception]) =>
      _log(TAG_INFO, message + (exception == null ? "" : exception.toString()));

  @override
  void logLogEntry(String level, DateTime? time, String message,
      Object exception, StackTrace stackTrace) {
    String timeStamp =
        time == null ? 'null' : time.millisecondsSinceEpoch.toString();
    String exceptionText = exception.toString();
    String stackTraceText = stackTrace.toString();
    _instrumentationLogger.log(_join([
      TAG_LOG_ENTRY,
      level,
      timeStamp,
      message,
      exceptionText,
      stackTraceText
    ]));
  }

  @override
  void logNotification(String notification) =>
      _log(TAG_NOTIFICATION, notification);

  @override
  void logPluginError(
      PluginData plugin, String code, String message, String stackTrace) {
    List<String> fields = <String>[TAG_PLUGIN_ERROR, code, message, stackTrace];
    plugin.addToFields(fields);
    _instrumentationLogger.log(_join(fields));
  }

  @override
  void logPluginException(
      PluginData plugin, dynamic exception, StackTrace? stackTrace) {
    List<String> fields = <String>[
      TAG_PLUGIN_EXCEPTION,
      _toString(exception),
      _toString(stackTrace)
    ];
    plugin.addToFields(fields);
    _instrumentationLogger.log(_join(fields));
  }

  @override
  void logPluginNotification(String pluginId, String notification) {
    _instrumentationLogger
        .log(_join([TAG_PLUGIN_NOTIFICATION, notification, pluginId, '', '']));
  }

  @override
  void logPluginRequest(String pluginId, String request) {
    _instrumentationLogger
        .log(_join([TAG_PLUGIN_REQUEST, request, pluginId, '', '']));
  }

  @override
  void logPluginResponse(String pluginId, String response) {
    _instrumentationLogger
        .log(_join([TAG_PLUGIN_RESPONSE, response, pluginId, '', '']));
  }

  @override
  void logPluginTimeout(PluginData plugin, String request) {
    List<String> fields = <String>[TAG_PLUGIN_TIMEOUT, request];
    plugin.addToFields(fields);
    _instrumentationLogger.log(_join(fields));
  }

  @override
  void logRequest(String request) => _log(TAG_REQUEST, request);

  @override
  void logResponse(String response) => _log(TAG_RESPONSE, response);

  @override
  void logVersion(String uuid, String clientId, String clientVersion,
      String serverVersion, String sdkVersion) {
    String normalize(String? value) =>
        value != null && value.isNotEmpty ? value : 'unknown';

    _instrumentationLogger.log(_join([
      TAG_VERSION,
      uuid,
      normalize(clientId),
      normalize(clientVersion),
      serverVersion,
      sdkVersion
    ]));
  }

  @override
  void logWatchEvent(String folderPath, String filePath, String changeType) {
    _instrumentationLogger
        .log(_join([TAG_WATCH_EVENT, folderPath, filePath, changeType]));
  }

  @override
  Future<void> shutdown() async {
    await _instrumentationLogger.shutdown();
  }

  /// Write an escaped version of the given [field] to the given [buffer].
  void _escape(StringBuffer buffer, String field) {
    int index = field.indexOf(':');
    if (index < 0) {
      buffer.write(field);
      return;
    }
    int start = 0;
    while (index >= 0) {
      buffer.write(field.substring(start, index));
      buffer.write('::');
      start = index + 1;
      index = field.indexOf(':', start);
    }
    buffer.write(field.substring(start));
  }

  /// Return the result of joining the values of the given fields, escaping the
  /// separator character by doubling it.
  String _join(List<String> fields) {
    StringBuffer buffer = StringBuffer();
    buffer.write(_timestamp);
    int length = fields.length;
    for (int i = 0; i < length; i++) {
      buffer.write(':');
      _escape(buffer, fields[i]);
    }
    return buffer.toString();
  }

  /// Log the given message with the given tag.
  void _log(String tag, String message) {
    _instrumentationLogger.log(_join([tag, message]));
  }

  /// Convert the given [object] to a string.
  String _toString(Object? object) {
    if (object == null) {
      return 'null';
    }
    return object.toString();
  }
}
