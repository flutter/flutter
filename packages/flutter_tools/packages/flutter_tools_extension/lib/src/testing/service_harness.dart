// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter_tools_core/flutter_tools_core.dart';

import '../protocol_base/provider.dart';
import '../protocol_base/service.dart';

/// A non-log JSON-RPC notification emitted by a [ToolExtensionService].
typedef ExtensionRecordedNotification = ({String method, Map<String, Object?> params});

/// In-process test harness for a [ToolExtensionService].
///
/// Wires [ToolExtensionService.notificationSender] so unit tests can invoke
/// service methods directly without spawning an isolate while capturing
/// `'extension.log'` and custom notifications.
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
  final _notifications = <ExtensionRecordedNotification>[];

  /// All `'extension.log'` notifications emitted by [service] in order.
  late final UnmodifiableListView<ExtensionLogMessage> logs =
      UnmodifiableListView<ExtensionLogMessage>(_logs);

  /// All non-log JSON-RPC notifications emitted by [service] in order.
  late final UnmodifiableListView<ExtensionRecordedNotification> notifications =
      UnmodifiableListView<ExtensionRecordedNotification>(_notifications);

  void _handleNotification(String method, Map<String, Object?> params) {
    if (method == ToolExtensionEntryPoint.logNotificationMethod) {
      _logs.add(ExtensionLogMessage.fromJson(params));
      return;
    }
    _notifications.add((method: method, params: Map<String, Object?>.unmodifiable(params)));
  }

  /// Detaches from [service] and awaits [ToolExtensionService.shutdown].
  Future<void> dispose() async {
    service.notificationSender = null;
    await service.shutdown();
  }
}
