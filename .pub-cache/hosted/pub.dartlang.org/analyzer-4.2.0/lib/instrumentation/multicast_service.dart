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
    for (var service in _services) {
      service.logError(message);
    }
  }

  @override
  void logException(
    Object exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {
    for (var service in _services) {
      service.logException(exception, stackTrace, attachments);
    }
  }

  @override
  void logInfo(String message, [dynamic exception]) {
    for (var service in _services) {
      service.logInfo(message, exception);
    }
  }

  @override
  void logLogEntry(String level, DateTime time, String message,
      Object exception, StackTrace stackTrace) {
    for (var service in _services) {
      service.logLogEntry(level, time, message, exception, stackTrace);
    }
  }

  @override
  void logNotification(String notification) {
    for (var service in _services) {
      service.logNotification(notification);
    }
  }

  @override
  void logPluginError(
      PluginData plugin, String code, String message, String stackTrace) {
    for (var service in _services) {
      service.logPluginError(plugin, code, message, stackTrace);
    }
  }

  @override
  void logPluginException(
      PluginData plugin, Object exception, StackTrace? stackTrace) {
    for (var service in _services) {
      service.logPluginException(plugin, exception, stackTrace);
    }
  }

  @override
  void logPluginNotification(String pluginId, String notification) {
    for (var service in _services) {
      service.logPluginNotification(pluginId, notification);
    }
  }

  @override
  void logPluginRequest(String pluginId, String request) {
    for (var service in _services) {
      service.logPluginRequest(pluginId, request);
    }
  }

  @override
  void logPluginResponse(String pluginId, String response) {
    for (var service in _services) {
      service.logPluginResponse(pluginId, response);
    }
  }

  @override
  void logPluginTimeout(PluginData plugin, String request) {
    for (var service in _services) {
      service.logPluginTimeout(plugin, request);
    }
  }

  @override
  void logRequest(String request) {
    for (var service in _services) {
      service.logRequest(request);
    }
  }

  @override
  void logResponse(String response) {
    for (var service in _services) {
      service.logResponse(response);
    }
  }

  @override
  void logVersion(String uuid, String clientId, String clientVersion,
      String serverVersion, String sdkVersion) {
    for (var service in _services) {
      service.logVersion(
          uuid, clientId, clientVersion, serverVersion, sdkVersion);
    }
  }

  @override
  void logWatchEvent(String folderPath, String filePath, String changeType) {
    for (var service in _services) {
      service.logWatchEvent(folderPath, filePath, changeType);
    }
  }

  @override
  Future<void> shutdown() {
    return Future.wait(_services.map((s) => s.shutdown()));
  }
}
