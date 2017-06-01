// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/port_scanner.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:quiver/time.dart';
import 'package:test/test.dart';

import 'common.dart';

/// Return the test logger. This assumes that the current Logger is a BufferLogger.
BufferLogger get testLogger => context[Logger];

MockDeviceManager get testDeviceManager => context[DeviceManager];
MockDoctor get testDoctor => context[Doctor];

typedef dynamic Generator();

typedef void ContextInitializer(AppContext testContext);

void _defaultInitializeContext(AppContext testContext) {
  testContext
    ..putIfAbsent(AnsiTerminal, () => new AnsiTerminal())
    ..putIfAbsent(DeviceManager, () => new MockDeviceManager())
    ..putIfAbsent(DevFSConfig, () => new DevFSConfig())
    ..putIfAbsent(Doctor, () => new MockDoctor())
    ..putIfAbsent(HotRunnerConfig, () => new HotRunnerConfig())
    ..putIfAbsent(Cache, () => new Cache())
    ..putIfAbsent(Artifacts, () => new CachedArtifacts())
    ..putIfAbsent(OperatingSystemUtils, () => new MockOperatingSystemUtils())
    ..putIfAbsent(PortScanner, () => new MockPortScanner())
    ..putIfAbsent(Xcode, () => new Xcode())
    ..putIfAbsent(IOSSimulatorUtils, () {
      final MockIOSSimulatorUtils mock = new MockIOSSimulatorUtils();
      when(mock.getAttachedDevices()).thenReturn(<IOSSimulator>[]);
      return mock;
    })
    ..putIfAbsent(SimControl, () => new MockSimControl())
    ..putIfAbsent(Usage, () => new MockUsage())
    ..putIfAbsent(FlutterVersion, () => new MockFlutterVersion())
    ..putIfAbsent(Clock, () => const Clock());
}

void testUsingContext(String description, dynamic testMethod(), {
  Timeout timeout,
  Map<Type, Generator> overrides: const <Type, Generator>{},
  ContextInitializer initializeContext: _defaultInitializeContext,
  bool skip, // should default to `false`, but https://github.com/dart-lang/test/issues/545 doesn't allow this
}) {
  test(description, () async {
    final AppContext testContext = new AppContext();

    // The context always starts with these value since others depend on them.
    testContext
      ..putIfAbsent(Platform, () => const LocalPlatform())
      ..putIfAbsent(FileSystem, () => const LocalFileSystem())
      ..putIfAbsent(ProcessManager, () => const LocalProcessManager())
      ..putIfAbsent(Logger, () => new BufferLogger())
      ..putIfAbsent(Config, () => new Config());

    // Apply the initializer after seeding the base value above.
    initializeContext(testContext);

    final String flutterRoot = getFlutterRoot();

    try {
      return await testContext.runInZone(() async {
        // Apply the overrides to the test context in the zone since their
        // instantiation may reference items already stored on the context.
        overrides.forEach((Type type, dynamic value()) {
          context.setVariable(type, value());
        });

        // Provide a sane default for the flutterRoot directory. Individual
        // tests can override this either in the test or during setup.
        Cache.flutterRoot ??= flutterRoot;

        return await testMethod();
      }, onError: (dynamic error, StackTrace stackTrace) {
        _printBufferedErrors(testContext);
        throw error;
      });
    } catch (error) {
      _printBufferedErrors(testContext);
      rethrow;
    }

  }, timeout: timeout, skip: skip);
}

void _printBufferedErrors(AppContext testContext) {
  if (testContext[Logger] is BufferLogger) {
    final BufferLogger bufferLogger = testContext[Logger];
    if (bufferLogger.errorText.isNotEmpty)
      print(bufferLogger.errorText);
    bufferLogger.clear();
  }
}

class MockPortScanner extends PortScanner {
  static int _nextAvailablePort = 12345;

  @override
  Future<bool> isPortAvailable(int port) async => true;

  @override
  Future<int> findAvailablePort() async => _nextAvailablePort++;
}

class MockDeviceManager implements DeviceManager {
  List<Device> devices = <Device>[];

  String _specifiedDeviceId;

  @override
  String get specifiedDeviceId {
    if (_specifiedDeviceId == null || _specifiedDeviceId == 'all')
      return null;
    return _specifiedDeviceId;
  }

  @override
  set specifiedDeviceId(String id) {
    _specifiedDeviceId = id;
  }

  @override
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  @override
  bool get hasSpecifiedAllDevices {
    return _specifiedDeviceId != null && _specifiedDeviceId == 'all';
  }

  @override
  Stream<Device> getAllConnectedDevices() => new Stream<Device>.fromIterable(devices);

  @override
  Stream<Device> getDevicesById(String deviceId) {
    return new Stream<Device>.fromIterable(
        devices.where((Device device) => device.id == deviceId));
  }

  @override
  Stream<Device> getDevices() {
    return hasSpecifiedDeviceId
        ? getDevicesById(specifiedDeviceId)
        : getAllConnectedDevices();
  }

  void addDevice(Device device) => devices.add(device);
}

class MockDoctor extends Doctor {
  // True for testing.
  @override
  bool get canListAnything => true;

  // True for testing.
  @override
  bool get canLaunchAnything => true;
}

class MockSimControl extends Mock implements SimControl {
  MockSimControl() {
    when(getConnectedDevices()).thenReturn(<SimDevice>[]);
  }
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {
  @override
  List<File> whichAll(String execName) => <File>[];

  @override
  String get name => 'fake OS name and version';
}

class MockIOSSimulatorUtils extends Mock implements IOSSimulatorUtils {}

class MockUsage implements Usage {
  @override
  bool get isFirstRun => false;

  @override
  bool get suppressAnalytics => false;

  @override
  set suppressAnalytics(bool value) { }

  @override
  bool get enabled => true;

  @override
  set enabled(bool value) { }

  @override
  String get clientId => '00000000-0000-4000-0000-000000000000';

  @override
  void sendCommand(String command) { }

  @override
  void sendEvent(String category, String parameter) { }

  @override
  void sendTiming(String category, String variableName, Duration duration, { String label }) { }

  @override
  void sendException(dynamic exception, StackTrace trace) { }

  @override
  Stream<Map<String, dynamic>> get onSend => null;

  @override
  Future<Null> ensureAnalyticsSent() => new Future<Null>.value();

  @override
  void printWelcome() { }
}

class MockFlutterVersion extends Mock implements FlutterVersion {}

class MockClock extends Mock implements Clock {}
