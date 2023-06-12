// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/instrumentation/plugin_data.dart';
import 'package:analyzer/instrumentation/service.dart';

/// An implementation of [InstrumentationService] which noops instead of saving
/// instrumentation logs.
class NoopInstrumentationService implements InstrumentationService {
  @override
  void logError(String message) {}

  @override
  void logException(
    Object exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {}

  @override
  void logInfo(String message, [dynamic exception]) {}

  @override
  void logLogEntry(String level, DateTime time, String message,
      Object exception, StackTrace stackTrace) {}

  @override
  void logNotification(String notification) {}

  @override
  void logPluginError(
      PluginData plugin, String code, String message, String stackTrace) {}

  @override
  void logPluginException(
      PluginData plugin, Object exception, StackTrace? stackTrace) {}

  @override
  void logPluginNotification(String pluginId, String notification) {}

  @override
  void logPluginRequest(String pluginId, String request) {}

  @override
  void logPluginResponse(String pluginId, String response) {}

  @override
  void logPluginTimeout(PluginData plugin, String request) {}

  @override
  void logRequest(String request) {}

  @override
  void logResponse(String response) {}

  @override
  void logVersion(String uuid, String clientId, String clientVersion,
      String serverVersion, String sdkVersion) {}

  @override
  void logWatchEvent(String folderPath, String filePath, String changeType) {}

  @override
  Future<void> shutdown() async {}
}
