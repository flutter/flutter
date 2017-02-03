// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/toolchain.dart';
import 'package:flutter_tools/src/usage.dart';

import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:test/test.dart';

/// Return the test logger. This assumes that the current Logger is a BufferLogger.
BufferLogger get testLogger => context[Logger];

MockDeviceManager get testDeviceManager => context[DeviceManager];
MockDoctor get testDoctor => context[Doctor];

typedef dynamic Generator();

void testUsingContext(String description, dynamic testMethod(), {
  Timeout timeout,
  Map<Type, Generator> overrides: const <Type, Generator>{},
  bool skip: false,
}) {
  test(description, () async {
    AppContext testContext = new AppContext();

    // Initialize the test context with some default mocks.
    // Seed these context entries first since others depend on them
    testContext.putIfAbsent(Platform, () => new LocalPlatform());
    testContext.putIfAbsent(FileSystem, () => new LocalFileSystem());
    testContext.putIfAbsent(ProcessManager, () => new LocalProcessManager());
    testContext.putIfAbsent(Logger, () => new BufferLogger());

    // Order-independent context entries
    testContext.putIfAbsent(DeviceManager, () => new MockDeviceManager());
    testContext.putIfAbsent(DevFSConfig, () => new DevFSConfig());
    testContext.putIfAbsent(Doctor, () => new MockDoctor());
    testContext.putIfAbsent(HotRunnerConfig, () => new HotRunnerConfig());
    testContext.putIfAbsent(Cache, () => new Cache());
    testContext.putIfAbsent(ToolConfiguration, () => new ToolConfiguration());
    testContext.putIfAbsent(Config, () => new Config());
    testContext.putIfAbsent(OperatingSystemUtils, () {
      MockOperatingSystemUtils os = new MockOperatingSystemUtils();
      when(os.isWindows).thenReturn(false);
      return os;
    });
    testContext.putIfAbsent(Xcode, () => new Xcode());
    testContext.putIfAbsent(IOSSimulatorUtils, () {
      MockIOSSimulatorUtils mock = new MockIOSSimulatorUtils();
      when(mock.getAttachedDevices()).thenReturn(<IOSSimulator>[]);
      return mock;
    });
    testContext.putIfAbsent(SimControl, () => new MockSimControl());
    testContext.putIfAbsent(Usage, () => new MockUsage());

    final String basePath = path.dirname(path.fromUri(platform.script));
    final String flutterRoot =
        path.normalize(path.join(basePath, '..', '..', '..'));
    try {
      return await testContext.runInZone(() {
        // Apply the overrides to the test context in the zone since their
        // instantiation may reference items already stored on the context.
        overrides.forEach((Type type, dynamic value()) {
          context.setVariable(type, value());
        });
        // Provide a sane default for the flutterRoot directory. Individual
        // tests can override this.
        Cache.flutterRoot = flutterRoot;
        return testMethod();
      });
    } catch (error) {
      if (testContext[Logger] is BufferLogger) {
        BufferLogger bufferLogger = testContext[Logger];
        if (bufferLogger.errorText.isNotEmpty)
          print(bufferLogger.errorText);
      }
      // Previously the following line read "throw error;". This is bad because
      // it drops the error's actual stacktrace. Use 'rethrow' to preserve
      // the stacktrace.
      rethrow;
    }

  }, timeout: timeout, skip: skip);
}

class MockDeviceManager implements DeviceManager {
  List<Device> devices = <Device>[];

  @override
  String specifiedDeviceId;

  @override
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  @override
  Future<List<Device>> getAllConnectedDevices() => new Future<List<Device>>.value(devices);

  @override
  Future<List<Device>> getDevicesById(String deviceId) async {
    return devices.where((Device device) => device.id == deviceId).toList();
  }

  @override
  Future<List<Device>> getDevices() async {
    if (specifiedDeviceId == null) {
      return getAllConnectedDevices();
    } else {
      return getDevicesById(specifiedDeviceId);
    }
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
    when(this.getConnectedDevices()).thenReturn(<SimDevice>[]);
  }
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {
  // TODO(goderbauer): Calls to the executable should be mocked out.
  //     That way it wouldn't really matter what the mock returns here.
  @override
  String getExecutableName(String binaryName, { String winExtension }) {
    if (!platform.isWindows)
      return binaryName;
    winExtension ??= 'exe';
    if (path.extension(binaryName).isEmpty && winExtension.isNotEmpty)
      return '$binaryName.$winExtension';
    return binaryName;
  }
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
  void sendCommand(String command) { }

  @override
  void sendEvent(String category, String parameter) { }

  @override
  void sendTiming(String category, String variableName, Duration duration) { }

  @override
  UsageTimer startTimer(String event) => new _MockUsageTimer(event);

  @override
  void sendException(dynamic exception, StackTrace trace) { }

  @override
  Stream<Map<String, dynamic>> get onSend => null;

  @override
  Future<Null> ensureAnalyticsSent() => new Future<Null>.value();

  @override
  void printUsage() { }
}

class _MockUsageTimer implements UsageTimer {
  _MockUsageTimer(this.event);

  @override
  final String event;

  @override
  void finish() { }
}
