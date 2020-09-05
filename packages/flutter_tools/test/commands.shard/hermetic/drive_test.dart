// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/drive.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:webdriver/sync_io.dart' as sync_io;
import 'package:flutter_tools/src/vmservice.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/mocks.dart';

void main() {
  group('drive', () {
    DriveCommand command;
    Device mockUnsupportedDevice;
    MemoryFileSystem fs;
    Directory tempDir;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      command = DriveCommand();
      applyMocksToCommand(command);
      fs = MemoryFileSystem();
      tempDir = fs.systemTempDirectory.createTempSync('flutter_drive_test.');
      fs.currentDirectory = tempDir;
      fs.directory('test').createSync();
      fs.directory('test_driver').createSync();
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      setExitFunctionForTests();
      appStarter = (DriveCommand command, Uri webUri) {
        throw 'Unexpected call to appStarter';
      };
      testRunner = (List<String> testArgs, Map<String, String> environment) {
        throw 'Unexpected call to testRunner';
      };
      appStopper = (DriveCommand command) {
        throw 'Unexpected call to appStopper';
      };
    });

    tearDown(() {
      command = null;
      restoreExitFunction();
      restoreAppStarter();
      restoreAppStopper();
      restoreTestRunner();
      tryToDelete(tempDir);
    });

    void applyDdsMocks(Device device) {
      final MockDartDevelopmentService mockDds = MockDartDevelopmentService();
      when(device.dds).thenReturn(mockDds);
      when(mockDds.startDartDevelopmentService(any, any)).thenReturn(null);
    }

    testUsingContext('returns 1 when test file is not found', () async {
      testDeviceManager.addDevice(MockDevice());

      final String testApp = globals.fs.path.join(tempDir.path, 'test', 'e2e.dart');
      final String testFile = globals.fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');
      globals.fs.file(testApp).createSync(recursive: true);

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
        expect(e.message, contains('Test file not found: $testFile'));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 1 when app fails to run', () async {
      testDeviceManager.addDevice(MockDevice());
      appStarter = expectAsync2((DriveCommand command, Uri webUri) async => null);

      final String testApp = globals.fs.path.join(tempDir.path, 'test_driver', 'e2e.dart');
      final String testFile = globals.fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

      final MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() { }');
      await memFs.file(testFile).writeAsString('main() { }');

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode, 1);
        expect(e.message, contains('Application failed to start. Will not run test. Quitting.'));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 1 when app file is outside package', () async {
      final String appFile = globals.fs.path.join(tempDir.dirname, 'other_app', 'app.dart');
      globals.fs.file(appFile).createSync(recursive: true);
      final List<String> args = <String>[
        '--no-wrap',
        'drive',
        '--target=$appFile',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
        expect(testLogger.errorText, contains(
            'Application file $appFile is outside the package directory ${tempDir.path}',
        ));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 1 when app file is in the root dir', () async {
      final String appFile = globals.fs.path.join(tempDir.path, 'main.dart');
      globals.fs.file(appFile).createSync(recursive: true);
      final List<String> args = <String>[
        '--no-wrap',
        'drive',
        '--target=$appFile',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
        expect(testLogger.errorText, contains(
            'Application file main.dart must reside in one of the '
            'sub-directories of the package structure, not in the root directory.',
        ));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 1 when targeted device is not Android with --device-user', () async {
      testDeviceManager.addDevice(MockDevice());

      final String testApp = globals.fs.path.join(tempDir.path, 'test', 'e2e.dart');
      globals.fs.file(testApp).createSync(recursive: true);

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
        '--device-user',
        '10',
      ];

      expect(() async => await createTestCommandRunner(command).run(args),
        throwsToolExit(message: '--device-user is only supported for Android'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 0 when test ends successfully', () async {
      final MockAndroidDevice mockDevice = MockAndroidDevice();
      applyDdsMocks(mockDevice);
      testDeviceManager.addDevice(mockDevice);

      final String testApp = globals.fs.path.join(tempDir.path, 'test', 'e2e.dart');
      final String testFile = globals.fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

      appStarter = expectAsync2((DriveCommand command, Uri webUri) async {
        return LaunchResult.succeeded();
      });
      testRunner = expectAsync2((List<String> testArgs, Map<String, String> environment) async {
        expect(testArgs, <String>[testFile]);
        // VM_SERVICE_URL is not set by drive command arguments
        expect(environment, <String, String>{
          'VM_SERVICE_URL': 'null',
        });
      });
      appStopper = expectAsync1((DriveCommand command) async {
        return true;
      });

      final MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
        '--device-user',
        '10',
      ];
      await createTestCommandRunner(command).run(args);
      expect(testLogger.errorText, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns exitCode set by test runner', () async {
      final MockDevice mockDevice = MockDevice();
      applyDdsMocks(mockDevice);
      testDeviceManager.addDevice(mockDevice);

      final String testApp = globals.fs.path.join(tempDir.path, 'test', 'e2e.dart');
      final String testFile = globals.fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

      appStarter = expectAsync2((DriveCommand command, Uri webUri) async {
        return LaunchResult.succeeded();
      });
      testRunner = (List<String> testArgs, Map<String, String> environment) async {
        throwToolExit(null, exitCode: 123);
      };
      appStopper = expectAsync1((DriveCommand command) async {
        return true;
      });

      final MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 123);
        expect(e.message, isNull);
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    group('findTargetDevice', () {
      testUsingContext('uses specified device', () async {
        testDeviceManager.specifiedDeviceId = '123';
        final Device mockDevice = MockDevice();
        testDeviceManager.addDevice(mockDevice);
        when(mockDevice.name).thenReturn('specified-device');
        when(mockDevice.id).thenReturn('123');

        final Device device = await findTargetDevice(timeout: null);
        expect(device.name, 'specified-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });

    void findTargetDeviceOnOperatingSystem(String operatingSystem) {
      Platform platform() => FakePlatform(operatingSystem: operatingSystem);

      testUsingContext('returns null if no devices found', () async {
        expect(await findTargetDevice(timeout: null), isNull);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: platform,
      });

      testUsingContext('uses existing Android device', () async {
        final Device mockDevice = MockAndroidDevice();
        when(mockDevice.name).thenReturn('mock-android-device');
        testDeviceManager.addDevice(mockDevice);

        final Device device = await findTargetDevice(timeout: null);
        expect(device.name, 'mock-android-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: platform,
      });

      testUsingContext('skips unsupported device', () async {
        final Device mockDevice = MockAndroidDevice();
        mockUnsupportedDevice = MockDevice();
        when(mockUnsupportedDevice.isSupportedForProject(any))
            .thenReturn(false);
        when(mockUnsupportedDevice.isSupported())
            .thenReturn(false);
        when(mockUnsupportedDevice.name).thenReturn('mock-web');
        when(mockUnsupportedDevice.id).thenReturn('web-1');
        when(mockUnsupportedDevice.targetPlatform).thenAnswer((_) => Future<TargetPlatform>(() => TargetPlatform.web_javascript));
        when(mockUnsupportedDevice.isLocalEmulator).thenAnswer((_) => Future<bool>(() => false));
        when(mockUnsupportedDevice.sdkNameAndVersion).thenAnswer((_) => Future<String>(() => 'html5'));
        when(mockDevice.name).thenReturn('mock-android-device');
        when(mockDevice.id).thenReturn('mad-28');
        when(mockDevice.isSupported())
            .thenReturn(true);
        when(mockDevice.isSupportedForProject(any))
            .thenReturn(true);
        when(mockDevice.targetPlatform).thenAnswer((_) => Future<TargetPlatform>(() => TargetPlatform.android_x64));
        when(mockDevice.isLocalEmulator).thenAnswer((_) => Future<bool>(() => false));
        when(mockDevice.sdkNameAndVersion).thenAnswer((_) => Future<String>(() => 'sdk-28'));
        testDeviceManager.addDevice(mockDevice);
        testDeviceManager.addDevice(mockUnsupportedDevice);

        final Device device = await findTargetDevice(timeout: null);
        expect(device.name, 'mock-android-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: platform,
      });
    }

    group('findTargetDevice on Linux', () {
      findTargetDeviceOnOperatingSystem('linux');
    });

    group('findTargetDevice on Windows', () {
      findTargetDeviceOnOperatingSystem('windows');
    });

    group('findTargetDevice on macOS', () {
      findTargetDeviceOnOperatingSystem('macos');

      Platform macOsPlatform() => FakePlatform(operatingSystem: 'macos');

      testUsingContext('uses existing simulator', () async {
        final Device mockDevice = MockDevice();
        testDeviceManager.addDevice(mockDevice);
        when(mockDevice.name).thenReturn('mock-simulator');
        when(mockDevice.isLocalEmulator)
            .thenAnswer((Invocation invocation) => Future<bool>.value(true));

        final Device device = await findTargetDevice(timeout: null);
        expect(device.name, 'mock-simulator');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: macOsPlatform,
      });
    });

    group('build arguments', () {
      String testApp, testFile;

      setUp(() {
        restoreAppStarter();
      });

      Future<Device> appStarterSetup() async {
        final Device mockDevice = MockDevice();
        applyDdsMocks(mockDevice);
        testDeviceManager.addDevice(mockDevice);

        final FakeDeviceLogReader mockDeviceLogReader = FakeDeviceLogReader();
        when(mockDevice.getLogReader()).thenReturn(mockDeviceLogReader);
        final MockLaunchResult mockLaunchResult = MockLaunchResult();
        when(mockLaunchResult.started).thenReturn(true);
        when(mockDevice.startApp(
          null,
          mainPath: anyNamed('mainPath'),
          route: anyNamed('route'),
          debuggingOptions: anyNamed('debuggingOptions'),
          platformArgs: anyNamed('platformArgs'),
          prebuiltApplication: anyNamed('prebuiltApplication'),
          userIdentifier: anyNamed('userIdentifier'),
        )).thenAnswer((_) => Future<LaunchResult>.value(mockLaunchResult));
        when(mockDevice.isAppInstalled(any, userIdentifier: anyNamed('userIdentifier')))
          .thenAnswer((_) => Future<bool>.value(false));

        testApp = globals.fs.path.join(tempDir.path, 'test', 'e2e.dart');
        testFile = globals.fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

        testRunner = (List<String> testArgs, Map<String, String> environment) async {
          throwToolExit(null, exitCode: 123);
        };
        appStopper = expectAsync1(
            (DriveCommand command) async {
              return true;
            },
            count: 2,
        );

        final MemoryFileSystem memFs = fs;
        await memFs.file(testApp).writeAsString('main() {}');
        await memFs.file(testFile).writeAsString('main() {}');
        return mockDevice;
      }

      testUsingContext('does not use pre-built app if no build arg provided', () async {
        final Device mockDevice = await appStarterSetup();

        final List<String> args = <String>[
          'drive',
          '--target=$testApp',
          '--no-pub',
        ];
        try {
          await createTestCommandRunner(command).run(args);
        } on ToolExit catch (e) {
          expect(e.exitCode, 123);
          expect(e.message, null);
        }
        verify(mockDevice.startApp(
                null,
                mainPath: anyNamed('mainPath'),
                route: anyNamed('route'),
                debuggingOptions: anyNamed('debuggingOptions'),
                platformArgs: anyNamed('platformArgs'),
                prebuiltApplication: false,
                userIdentifier: anyNamed('userIdentifier'),
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('does not use pre-built app if --build arg provided', () async {
        final Device mockDevice = await appStarterSetup();

        final List<String> args = <String>[
          'drive',
          '--build',
          '--target=$testApp',
          '--no-pub',
        ];
        try {
          await createTestCommandRunner(command).run(args);
        } on ToolExit catch (e) {
          expect(e.exitCode, 123);
          expect(e.message, null);
        }
        verify(mockDevice.startApp(
                null,
                mainPath: anyNamed('mainPath'),
                route: anyNamed('route'),
                debuggingOptions: anyNamed('debuggingOptions'),
                platformArgs: anyNamed('platformArgs'),
                prebuiltApplication: false,
                userIdentifier: anyNamed('userIdentifier'),
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('uses prebuilt app if --no-build arg provided', () async {
        final Device mockDevice = await appStarterSetup();

        final List<String> args = <String>[
          'drive',
          '--no-build',
          '--target=$testApp',
          '--no-pub',
        ];
        try {
          await createTestCommandRunner(command).run(args);
        } on ToolExit catch (e) {
          expect(e.exitCode, 123);
          expect(e.message, null);
        }
        verify(mockDevice.startApp(
                null,
                mainPath: anyNamed('mainPath'),
                route: anyNamed('route'),
                debuggingOptions: anyNamed('debuggingOptions'),
                platformArgs: anyNamed('platformArgs'),
                prebuiltApplication: true,
                userIdentifier: anyNamed('userIdentifier'),
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });

    group('debugging options', () {
      DebuggingOptions debuggingOptions;

      String testApp, testFile;

      setUp(() {
        restoreAppStarter();
      });

      Future<Device> appStarterSetup() async {
        final Device mockDevice = MockDevice();
        applyDdsMocks(mockDevice);
        testDeviceManager.addDevice(mockDevice);

        final FakeDeviceLogReader mockDeviceLogReader = FakeDeviceLogReader();
        when(mockDevice.getLogReader()).thenReturn(mockDeviceLogReader);
        final MockLaunchResult mockLaunchResult = MockLaunchResult();
        when(mockLaunchResult.started).thenReturn(true);
        when(mockDevice.startApp(
          null,
          mainPath: anyNamed('mainPath'),
          route: anyNamed('route'),
          debuggingOptions: anyNamed('debuggingOptions'),
          platformArgs: anyNamed('platformArgs'),
          prebuiltApplication: anyNamed('prebuiltApplication'),
          userIdentifier: anyNamed('userIdentifier'),
        )).thenAnswer((Invocation invocation) async {
          debuggingOptions = invocation.namedArguments[#debuggingOptions] as DebuggingOptions;
          return mockLaunchResult;
        });
        when(mockDevice.isAppInstalled(any, userIdentifier: anyNamed('userIdentifier')))
            .thenAnswer((_) => Future<bool>.value(false));

        testApp = globals.fs.path.join(tempDir.path, 'test', 'e2e.dart');
        testFile = globals.fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

        testRunner = (List<String> testArgs, Map<String, String> environment) async {
          throwToolExit(null, exitCode: 123);
        };
        appStopper = expectAsync1(
          (DriveCommand command) async {
            return true;
          },
          count: 2,
        );

        final MemoryFileSystem memFs = fs;
        await memFs.file(testApp).writeAsString('main() {}');
        await memFs.file(testFile).writeAsString('main() {}');
        return mockDevice;
      }

      void _testOptionThatDefaultsToFalse(
        String optionName,
        bool setToTrue,
        bool optionValue(),
      ) {
        testUsingContext('$optionName ${setToTrue ? 'works' : 'defaults to false'}', () async {
          final Device mockDevice = await appStarterSetup();

          final List<String> args = <String>[
            'drive',
            '--target=$testApp',
            if (setToTrue) optionName,
            '--no-pub',
          ];
          try {
            await createTestCommandRunner(command).run(args);
          } on ToolExit catch (e) {
            expect(e.exitCode, 123);
            expect(e.message, null);
          }
          verify(mockDevice.startApp(
            null,
            mainPath: anyNamed('mainPath'),
            route: anyNamed('route'),
            debuggingOptions: anyNamed('debuggingOptions'),
            platformArgs: anyNamed('platformArgs'),
            prebuiltApplication: false,
            userIdentifier: anyNamed('userIdentifier'),
          ));
          expect(optionValue(), setToTrue ? isTrue : isFalse);
        }, overrides: <Type, Generator>{
          FileSystem: () => fs,
          ProcessManager: () => FakeProcessManager.any(),
        });
      }

      void testOptionThatDefaultsToFalse(
        String optionName,
        bool optionValue(),
      ) {
        _testOptionThatDefaultsToFalse(optionName, true, optionValue);
        _testOptionThatDefaultsToFalse(optionName, false, optionValue);
      }

      testOptionThatDefaultsToFalse(
        '--dump-skp-on-shader-compilation',
        () => debuggingOptions.dumpSkpOnShaderCompilation,
      );

      testOptionThatDefaultsToFalse(
        '--verbose-system-logs',
        () => debuggingOptions.verboseSystemLogs,
      );

      testOptionThatDefaultsToFalse(
        '--cache-sksl',
        () => debuggingOptions.cacheSkSL,
      );

      testOptionThatDefaultsToFalse(
        '--purge-persistent-cache',
        () => debuggingOptions.purgePersistentCache,
      );
    });
  });

  group('getDesiredCapabilities', () {
    test('Chrome with headless on', () {
      final Map<String, dynamic> expected = <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'chrome',
        'goog:loggingPrefs': <String, String>{ sync_io.LogType.performance: 'ALL'},
        'chromeOptions': <String, dynamic>{
          'w3c': false,
          'args': <String>[
            '--bwsi',
            '--disable-background-timer-throttling',
            '--disable-default-apps',
            '--disable-extensions',
            '--disable-popup-blocking',
            '--disable-translate',
            '--no-default-browser-check',
            '--no-sandbox',
            '--no-first-run',
            '--headless'
          ],
          'perfLoggingPrefs': <String, String>{
            'traceCategories':
            'devtools.timeline,'
                'v8,blink.console,benchmark,blink,'
                'blink.user_timing'
          }
        }
      };

      expect(getDesiredCapabilities(Browser.chrome, true), expected);
    });

    test('Chrome with headless off', () {
      const String chromeBinary = 'random-binary';
      final Map<String, dynamic> expected = <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'chrome',
        'goog:loggingPrefs': <String, String>{ sync_io.LogType.performance: 'ALL'},
        'chromeOptions': <String, dynamic>{
          'binary': chromeBinary,
          'w3c': false,
          'args': <String>[
            '--bwsi',
            '--disable-background-timer-throttling',
            '--disable-default-apps',
            '--disable-extensions',
            '--disable-popup-blocking',
            '--disable-translate',
            '--no-default-browser-check',
            '--no-sandbox',
            '--no-first-run',
          ],
          'perfLoggingPrefs': <String, String>{
            'traceCategories':
            'devtools.timeline,'
                'v8,blink.console,benchmark,blink,'
                'blink.user_timing'
          }
        }
      };

      expect(getDesiredCapabilities(Browser.chrome, false, chromeBinary), expected);

    });

    test('Firefox with headless on', () {
      final Map<String, dynamic> expected = <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'firefox',
        'moz:firefoxOptions' : <String, dynamic>{
          'args': <String>['-headless'],
          'prefs': <String, dynamic>{
            'dom.file.createInChild': true,
            'dom.timeout.background_throttling_max_budget': -1,
            'media.autoplay.default': 0,
            'media.gmp-manager.url': '',
            'media.gmp-provider.enabled': false,
            'network.captive-portal-service.enabled': false,
            'security.insecure_field_warning.contextual.enabled': false,
            'test.currentTimeOffsetSeconds': 11491200
          },
          'log': <String, String>{'level': 'trace'}
        }
      };

      expect(getDesiredCapabilities(Browser.firefox, true), expected);
    });

    test('Firefox with headless off', () {
      final Map<String, dynamic> expected = <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'firefox',
        'moz:firefoxOptions' : <String, dynamic>{
          'args': <String>[],
          'prefs': <String, dynamic>{
            'dom.file.createInChild': true,
            'dom.timeout.background_throttling_max_budget': -1,
            'media.autoplay.default': 0,
            'media.gmp-manager.url': '',
            'media.gmp-provider.enabled': false,
            'network.captive-portal-service.enabled': false,
            'security.insecure_field_warning.contextual.enabled': false,
            'test.currentTimeOffsetSeconds': 11491200
          },
          'log': <String, String>{'level': 'trace'}
        }
      };

      expect(getDesiredCapabilities(Browser.firefox, false), expected);
    });

    test('Edge', () {
      final Map<String, dynamic> expected = <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'edge',
      };

      expect(getDesiredCapabilities(Browser.edge, false), expected);
    });

    test('macOS Safari', () {
      final Map<String, dynamic> expected = <String, dynamic>{
        'browserName': 'safari',
      };

      expect(getDesiredCapabilities(Browser.safari, false), expected);
    });

    test('iOS Safari', () {
      final Map<String, dynamic> expected = <String, dynamic>{
        'platformName': 'ios',
        'browserName': 'safari',
        'safari:useSimulator': true
      };

      expect(getDesiredCapabilities(Browser.iosSafari, false), expected);
    });

    test('android chrome', () {
      final Map<String, dynamic> expected = <String, dynamic>{
        'browserName': 'chrome',
        'platformName': 'android',
        'goog:chromeOptions': <String, dynamic>{
          'androidPackage': 'com.android.chrome',
          'args': <String>['--disable-fullscreen']
        },
      };

      expect(getDesiredCapabilities(Browser.androidChrome, false), expected);
    });
  });

  testUsingContext('Can write SkSL file with provided output file', () async {
    final MockDevice device = MockDevice();
    when(device.name).thenReturn('foo');
    when(device.targetPlatform).thenAnswer((Invocation invocation) async {
      return TargetPlatform.android_arm;
    });
    final File outputFile = globals.fs.file('out/foo');

    final String result = await sharedSkSlWriter(
      device,
      <String, Object>{'foo': 'bar'},
      outputFile: outputFile,
    );

    expect(result, 'out/foo');
    expect(outputFile, exists);
    expect(outputFile.readAsStringSync(), '{"platform":"android","name":"foo","engineRevision":null,"data":{"foo":"bar"}}');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class MockAndroidDevice extends Mock implements AndroidDevice { }
class MockDartDevelopmentService extends Mock implements DartDevelopmentService { }
class MockLaunchResult extends Mock implements LaunchResult { }
