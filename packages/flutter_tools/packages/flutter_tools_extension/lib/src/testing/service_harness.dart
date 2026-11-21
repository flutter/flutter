// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:flutter_tools_core/flutter_tools_core.dart';

import '../device.dart';
import '../protocol_base/provider.dart';
import '../protocol_base/service.dart';

/// A non-log JSON-RPC notification emitted by a [ToolExtensionService].
typedef ExtensionRecordedNotification = ({String method, Map<String, Object?> params});

/// In-process test harness for a [ToolExtensionService].
///
/// Attaches to [service] by wiring [ToolExtensionService.notificationSender]
/// so unit tests can invoke service methods directly without spawning an
/// isolate, while still capturing `'extension.log'` and custom notifications
/// and exercising [ToolExtensionService.shutdown] on [dispose].
final class ServiceTestHarness<T extends ToolExtensionService> {
  ServiceTestHarness(this.service) {
    if (service.notificationSender != null) {
      throw StateError('Service "${service.namespace}" already has a notificationSender attached.');
    }
    service.notificationSender = _handleNotification;
  }

  /// The extension service instance under test.
  final T service;

  final _logs = <ExtensionLogMessage>[];
  final _logController = StreamController<ExtensionLogMessage>.broadcast();
  final _notifications = <ExtensionRecordedNotification>[];

  Future<void>? _disposeFuture;

  /// All `'extension.log'` notifications emitted by [service] in order.
  late final UnmodifiableListView<ExtensionLogMessage> logs =
      UnmodifiableListView<ExtensionLogMessage>(_logs);

  /// Broadcast stream of `'extension.log'` notifications emitted by [service].
  Stream<ExtensionLogMessage> get onLog => _logController.stream;

  /// All non-log JSON-RPC notifications emitted by [service] in order.
  late final UnmodifiableListView<ExtensionRecordedNotification> notifications =
      UnmodifiableListView<ExtensionRecordedNotification>(_notifications);

  /// Extracts log lines emitted via [DeviceService.logEntryNotificationMethod]
  /// for [deviceId].
  ///
  /// Throws a [FormatException] if any recorded `'device.logEntry'` payload has
  /// a non-[String] `deviceId` or `line`.
  List<String> deviceLogLines(String deviceId) {
    final lines = <String>[];
    for (final ExtensionRecordedNotification notification in _notifications) {
      if (notification.method != DeviceService.logEntryNotificationMethod) {
        continue;
      }
      final Object? entryDeviceId = notification.params[DeviceService.deviceIdParam];
      final Object? line = notification.params[DeviceService.lineKey];
      if (entryDeviceId is! String || line is! String) {
        throw FormatException(
          'Malformed ${DeviceService.logEntryNotificationMethod} payload: ${notification.params}',
        );
      }
      if (entryDeviceId == deviceId) {
        lines.add(line);
      }
    }
    return lines;
  }

  void _handleNotification(String method, Map<String, Object?> params) {
    if (_disposeFuture != null) {
      return;
    }
    if (method == ToolExtensionEntryPoint.logNotificationMethod) {
      final parsed = ExtensionLogMessage.fromJson(params);
      _logs.add(parsed);
      _logController.add(parsed);
      return;
    }
    _notifications.add((method: method, params: Map<String, Object?>.unmodifiable(params)));
  }

  /// Detaches from [service], closes [onLog], and awaits
  /// [ToolExtensionService.shutdown].
  Future<void> dispose() => _disposeFuture ??= _doDispose();

  Future<void> _doDispose() async {
    if (service.notificationSender == _handleNotification) {
      service.notificationSender = null;
    }
    await _logController.close();
    await service.shutdown();
  }
}
