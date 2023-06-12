// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/instrumentation/plugin_data.dart';
import 'package:analyzer/instrumentation/service.dart';

/// An [InstrumentationService] that sends messages to multiple services.
class MulticastInstrumentationService implements InstrumentationService {
  final List<InstrumentationService> _services;

  MulticastInstrumentationService(this._services);

  @override
  void logError(String message) {
    _services.forEach((s) => s.logError(message));
  }

  @override
  void logException(
    Object exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {
    _services
        .forEach((s) => s.logException(exception, stackTrace, attachments));
  }

  @override
  void logInfo(String message, [dynamic exception]) {
    _services.forEach((s) => s.logInfo(message, exception));
  }

  @override
  void logLogEntry(String level, DateTime time, String message,
      Object exception, StackTrace stackTrace) {
    _services.forEach(
        (s) => s.logLogEntry(level, time, message, exception, stackTrace));
  }

  @override
  void logNotification(String notification) {
    _services.forEach((s) => s.logNotification(notification));
  }

  @override
  void logPluginError(
      PluginData plugin, String code, String message, String stackTrace) {
    _services
        .forEach((s) => s.logPluginError(plugin, code, message, stackTrace));
  }

  @override
  void logPluginException(
      PluginData plugin, Object exception, StackTrace? stackTrace) {
    _services
        .forEach((s) => s.logPluginException(plugin, exception, stackTrace));
  }

  @override
  void logPluginNotification(String pluginId, String notification) {
    _services.forEach((s) => s.logPluginNotification(pluginId, notification));
  }

  @override
  void logPluginRequest(String pluginId, String request) {
    _services.forEach((s) => s.logPluginRequest(pluginId, request));
  }

  @override
  void logPluginResponse(String pluginId, String response) {
    _services.forEach((s) => s.logPluginResponse(pluginId, response));
  }

  @override
  void logPluginTimeout(PluginData plugin, String request) {
    _services.forEach((s) => s.logPluginTimeout(plugin, request));
  }

  @override
  void logRequest(String request) {
    _services.forEach((s) => s.logRequest(request));
  }

  @override
  void logResponse(String response) {
    _services.forEach((s) => s.logResponse(response));
  }

  @override
  void logVersion(String uuid, String clientId, String clientVersion,
      String serverVersion, String sdkVersion) {
    _services.forEach((s) =>
        s.logVersion(uuid, clientId, clientVersion, serverVersion, sdkVersion));
  }

  @override
  void logWatchEvent(String folderPath, String filePath, String changeType) {
    _services.forEach((s) => s.logWatchEvent(folderPath, filePath, changeType));
  }

  @override
  Future<void> shutdown() {
    return Future.wait(_services.map((s) => s.shutdown()));
  }
}
