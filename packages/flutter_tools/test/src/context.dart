// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import 'common.dart';
import 'fake_http_client.dart';
import 'fake_process_manager.dart';
import 'fakes.dart';
import 'throwing_pub.dart';

export 'package:flutter_tools/src/base/context.dart' show Generator;
export 'fake_process_manager.dart' show ProcessManager, FakeProcessManager, FakeCommand;

/// Return the test logger. This assumes that the current Logger is a BufferLogger.
BufferLogger get testLogger => context.get<Logger>() as BufferLogger;

FakeDeviceManager get testDeviceManager => context.get<DeviceManager>() as FakeDeviceManager;
FakeDoctor get testDoctor => context.get<Doctor>() as FakeDoctor;

typedef ContextInitializer = void Function(AppContext testContext);

@isTest
void testUsingContext(
  String description,
  dynamic testMethod(), {
  Map<Type, Generator> overrides = const <Type, Generator>{},
  bool initializeFlutterRoot = true,
  String testOn,
  Timeout timeout,
  bool skip, // should default to `false`, but https://github.com/dart-lang/test/issues/545 doesn't allow this
}) {
  if (overrides[FileSystem] != null && overrides[ProcessManager] == null) {
    throw StateError(
      'If you override the FileSystem context you must also provide a ProcessManager, '
      'otherwise the processes you launch will not be dealing with the same file system '
      'that you are dealing with in your test.'
    );
  }
  if (overrides.containsKey(ProcessUtils)) {
    throw StateError('Do not inject ProcessUtils for testing, use ProcessManager instead.');
  }

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
    configDir ??= globals.fs.systemTempDirectory.createTempSync(
      'flutter_config_dir_test.',
    );
    return Config.test(
      name: Config.kFlutterSettings,
      directory: configDir,
      logger: globals.logger,
    );
  }
  PersistentToolState buildPersistentToolState(FileSystem fs) {
    configDir ??= globals.fs.systemTempDirectory.createTempSync(
      'flutter_config_dir_test.',
    );
    return PersistentToolState.test(
      directory: configDir,
      logger: globals.logger,
    );
  }

  test(description, () async {
    await runInContext<dynamic>(() {
      return context.run<dynamic>(
        name: 'mocks',
        overrides: <Type, Generator>{
          AnsiTerminal: () => AnsiTerminal(platform: globals.platform, stdio: globals.stdio),
          Config: () => buildConfig(globals.fs),
          DeviceManager: () => FakeDeviceManager(),
          Doctor: () => FakeDoctor(globals.logger),
          FlutterVersion: () => MockFlutterVersion(),
          HttpClient: () => FakeHttpClient.any(),
          IOSSimulatorUtils: () {
            final MockIOSSimulatorUtils mock = MockIOSSimulatorUtils();
            when(mock.getAttachedDevices()).thenAnswer((Invocation _) async => <IOSSimulator>[]);
            return mock;
          },
          OutputPreferences: () => OutputPreferences.test(),
          Logger: () => BufferLogger(
            terminal: globals.terminal,
            outputPreferences: globals.outputPreferences,
          ),
          OperatingSystemUtils: () => FakeOperatingSystemUtils(),
          PersistentToolState: () => buildPersistentToolState(globals.fs),
          SimControl: () => MockSimControl(),
          Usage: () => TestUsage(),
          XcodeProjectInterpreter: () => FakeXcodeProjectInterpreter(),
          FileSystem: () => LocalFileSystemBlockingSetCurrentDirectory(),
          PlistParser: () => FakePlistParser(),
          Signals: () => FakeSignals(),
          Pub: () => ThrowingPub(), // prevent accidentally using pub.
          CrashReporter: () => MockCrashReporter(),
          TemplateRenderer: () => const MustacheTemplateRenderer(),
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
            // This catch rethrows, so doesn't need to catch only Exception.
            } catch (error) { // ignore: avoid_catches_without_on_clauses
              _printBufferedErrors(context);
              rethrow;
            }
          }, onError: (Object error, StackTrace stackTrace) { // ignore: deprecated_member_use
            print(error);
            print(stackTrace);
            _printBufferedErrors(context);
            throw error;
          });
        },
      );
    }, overrides: <Type, Generator>{
      // This has to go here so that runInContext will pick it up when it tries
      // to do bot detection before running the closure.  This is important
      // because the test may be giving us a fake HttpClientFactory, which may
      // throw in unexpected/abnormal ways.
      // If a test needs a BotDetector that does not always return true, it
      // can provide the AlwaysFalseBotDetector in the overrides, or its own
      // BotDetector implementation in the overrides.
      BotDetector: overrides[BotDetector] ?? () => const FakeBotDetector(true),
    });
  }, testOn: testOn, skip: skip, timeout: timeout);
}

void _printBufferedErrors(AppContext testContext) {
  if (testContext.get<Logger>() is BufferLogger) {
    final BufferLogger bufferLogger = testContext.get<Logger>() as BufferLogger;
    if (bufferLogger.errorText.isNotEmpty) {
      print(bufferLogger.errorText);
    }
    bufferLogger.clear();
  }
}

class FakeDeviceManager implements DeviceManager {
  List<Device> devices = <Device>[];

  String _specifiedDeviceId;

  @override
  String get specifiedDeviceId {
    if (_specifiedDeviceId == null || _specifiedDeviceId == 'all') {
      return null;
    }
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
  Future<List<Device>> getAllConnectedDevices() async => devices;

  @override
  Future<List<Device>> refreshAllConnectedDevices({ Duration timeout }) async => devices;

  @override
  Future<List<Device>> getDevicesById(String deviceId) async {
    return devices.where((Device device) => device.id == deviceId).toList();
  }

  @override
  Future<List<Device>> getDevices() {
    return hasSpecifiedDeviceId
        ? getDevicesById(specifiedDeviceId)
        : getAllConnectedDevices();
  }

  void addDevice(Device device) => devices.add(device);

  @override
  bool get canListAnything => true;

  @override
  Future<List<String>> getDeviceDiagnostics() async => <String>[];

  @override
  List<DeviceDiscovery> get deviceDiscoverers => <DeviceDiscovery>[];

  @override
  bool isDeviceSupportedForProject(Device device, FlutterProject flutterProject) {
    return device.isSupportedForProject(flutterProject);
  }

  @override
  Future<List<Device>> findTargetDevices(FlutterProject flutterProject, { Duration timeout }) async {
    return devices;
  }
}

class FakeAndroidLicenseValidator extends AndroidLicenseValidator {
  @override
  Future<LicensesAccepted> get licensesAccepted async => LicensesAccepted.all;
}

class FakeDoctor extends Doctor {
  FakeDoctor(Logger logger) : super(logger: logger);

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
        return FakeAndroidLicenseValidator();
      }
      return v;
    }).toList();
  }
}

class MockSimControl extends Mock implements SimControl {
  MockSimControl() {
    when(getConnectedDevices()).thenAnswer((Invocation _) async => <SimDevice>[]);
  }
}

class FakeOperatingSystemUtils implements OperatingSystemUtils {
  @override
  ProcessResult makeExecutable(File file) => null;

  @override
  HostPlatform hostPlatform = HostPlatform.linux_x64;

  @override
  void chmod(FileSystemEntity entity, String mode) { }

  @override
  File which(String execName) => null;

  @override
  List<File> whichAll(String execName) => <File>[];

  @override
  File makePipe(String path) => null;

  @override
  void unzip(File file, Directory targetDirectory) { }

  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) { }

  @override
  Stream<List<int>> gzipLevel1Stream(Stream<List<int>> stream) => stream;

  @override
  String get name => 'fake OS name and version';

  @override
  String get pathVarSeparator => ';';

  @override
  Future<int> findFreePort({bool ipv6 = false}) async => 12345;
}

class MockIOSSimulatorUtils extends Mock implements IOSSimulatorUtils {}

class FakeXcodeProjectInterpreter implements XcodeProjectInterpreter {
  @override
  bool get isInstalled => true;

  @override
  String get versionText => 'Xcode 11.0';

  @override
  int get majorVersion => 11;

  @override
  int get minorVersion => 0;

  @override
  int get patchVersion => 0;

  @override
  Future<Map<String, String>> getBuildSettings(
    String projectPath, {
    String scheme,
    Duration timeout = const Duration(minutes: 1),
  }) async {
    return <String, String>{};
  }

  @override
  Future<void> cleanWorkspace(String workspacePath, String scheme, { bool verbose = false }) {
    return null;
  }

  @override
  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    return XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug', 'Release'],
      <String>['Runner'],
      BufferLogger.test(),
    );
  }

  @override
  List<String> xcrunCommand() => <String>['xcrun'];
}

class MockFlutterVersion extends Mock implements FlutterVersion {}

class MockCrashReporter extends Mock implements CrashReporter {}

class LocalFileSystemBlockingSetCurrentDirectory extends LocalFileSystem {
  LocalFileSystemBlockingSetCurrentDirectory() : super.test(
    signals: LocalSignals.instance,
  );

  @override
  set currentDirectory(dynamic value) {
    throw 'globals.fs.currentDirectory should not be set on the local file system during '
          'tests as this can cause race conditions with concurrent tests. '
          'Consider using a MemoryFileSystem for testing if possible or refactor '
          'code to not require setting globals.fs.currentDirectory.';
  }
}

class FakeSignals implements Signals {
  @override
  Object addHandler(ProcessSignal signal, SignalHandler handler) {
    return null;
  }

  @override
  Future<bool> removeHandler(ProcessSignal signal, Object token) async {
    return true;
  }

  @override
  Stream<Object> get errors => const Stream<Object>.empty();
}
