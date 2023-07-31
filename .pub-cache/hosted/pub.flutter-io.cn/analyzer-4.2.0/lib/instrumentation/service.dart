// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/instrumentation/noop_service.dart';
import 'package:analyzer/instrumentation/plugin_data.dart';

/// The interface used by client code to communicate with an instrumentation
/// service of some kind.
abstract class InstrumentationService {
  /// A service which does not log or otherwise record instrumentation.
  static final NULL_SERVICE = NoopInstrumentationService();

  /// Log the fact that an error, described by the given [message], has occurred.
  void logError(String message);

  /// Log that the given non-priority [exception] was thrown, with the given
  /// [stackTrace].
  void logException(
    Object exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]);

  /// Log unstructured text information for debugging purposes.
  void logInfo(String message, [dynamic exception]);

  /// Log that a log entry that was written to the analysis engine's log. The log
  /// entry has the given [level] and [message], and was created at the given
  /// [time].
  void logLogEntry(String level, DateTime time, String message,
      Object exception, StackTrace stackTrace);

  /// Log that a notification has been sent to the client.
  void logNotification(String notification);

  /// Log the fact that an error, described by the given [message], was reported
  /// by the given [plugin].
  void logPluginError(
      PluginData plugin, String code, String message, String stackTrace);

  /// Log that the given non-priority [exception] was thrown, with the given
  /// [stackTrace] by the given [plugin].
  void logPluginException(
      PluginData plugin, Object exception, StackTrace? stackTrace);

  /// Log a notification from the plugin with the given [pluginId].
  void logPluginNotification(String pluginId, String notification);

  /// Log a request to the plugin with the given [pluginId].
  void logPluginRequest(String pluginId, String request);

  /// Log a response from the plugin with the given [pluginId].
  void logPluginResponse(String pluginId, String response);

  /// Log that the given [plugin] took too long to execute the given [request].
  /// This doesn't necessarily imply that there is a problem with the plugin,
  /// only that this particular response was not included in the data returned
  /// to the client.
  void logPluginTimeout(PluginData plugin, String request);

  /// Log that a request has been sent to the client.
  void logRequest(String request);

  /// Log that a response has been sent to the client.
  void logResponse(String response);

  /// Signal that the client has started analysis server.
  /// This method should be invoked exactly one time.
  void logVersion(String uuid, String clientId, String clientVersion,
      String serverVersion, String sdkVersion);

  /// Log that the file system watcher sent an event. The [folderPath] is the
  /// path to the folder containing the changed file, the [filePath] is the path
  /// of the file that changed, and the [changeType] indicates what kind of
  /// change occurred.
  void logWatchEvent(String folderPath, String filePath, String changeType);

  /// Shut down this service.
  Future<void> shutdown();
}

/// The additional attachment to be logged.
class InstrumentationServiceAttachment {
  final String id;
  final String stringValue;

  /// Create a new attachment with the unique [id] and string [value].
  InstrumentationServiceAttachment.string({
    required this.id,
    required String value,
  }) : stringValue = value;
}
