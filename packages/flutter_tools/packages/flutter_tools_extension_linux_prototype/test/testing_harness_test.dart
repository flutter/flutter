// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension/testing.dart';
import 'package:test/test.dart';

final class _FakeService extends ToolExtensionService {
  int shutdownCount = 0;

  @override
  String get namespace => DiagnosticsExtension.serviceNamespace;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async => <String, ExtensionRpcHandler>{};

  @override
  Future<void> shutdown() async {
    shutdownCount++;
  }
}

void main() {
  group('ServiceTestHarness', () {
    test('captures extension.log messages with default and explicit timestamps', () {
      final service = _FakeService();
      final harness = ServiceTestHarness<_FakeService>(service);
      addTearDown(harness.dispose);

      final DateTime before = DateTime.now().toUtc();
      final explicitTime = DateTime.utc(2026, 1, 2, 3, 4, 5);
      service
        ..log('plain message')
        ..log('warning message', level: .warning, timestamp: explicitTime);
      final DateTime after = DateTime.now().toUtc();

      expect(harness.logs, hasLength(2));
      expect(harness.logs[0].level, ExtensionLogLevel.info);
      expect(harness.logs[0].message, 'plain message');
      expect(harness.logs[0].timestamp, isNotNull);
      expect(harness.logs[0].timestamp!.isUtc, isTrue);
      expect(harness.logs[0].timestamp!.isBefore(before), isFalse);
      expect(harness.logs[0].timestamp!.isAfter(after), isFalse);
      expect(harness.logs[1].level, ExtensionLogLevel.warning);
      expect(harness.logs[1].message, 'warning message');
      expect(harness.logs[1].timestamp, explicitTime);
      expect(harness.notifications, isEmpty);
    });

    test('rejects malformed extension.log payloads', () {
      final harness = ServiceTestHarness<_FakeService>(_FakeService());
      addTearDown(harness.dispose);

      expect(
        () => harness.service.sendNotification(
          ToolExtensionEntryPoint.logNotificationMethod,
          <String, Object?>{'level': 'bogus', 'message': 'bad'},
        ),
        throwsFormatException,
      );
      expect(harness.logs, isEmpty);
    });

    test('captures custom notifications in order with unmodifiable params', () {
      final service = _FakeService();
      final harness = ServiceTestHarness<_FakeService>(service);
      addTearDown(harness.dispose);

      final params = <String, Object?>{'count': 42};
      service
        ..sendNotification(DeviceService.logEntryNotificationMethod, <String, Object?>{
          DeviceService.deviceIdParam: 'dev-1',
          DeviceService.lineKey: 'line 1',
        })
        ..sendNotification('custom.event', params);
      params['count'] = 99;

      expect(harness.logs, isEmpty);
      expect(harness.notifications, hasLength(2));
      expect(harness.notifications[0].method, DeviceService.logEntryNotificationMethod);
      expect(harness.notifications[0].params, <String, Object?>{
        DeviceService.deviceIdParam: 'dev-1',
        DeviceService.lineKey: 'line 1',
      });
      expect(harness.notifications[1].method, 'custom.event');
      expect(harness.notifications[1].params, <String, Object?>{'count': 42});
      expect(() => harness.notifications[1].params['count'] = 0, throwsUnsupportedError);
    });

    test('rejects attaching a second harness to the same service', () {
      final service = _FakeService();
      final harness = ServiceTestHarness<_FakeService>(service);
      addTearDown(harness.dispose);

      expect(() => ServiceTestHarness<_FakeService>(service), throwsStateError);
    });

    test('dispose detaches notificationSender and calls shutdown', () async {
      final service = _FakeService();
      final harness = ServiceTestHarness<_FakeService>(service);

      await harness.dispose();

      expect(service.shutdownCount, 1);
      expect(() => service.log('after dispose'), throwsStateError);
      expect(
        () => service.sendNotification('custom.event', const <String, Object?>{}),
        throwsStateError,
      );

      final reattached = ServiceTestHarness<_FakeService>(service);
      addTearDown(reattached.dispose);
    });
  });
}
