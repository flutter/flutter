// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/mdns_device_discovery.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

void main() {
  group('MDNSDeviceDiscovery', () {
    test('advertises when not running on bot', () async {
      final botDetector = FakeBotDetector(false);
      final FakeMDNSDeviceDiscovery discovery = createDiscovery(botDetector);

      await discovery.advertise(appName: 'app', vmServiceUri: Uri.parse('ws://localhost:1234'));

      expect(discovery.advertised, isTrue);
    });

    test('does not advertise when running on bot', () async {
      final botDetector = FakeBotDetector(true);
      final FakeMDNSDeviceDiscovery discovery = createDiscovery(botDetector);

      // Advertise attempts to start mDNS, but should respect the bot detector.
      await discovery.advertise(appName: 'app', vmServiceUri: Uri.parse('ws://localhost:1234'));

      expect(discovery.advertised, isFalse);
    });
    test('advertises even if BOT=true when BotDetector returns false', () async {
      // Simulate BotDetector saying "False" (e.g. because FLUTTER_ANALYTICS_LOG_FILE is set)
      final botDetector = FakeBotDetector(false);
      final fakePlatform = FakePlatform(environment: <String, String>{'BOT': 'true'});
      final FakeMDNSDeviceDiscovery discovery = createDiscovery(
        botDetector,
        platform: fakePlatform,
      );

      await discovery.advertise(appName: 'app', vmServiceUri: Uri.parse('ws://localhost:1234'));

      expect(discovery.advertised, isTrue);
    });

    test('does not advertise when enable-local-discovery is false', () async {
      final botDetector = FakeBotDetector(false);
      final FakeMDNSDeviceDiscovery discovery = createDiscovery(
        botDetector,
        enableLocalDiscovery: false,
      );

      await discovery.advertise(appName: 'app', vmServiceUri: Uri.parse('ws://localhost:1234'));

      expect(discovery.advertised, isFalse);
    });
  });
}

FakeMDNSDeviceDiscovery createDiscovery(
  FakeBotDetector botDetector, {
  Platform? platform,
  bool enableLocalDiscovery = true,
}) {
  return FakeMDNSDeviceDiscovery(
    device: FakeDevice(),
    vmService: FakeVmService(),
    debuggingOptions: DebuggingOptions.enabled(
      BuildInfo.debug,
      enableLocalDiscovery: enableLocalDiscovery,
    ),
    logger: BufferLogger.test(),
    platform: platform ?? FakePlatform(),
    flutterVersion: FakeFlutterVersion(),
    systemClock: SystemClock.fixed(DateTime(2023)),
    botDetector: botDetector,
  );
}

class FakeMDNSDeviceDiscovery extends MDNSDeviceDiscovery {
  FakeMDNSDeviceDiscovery({
    required super.device,
    required super.vmService,
    required super.debuggingOptions,
    required super.logger,
    required super.platform,
    required super.flutterVersion,
    required super.systemClock,
    required super.botDetector,
  });

  bool advertised = false;

  @override
  Future<void> advertise({required String appName, required Uri? vmServiceUri}) async {
    // We override advertise to check if the base implementation would have proceeded.
    // However, the base implementation calls `MDNSService.create` and `server.start()` which we can't easily mock
    // without more refactoring or proper dependency injection of the mDNS client.
    // BUT, the goal is to test the guarding logic.
    // The guarding logic happens BEFORE creating services.
    // So we can let the base method run until it hits the mDNS part, or we can check the logger?

    // Better approach: modifying MDNSDeviceDiscovery to be testable or checking side effects.
    // The base `advertise` logs "Running on CI/Bot..." if it returns early.
    // We can check the logger.

    try {
      await super.advertise(appName: appName, vmServiceUri: vmServiceUri);
    } on Object {
      // Ignore errors from starting mDNS
    }

    // If it didn't return early, it would try to start mDNS.
    // Since we are in a test and haven't mocked MDNSServer, it will likely throw or log error
    // "Error getting local IPs or starting mDNS".
    // If the logger contains "Running on CI/Bot...", then it obeyed the check.

    final testLogger = (this as dynamic).logger as BufferLogger;
    if (testLogger.traceText.contains('Running on CI/Bot, not starting mDNS server.') ||
        testLogger.traceText.contains('mDNS local discovery is disabled.')) {
      advertised = false;
    } else {
      advertised = true;
    }
  }
}

class FakeDevice extends Fake implements Device {
  @override
  final String name = 'test-device';

  @override
  final String id = 'test-device-id';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android_arm;
}

class FakeVmService extends Fake implements VmService {}

class FakeBotDetector extends Fake implements BotDetector {
  FakeBotDetector(this.isRunningOnBotValue);
  final bool isRunningOnBotValue;

  @override
  Future<bool> get isRunningOnBot async => isRunningOnBotValue;
}

class FakeFlutterVersion extends Fake implements FlutterVersion {
  @override
  final String frameworkVersion = '1.0.0';
  @override
  final String dartSdkVersion = '2.0.0';
}
