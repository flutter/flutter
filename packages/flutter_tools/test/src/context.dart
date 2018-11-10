// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import 'common.dart';

export 'package:flutter_tools/src/base/context.dart' show Generator;

/// Return the test logger. This assumes that the current Logger is a BufferLogger.
BufferLogger get testLogger => context[Logger];

MockDeviceManager get testDeviceManager => context[DeviceManager];
MockDoctor get testDoctor => context[Doctor];

typedef ContextInitializer = void Function(AppContext testContext);

@isTest
void testUsingContext(String description, dynamic testMethod(), {
  Timeout timeout,
  Map<Type, Generator> overrides = const <Type, Generator>{},
  bool initializeFlutterRoot = true,
  String testOn,
  bool skip, // should default to `false`, but https://github.com/dart-lang/test/issues/545 doesn't allow this
}) {
  // Ensure we don't rely on the default [Config] constructor which will
  // leak a sticky $HOME/.flutter_settings behind!
  Directory configDir;
  tearDown(() {
    if (configDir != null) {
      tryToDelete(configDir);
      configDir = null;
    }
  });
  Config buildConfig(FileSystem fs) {
    configDir = fs.systemTempDirectory.createTempSync('flutter_config_dir_test.');
    final File settingsFile = fs.file(
      fs.path.join(configDir.path, '.flutter_settings')
    );
    return Config(settingsFile);
  }

  test(description, () async {
    await runInContext<dynamic>(() {
      return context.run<dynamic>(
        name: 'mocks',
        overrides: <Type, Generator>{
          Config: () => buildConfig(fs),
          DeviceManager: () => MockDeviceManager(),
          Doctor: () => MockDoctor(),
          FlutterVersion: () => MockFlutterVersion(),
          HttpClient: () => MockHttpClient(),
          IOSSimulatorUtils: () {
            final MockIOSSimulatorUtils mock = MockIOSSimulatorUtils();
            when(mock.getAttachedDevices()).thenReturn(<IOSSimulator>[]);
            return mock;
          },
          OutputPreferences: () => OutputPreferences(showColor: false),
          Logger: () => BufferLogger(),
          OperatingSystemUtils: () => MockOperatingSystemUtils(),
          SimControl: () => MockSimControl(),
          Usage: () => MockUsage(),
          XcodeProjectInterpreter: () => MockXcodeProjectInterpreter(),
          FileSystem: () => LocalFileSystemBlockingSetCurrentDirectory(),
        },
        body: () {
          final String flutterRoot = getFlutterRoot();

          return runZoned<Future<dynamic>>(() {
            try {
              return context.run<dynamic>(
                // Apply the overrides to the test context in the zone since their
                // instantiation may reference items already stored on the context.
                overrides: overrides,
                name: 'test-specific overrides',
                body: () async {
                  if (initializeFlutterRoot) {
                    // Provide a sane default for the flutterRoot directory. Individual
                    // tests can override this either in the test or during setup.
                    Cache.flutterRoot ??= flutterRoot;
                  }

                  return await testMethod();
                },
              );
            } catch (error) {
              _printBufferedErrors(context);
              rethrow;
            }
          }, onError: (dynamic error, StackTrace stackTrace) {
            io.stdout.writeln(error);
            io.stdout.writeln(stackTrace);
            _printBufferedErrors(context);
            throw error;
          });
        },
      );
    });
  }, timeout: timeout != null ? timeout : const Timeout(Duration(seconds: 60)),
      testOn: testOn, skip: skip);
}

void _printBufferedErrors(AppContext testContext) {
  if (testContext[Logger] is BufferLogger) {
    final BufferLogger bufferLogger = testContext[Logger];
    if (bufferLogger.errorText.isNotEmpty)
      print(bufferLogger.errorText);
    bufferLogger.clear();
  }
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
  Stream<Device> getAllConnectedDevices() => Stream<Device>.fromIterable(devices);

  @override
  Stream<Device> getDevicesById(String deviceId) {
    return Stream<Device>.fromIterable(
        devices.where((Device device) => device.id == deviceId));
  }

  @override
  Stream<Device> getDevices() {
    return hasSpecifiedDeviceId
        ? getDevicesById(specifiedDeviceId)
        : getAllConnectedDevices();
  }

  void addDevice(Device device) => devices.add(device);

  @override
  bool get canListAnything => true;

  @override
  Future<List<String>> getDeviceDiagnostics() async => <String>[];
}

class MockAndroidLicenseValidator extends AndroidLicenseValidator {
  @override
  Future<LicensesAccepted> get licensesAccepted async => LicensesAccepted.all;
}

class MockDoctor extends Doctor {
  // True for testing.
  @override
  bool get canListAnything => true;

  // True for testing.
  @override
  bool get canLaunchAnything => true;

  @override
  /// Replaces the android workflow with a version that overrides licensesAccepted,
  /// to prevent individual tests from having to mock out the process for
  /// the Doctor.
  List<DoctorValidator> get validators {
    final List<DoctorValidator> superValidators = super.validators;
    return superValidators.map<DoctorValidator>((DoctorValidator v) {
      if (v is AndroidLicenseValidator) {
        return MockAndroidLicenseValidator();
      }
      return v;
    }).toList();
  }
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

  @override
  String get pathVarSeparator => ';';
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
  void sendCommand(String command, { Map<String, String> parameters }) { }

  @override
  void sendEvent(String category, String parameter, { Map<String, String> parameters }) { }

  @override
  void sendTiming(String category, String variableName, Duration duration, { String label }) { }

  @override
  void sendException(dynamic exception, StackTrace trace) { }

  @override
  Stream<Map<String, dynamic>> get onSend => null;

  @override
  Future<void> ensureAnalyticsSent() => Future<void>.value();

  @override
  void printWelcome() { }
}

class MockXcodeProjectInterpreter implements XcodeProjectInterpreter {
  @override
  bool get isInstalled => true;

  @override
  String get versionText => 'Xcode 9.2';

  @override
  int get majorVersion => 9;

  @override
  int get minorVersion => 2;

  @override
  Map<String, String> getBuildSettings(String projectPath, String target) {
    return <String, String>{};
  }

  @override
  XcodeProjectInfo getInfo(String projectPath) {
    return XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug', 'Release'],
      <String>['Runner'],
    );
  }
}

class MockFlutterVersion extends Mock implements FlutterVersion {}

class MockClock extends Mock implements SystemClock {}

class MockHttpClient extends Mock implements HttpClient {}

class LocalFileSystemBlockingSetCurrentDirectory extends LocalFileSystem {
  @override
  set currentDirectory(dynamic value) {
    throw 'fs.currentDirectory should not be set on the local file system during '
          'tests as this can cause race conditions with concurrent tests. '
          'Consider using a MemoryFileSystem for testing if possible or refactor '
          'code to not require setting fs.currentDirectory.';
  }
}
