// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:quiver/testing/async.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

class MockIOSApp extends Mock implements IOSApp {}
class MockApplicationPackage extends Mock implements ApplicationPackage {}
class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockDirectory extends Mock implements Directory {}
class MockFileSystem extends Mock implements FileSystem {}
class MockForwardedPort extends Mock implements ForwardedPort {}
class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockIOSDeploy extends Mock implements IOSDeploy {}
class MockDevicePortForwarder extends Mock implements DevicePortForwarder {}
class MockMDnsObservatoryDiscovery extends Mock implements MDnsObservatoryDiscovery {}
class MockMDnsObservatoryDiscoveryResult extends Mock implements MDnsObservatoryDiscoveryResult {}
class MockXcode extends Mock implements Xcode {}
class MockFile extends Mock implements File {}
class MockPortForwarder extends Mock implements DevicePortForwarder {}
class MockUsage extends Mock implements Usage {}
class MockXcdevice extends Mock implements XCDevice {}

void main() {
  final FakePlatform macPlatform = FakePlatform.fromPlatform(const LocalPlatform());
  macPlatform.operatingSystem = 'macos';
  final FakePlatform linuxPlatform = FakePlatform.fromPlatform(const LocalPlatform());
  linuxPlatform.operatingSystem = 'linux';
  final FakePlatform windowsPlatform = FakePlatform.fromPlatform(const LocalPlatform());
  windowsPlatform.operatingSystem = 'windows';

  group('IOSDevice', () {
    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];

    testUsingContext('successfully instantiates on Mac OS', () {
      IOSDevice('device-123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
    }, overrides: <Type, Generator>{
      Platform: () => macPlatform,
    });

    testUsingContext('parses major version', () {
      expect(IOSDevice('device-123', name: 'iPhone 1', cpuArchitecture: DarwinArch.arm64, sdkVersion: '1.0.0').majorSdkVersion, 1);
      expect(IOSDevice('device-123', name: 'iPhone 1', cpuArchitecture: DarwinArch.arm64, sdkVersion: '13.1.1').majorSdkVersion, 13);
      expect(IOSDevice('device-123', name: 'iPhone 1', cpuArchitecture: DarwinArch.arm64, sdkVersion: '10').majorSdkVersion, 10);
      expect(IOSDevice('device-123', name: 'iPhone 1', cpuArchitecture: DarwinArch.arm64, sdkVersion: '0').majorSdkVersion, 0);
      expect(IOSDevice('device-123', name: 'iPhone 1', cpuArchitecture: DarwinArch.arm64, sdkVersion: 'bogus').majorSdkVersion, 0);
    }, overrides: <Type, Generator>{
      Platform: () => macPlatform,
    });

    for (final Platform platform in unsupportedPlatforms) {
      testUsingContext('throws UnsupportedError exception if instantiated on ${platform.operatingSystem}', () {
        expect(
          () { IOSDevice('device-123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64); },
          throwsAssertionError,
        );
      }, overrides: <Type, Generator>{
        Platform: () => platform,
      });
    }

    group('.dispose()', () {
      IOSDevice device;
      MockIOSApp appPackage1;
      MockIOSApp appPackage2;
      IOSDeviceLogReader logReader1;
      IOSDeviceLogReader logReader2;
      MockProcess mockProcess1;
      MockProcess mockProcess2;
      MockProcess mockProcess3;
      IOSDevicePortForwarder portForwarder;
      ForwardedPort forwardedPort;

      IOSDevicePortForwarder createPortForwarder(
          ForwardedPort forwardedPort,
          IOSDevice device) {
        final IOSDevicePortForwarder portForwarder = IOSDevicePortForwarder(device);
        portForwarder.addForwardedPorts(<ForwardedPort>[forwardedPort]);
        return portForwarder;
      }

      IOSDeviceLogReader createLogReader(
          IOSDevice device,
          IOSApp appPackage,
          Process process) {
        final IOSDeviceLogReader logReader = IOSDeviceLogReader(device, appPackage);
        logReader.idevicesyslogProcess = process;
        return logReader;
      }

      setUp(() {
        appPackage1 = MockIOSApp();
        appPackage2 = MockIOSApp();
        when(appPackage1.name).thenReturn('flutterApp1');
        when(appPackage2.name).thenReturn('flutterApp2');
        mockProcess1 = MockProcess();
        mockProcess2 = MockProcess();
        mockProcess3 = MockProcess();
        forwardedPort = ForwardedPort.withContext(123, 456, mockProcess3);
      });

      testUsingContext(' kills all log readers & port forwarders', () async {
        device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        logReader1 = createLogReader(device, appPackage1, mockProcess1);
        logReader2 = createLogReader(device, appPackage2, mockProcess2);
        portForwarder = createPortForwarder(forwardedPort, device);
        device.setLogReader(appPackage1, logReader1);
        device.setLogReader(appPackage2, logReader2);
        device.portForwarder = portForwarder;

        await device.dispose();

        verify(mockProcess1.kill());
        verify(mockProcess2.kill());
        verify(mockProcess3.kill());
      }, overrides: <Type, Generator>{
        Platform: () => macPlatform,
      });
    });

    group('startApp', () {
      MockIOSApp mockApp;
      MockArtifacts mockArtifacts;
      MockCache mockCache;
      MockFileSystem mockFileSystem;
      MockProcessManager mockProcessManager;
      MockDeviceLogReader mockLogReader;
      MockMDnsObservatoryDiscovery mockMDnsObservatoryDiscovery;
      MockPortForwarder mockPortForwarder;
      MockIMobileDevice mockIMobileDevice;
      MockIOSDeploy mockIosDeploy;
      MockUsage mockUsage;

      Directory tempDir;
      Directory projectDir;

      const int devicePort = 499;
      const int hostPort = 42;
      const String installerPath = '/path/to/ideviceinstaller';
      const String iosDeployPath = '/path/to/iosdeploy';
      const String iproxyPath = '/path/to/iproxy';
      const MapEntry<String, String> libraryEntry = MapEntry<String, String>(
          'DYLD_LIBRARY_PATH',
          '/path/to/libraries',
      );
      final Map<String, String> env = Map<String, String>.fromEntries(
          <MapEntry<String, String>>[libraryEntry]
      );

      setUp(() {
        Cache.disableLocking();

        mockApp = MockIOSApp();
        mockArtifacts = MockArtifacts();
        mockCache = MockCache();
        when(mockCache.dyLdLibEntry).thenReturn(libraryEntry);
        mockFileSystem = MockFileSystem();
        mockMDnsObservatoryDiscovery = MockMDnsObservatoryDiscovery();
        mockProcessManager = MockProcessManager();
        mockLogReader = MockDeviceLogReader();
        mockPortForwarder = MockPortForwarder();
        mockIMobileDevice = MockIMobileDevice();
        mockIosDeploy = MockIOSDeploy();
        mockUsage = MockUsage();

        tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_create_test.');
        projectDir = tempDir.childDirectory('flutter_project');

        when(
            mockArtifacts.getArtifactPath(
                Artifact.ideviceinstaller,
                platform: anyNamed('platform'),
            ),
        ).thenReturn(installerPath);

        when(
            mockArtifacts.getArtifactPath(
                Artifact.iosDeploy,
                platform: anyNamed('platform'),
            ),
        ).thenReturn(iosDeployPath);

        when(
            mockArtifacts.getArtifactPath(
                Artifact.iproxy,
                platform: anyNamed('platform'),
            ),
        ).thenReturn(iproxyPath);

        when(mockPortForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
          .thenAnswer((_) async => hostPort);
        when(mockPortForwarder.forwardedPorts)
          .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
        when(mockPortForwarder.unforward(any))
          .thenAnswer((_) async => null);

        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        when(mockFileSystem.currentDirectory)
          .thenReturn(memoryFileSystem.currentDirectory);

        const String bundlePath = '/path/to/bundle';
        final List<String> installArgs = <String>[installerPath, '-i', bundlePath];
        when(mockApp.deviceBundlePath).thenReturn(bundlePath);
        final MockDirectory directory = MockDirectory();
        when(mockFileSystem.directory(bundlePath)).thenReturn(directory);
        when(directory.existsSync()).thenReturn(true);
        when(mockProcessManager.run(
          installArgs,
          workingDirectory: anyNamed('workingDirectory'),
          environment: env,
        )).thenAnswer(
          (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
        );
      });

      tearDown(() {
        mockLogReader.dispose();
        tryToDelete(tempDir);

        Cache.enableLocking();
      });

      testUsingContext('disposing device disposes the portForwarder', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        device.portForwarder = mockPortForwarder;
        device.setLogReader(mockApp, mockLogReader);
        await device.dispose();
        verify(mockPortForwarder.dispose()).called(1);
      }, overrides: <Type, Generator>{
        Platform: () => macPlatform,
      });

      testUsingContext(' succeeds in debug mode via mDNS', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        device.portForwarder = mockPortForwarder;
        device.setLogReader(mockApp, mockLogReader);
        final Uri uri = Uri(
          scheme: 'http',
          host: '127.0.0.1',
          port: 1234,
          path: 'observatory',
        );
        when(mockMDnsObservatoryDiscovery.getObservatoryUri(any, any, usesIpv6: anyNamed('usesIpv6')))
          .thenAnswer((Invocation invocation) => Future<Uri>.value(uri));

        final LaunchResult launchResult = await device.startApp(mockApp,
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.enabled(const BuildInfo(BuildMode.debug, null, treeShakeIcons: false)),
          platformArgs: <String, dynamic>{},
        );
        verify(mockUsage.sendEvent('ios-handshake', 'mdns-success')).called(1);
        expect(launchResult.started, isTrue);
        expect(launchResult.hasObservatory, isTrue);
        expect(await device.stopApp(mockApp), isFalse);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        FileSystem: () => mockFileSystem,
        MDnsObservatoryDiscovery: () => mockMDnsObservatoryDiscovery,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
        Usage: () => mockUsage,
      });

      // By default, the .forward() method will try every port between 1024
      // and 65535; this test verifies we are killing iproxy processes when
      // we timeout on a port
      testUsingContext(' .forward() will kill iproxy processes before invoking a second', () async {
        const String deviceId = '123';
        const int devicePort = 456;
        final IOSDevice device = IOSDevice(deviceId, name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        final IOSDevicePortForwarder portForwarder = IOSDevicePortForwarder(device);
        bool firstRun = true;
        final MockProcess successProcess = MockProcess(
          exitCode: Future<int>.value(0),
          stdout: Stream<List<int>>.fromIterable(<List<int>>['Hello'.codeUnits]),
        );
        final MockProcess failProcess = MockProcess(
          exitCode: Future<int>.value(1),
          stdout: const Stream<List<int>>.empty(),
        );

        final ProcessFactory factory = (List<String> command) {
          if (!firstRun) {
            return successProcess;
          }
          firstRun = false;
          return failProcess;
        };
        mockProcessManager.processFactory = factory;
        final int hostPort = await portForwarder.forward(devicePort);
        // First port tried (1024) should fail, then succeed on the next
        expect(hostPort, 1024 + 1);
        verifyNever(successProcess.kill());
        verify(failProcess.kill());
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
        Usage: () => mockUsage,
      });

      testUsingContext(' succeeds in debug mode when mDNS fails by falling back to manual protocol discovery', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        device.portForwarder = mockPortForwarder;
        device.setLogReader(mockApp, mockLogReader);
        // Now that the reader is used, start writing messages to it.
        Timer.run(() {
          mockLogReader.addLine('Foo');
          mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
        });
        when(mockMDnsObservatoryDiscovery.getObservatoryUri(any, any, usesIpv6: anyNamed('usesIpv6')))
          .thenAnswer((Invocation invocation) => Future<Uri>.value(null));

        final LaunchResult launchResult = await device.startApp(mockApp,
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.enabled(const BuildInfo(BuildMode.debug, null, treeShakeIcons: false)),
          platformArgs: <String, dynamic>{},
        );
        verify(mockUsage.sendEvent('ios-handshake', 'mdns-failure')).called(1);
        verify(mockUsage.sendEvent('ios-handshake', 'fallback-success')).called(1);
        expect(launchResult.started, isTrue);
        expect(launchResult.hasObservatory, isTrue);
        expect(await device.stopApp(mockApp), isFalse);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        FileSystem: () => mockFileSystem,
        MDnsObservatoryDiscovery: () => mockMDnsObservatoryDiscovery,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
        Usage: () => mockUsage,
      });

      testUsingContext(' fails in debug mode when mDNS fails and when Observatory URI is malformed', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        device.portForwarder = mockPortForwarder;
        device.setLogReader(mockApp, mockLogReader);

        // Now that the reader is used, start writing messages to it.
        Timer.run(() {
          mockLogReader.addLine('Foo');
          mockLogReader.addLine('Observatory listening on http:/:/127.0.0.1:$devicePort');
        });
        when(mockMDnsObservatoryDiscovery.getObservatoryUri(any, any, usesIpv6: anyNamed('usesIpv6')))
          .thenAnswer((Invocation invocation) => Future<Uri>.value(null));

        final LaunchResult launchResult = await device.startApp(mockApp,
            prebuiltApplication: true,
            debuggingOptions: DebuggingOptions.enabled(const BuildInfo(BuildMode.debug, null, treeShakeIcons: false)),
            platformArgs: <String, dynamic>{},
        );
        verify(mockUsage.sendEvent(
          'ios-handshake',
          'failure',
          label: anyNamed('label'),
          value: anyNamed('value'),
        )).called(1);
        verify(mockUsage.sendEvent('ios-handshake', 'mdns-failure')).called(1);
        verify(mockUsage.sendEvent('ios-handshake', 'fallback-failure')).called(1);
        expect(launchResult.started, isFalse);
        expect(launchResult.hasObservatory, isFalse);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        FileSystem: () => mockFileSystem,
        MDnsObservatoryDiscovery: () => mockMDnsObservatoryDiscovery,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
        Usage: () => mockUsage,
      });

      testUsingContext('succeeds in release mode', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        final LaunchResult launchResult = await device.startApp(mockApp,
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.disabled(const BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
          platformArgs: <String, dynamic>{},
        );
        expect(launchResult.started, isTrue);
        expect(launchResult.hasObservatory, isFalse);
        expect(await device.stopApp(mockApp), isFalse);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        FileSystem: () => mockFileSystem,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('succeeds with --cache-sksl', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        device.setLogReader(mockApp, mockLogReader);
        final Uri uri = Uri(
          scheme: 'http',
          host: '127.0.0.1',
          port: 1234,
          path: 'observatory',
        );
        when(mockMDnsObservatoryDiscovery.getObservatoryUri(any, any, usesIpv6: anyNamed('usesIpv6')))
            .thenAnswer((Invocation invocation) => Future<Uri>.value(uri));

        List<String> args;
        when(mockIosDeploy.runApp(
          deviceId: anyNamed('deviceId'),
          bundlePath: anyNamed('bundlePath'),
          launchArguments: anyNamed('launchArguments'),
        )).thenAnswer((Invocation inv) {
          args = inv.namedArguments[const Symbol('launchArguments')] as List<String>;
          return Future<int>.value(0);
        });

        final LaunchResult launchResult = await device.startApp(mockApp,
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.enabled(
              const BuildInfo(BuildMode.debug, null, treeShakeIcons: false),
              cacheSkSL: true,
          ),
          platformArgs: <String, dynamic>{},
        );
        expect(launchResult.started, isTrue);
        expect(args, contains('--cache-sksl'));
        expect(await device.stopApp(mockApp), isFalse);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        FileSystem: () => mockFileSystem,
        MDnsObservatoryDiscovery: () => mockMDnsObservatoryDiscovery,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
        Usage: () => mockUsage,
        IOSDeploy: () => mockIosDeploy,
      });

      testUsingContext('succeeds with --device-vmservice-port', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        device.setLogReader(mockApp, mockLogReader);
        final Uri uri = Uri(
          scheme: 'http',
          host: '127.0.0.1',
          port: 1234,
          path: 'observatory',
        );
        when(mockMDnsObservatoryDiscovery.getObservatoryUri(any, any, usesIpv6: anyNamed('usesIpv6')))
            .thenAnswer((Invocation invocation) => Future<Uri>.value(uri));

        List<String> args;
        when(mockIosDeploy.runApp(
          deviceId: anyNamed('deviceId'),
          bundlePath: anyNamed('bundlePath'),
          launchArguments: anyNamed('launchArguments'),
        )).thenAnswer((Invocation inv) {
          args = inv.namedArguments[const Symbol('launchArguments')] as List<String>;
          return Future<int>.value(0);
        });

        final LaunchResult launchResult = await device.startApp(mockApp,
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.enabled(
            const BuildInfo(BuildMode.debug, null, treeShakeIcons: false),
            deviceVmServicePort: 8181,
          ),
          platformArgs: <String, dynamic>{},
        );
        expect(launchResult.started, isTrue);
        expect(args, contains('--observatory-port=8181'));
        expect(await device.stopApp(mockApp), isFalse);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        FileSystem: () => mockFileSystem,
        MDnsObservatoryDiscovery: () => mockMDnsObservatoryDiscovery,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
        Usage: () => mockUsage,
        IOSDeploy: () => mockIosDeploy,
      });

      void testNonPrebuilt(
        String name, {
        @required bool showBuildSettingsFlakes,
        void Function() additionalSetup,
        void Function() additionalExpectations,
      }) {
        testUsingContext('non-prebuilt succeeds in debug mode $name', () async {
          final Directory targetBuildDir =
              projectDir.childDirectory('build/ios/iphoneos/Debug-arm64');

          // The -showBuildSettings calls have a timeout and so go through
          // globals.processManager.start().
          mockProcessManager.processFactory = flakyProcessFactory(
            flakes: showBuildSettingsFlakes ? 1 : 0,
            delay: const Duration(seconds: 62),
            filter: (List<String> args) => args.contains('-showBuildSettings'),
            stdout:
                () => Stream<String>
                  .fromIterable(
                      <String>['TARGET_BUILD_DIR = ${targetBuildDir.path}\n'])
                  .transform(utf8.encoder),
          );

          // Make all other subcommands succeed.
          when(mockProcessManager.run(
              any,
              workingDirectory: anyNamed('workingDirectory'),
              environment: anyNamed('environment'),
          )).thenAnswer((Invocation inv) {
            return Future<ProcessResult>.value(ProcessResult(0, 0, '', ''));
          });

          when(mockProcessManager.run(
            argThat(contains('find-identity')),
            environment: anyNamed('environment'),
            workingDirectory: anyNamed('workingDirectory'),
          )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
                1, // pid
                0, // exitCode
                '''
    1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
    2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
    3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
        3 valid identities found''',
                '',
          )));

          // Deploy works.
          when(mockIosDeploy.runApp(
            deviceId: anyNamed('deviceId'),
            bundlePath: anyNamed('bundlePath'),
            launchArguments: anyNamed('launchArguments'),
          )).thenAnswer((_) => Future<int>.value(0));

          // Create a dummy project to avoid mocking out the whole directory
          // structure expected by device.startApp().
          Cache.flutterRoot = '../..';
          final CreateCommand command = CreateCommand();
          final CommandRunner<void> runner = createTestCommandRunner(command);
          await runner.run(<String>[
            'create',
            '--no-pub',
            projectDir.path,
          ]);

          if (additionalSetup != null) {
            additionalSetup();
          }

          final IOSApp app = await AbsoluteBuildableIOSApp.fromProject(
            FlutterProject.fromDirectory(projectDir).ios);
          final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);

          // Pre-create the expected build products.
          targetBuildDir.createSync(recursive: true);
          projectDir.childDirectory('build/ios/iphoneos/Runner.app').createSync(recursive: true);

          final Completer<LaunchResult> completer = Completer<LaunchResult>();
          FakeAsync().run((FakeAsync time) {
            device.startApp(
              app,
              prebuiltApplication: false,
              debuggingOptions: DebuggingOptions.disabled(const BuildInfo(BuildMode.debug, null, treeShakeIcons: false)),
              platformArgs: <String, dynamic>{},
            ).then((LaunchResult result) {
              completer.complete(result);
            });
            time.flushMicrotasks();
            time.elapse(const Duration(seconds: 65));
          });
          final LaunchResult launchResult = await completer.future;
          expect(launchResult.started, isTrue);
          expect(launchResult.hasObservatory, isFalse);
          expect(await device.stopApp(mockApp), isFalse);

          if (additionalExpectations != null) {
            additionalExpectations();
          }
        }, overrides: <Type, Generator>{
          DoctorValidatorsProvider: () => FakeIosDoctorProvider(),
          IMobileDevice: () => mockIMobileDevice,
          IOSDeploy: () => mockIosDeploy,
          Platform: () => macPlatform,
          ProcessManager: () => mockProcessManager,
        });
      }

      testNonPrebuilt('flaky: false', showBuildSettingsFlakes: false);
      testNonPrebuilt('flaky: true', showBuildSettingsFlakes: true);
      testNonPrebuilt('with concurrent build failiure',
        showBuildSettingsFlakes: false,
        additionalSetup: () {
          int callCount = 0;
          when(mockProcessManager.run(
            argThat(allOf(
              contains('xcodebuild'),
              contains('-configuration'),
              contains('Debug'),
            )),
            workingDirectory: anyNamed('workingDirectory'),
            environment: anyNamed('environment'),
          )).thenAnswer((Invocation inv) {
            // Succeed after 2 calls.
            if (++callCount > 2) {
              return Future<ProcessResult>.value(ProcessResult(0, 0, '', ''));
            }
            // Otherwise fail with the Xcode concurrent error.
            return Future<ProcessResult>.value(ProcessResult(
              0,
              1,
              '''
                "/Developer/Xcode/DerivedData/foo/XCBuildData/build.db":
                database is locked
                Possibly there are two concurrent builds running in the same filesystem location.
                ''',
              '',
            ));
          });
        },
        additionalExpectations: () {
          expect(testLogger.statusText, contains('will retry in 2 seconds'));
          expect(testLogger.statusText, contains('will retry in 4 seconds'));
          expect(testLogger.statusText, contains('Xcode build done.'));
        },
      );
    });

    group('Process calls', () {
      MockIOSApp mockApp;
      MockArtifacts mockArtifacts;
      MockCache mockCache;
      MockFileSystem mockFileSystem;
      MockProcessManager mockProcessManager;
      const String installerPath = '/path/to/ideviceinstaller';
      const String appId = '789';
      const MapEntry<String, String> libraryEntry = MapEntry<String, String>(
        'DYLD_LIBRARY_PATH',
        '/path/to/libraries',
      );
      final Map<String, String> env = Map<String, String>.fromEntries(
          <MapEntry<String, String>>[libraryEntry]
      );

      setUp(() {
        mockApp = MockIOSApp();
        mockArtifacts = MockArtifacts();
        mockCache = MockCache();
        when(mockCache.dyLdLibEntry).thenReturn(libraryEntry);
        mockFileSystem = MockFileSystem();
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        when(mockFileSystem.currentDirectory)
          .thenReturn(memoryFileSystem.currentDirectory);
        mockProcessManager = MockProcessManager();
        when(
            mockArtifacts.getArtifactPath(
                Artifact.ideviceinstaller,
                platform: anyNamed('platform'),
            ),
        ).thenReturn(installerPath);
      });

      testUsingContext('installApp() invokes process with correct environment', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        const String bundlePath = '/path/to/bundle';
        final List<String> args = <String>[installerPath, '-i', bundlePath];
        when(mockApp.deviceBundlePath).thenReturn(bundlePath);
        final MockDirectory directory = MockDirectory();
        when(mockFileSystem.directory(bundlePath)).thenReturn(directory);
        when(directory.existsSync()).thenReturn(true);
        when(mockProcessManager.run(args, environment: env))
            .thenAnswer(
                (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
            );
        await device.installApp(mockApp);
        verify(mockProcessManager.run(args, environment: env));
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        FileSystem: () => mockFileSystem,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('isAppInstalled() invokes process with correct environment', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        final List<String> args = <String>[installerPath, '--list-apps'];
        when(mockProcessManager.run(args, environment: env))
            .thenAnswer(
                (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
            );
        when(mockApp.id).thenReturn(appId);
        await device.isAppInstalled(mockApp);
        verify(mockProcessManager.run(args, environment: env));
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('uninstallApp() invokes process with correct environment', () async {
        final IOSDevice device = IOSDevice('123', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
        final List<String> args = <String>[installerPath, '-U', appId];
        when(mockApp.id).thenReturn(appId);
        when(mockProcessManager.run(args, environment: env))
            .thenAnswer(
                (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
            );
        await device.uninstallApp(mockApp);
        verify(mockProcessManager.run(args, environment: env));
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
      });
    });
  });

  group('getAttachedDevices', () {
    MockXcdevice mockXcdevice;

    setUp(() {
      mockXcdevice = MockXcdevice();
    });

    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];
    for (final Platform unsupportedPlatform in unsupportedPlatforms) {
      testWithoutContext('throws Unsupported Operation exception on ${unsupportedPlatform.operatingSystem}', () async {
        when(mockXcdevice.isInstalled).thenReturn(false);
        expect(
            () async { await IOSDevice.getAttachedDevices(unsupportedPlatform, mockXcdevice); },
            throwsA(isA<UnsupportedError>()),
        );
      });
    }

    testUsingContext('returns attached devices', () async {
      when(mockXcdevice.isInstalled).thenReturn(true);
      final IOSDevice device = IOSDevice('d83d5bc53967baa0ee18626ba87b6254b2ab5418', name: 'Paired iPhone', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64);
      when(mockXcdevice.getAvailableTetheredIOSDevices())
          .thenAnswer((Invocation invocation) => Future<List<IOSDevice>>.value(<IOSDevice>[device]));

      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices(macPlatform, mockXcdevice);
      expect(devices, hasLength(1));
      expect(identical(devices.first, device), isTrue);
    }, overrides: <Type, Generator>{
      Platform: () => macPlatform,
    });
  });

  group('getDiagnostics', () {
    MockXcdevice mockXcdevice;

    setUp(() {
      mockXcdevice = MockXcdevice();
    });

    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];
    for (final Platform unsupportedPlatform in unsupportedPlatforms) {
      testWithoutContext('throws returns platform diagnostic exception on ${unsupportedPlatform.operatingSystem}', () async {
        when(mockXcdevice.isInstalled).thenReturn(false);
        expect((await IOSDevice.getDiagnostics(unsupportedPlatform, mockXcdevice)).first, 'Control of iOS devices or simulators only supported on macOS.');
      });
    }

    testUsingContext('returns diagnostics', () async {
      when(mockXcdevice.isInstalled).thenReturn(true);
      when(mockXcdevice.getDiagnostics())
          .thenAnswer((Invocation invocation) => Future<List<String>>.value(<String>['Generic pairing error']));

      final List<String> diagnostics = await IOSDevice.getDiagnostics(macPlatform, mockXcdevice);
      expect(diagnostics, hasLength(1));
      expect(diagnostics.first, 'Generic pairing error');
    }, overrides: <Type, Generator>{
      Platform: () => macPlatform,
    });
  });

  group('decodeSyslog', () {
    test('decodes a syslog-encoded line', () {
      final String decoded = decodeSyslog(r'I \M-b\M^]\M-$\M-o\M-8\M^O syslog \M-B\M-/\134_(\M-c\M^C\M^D)_/\M-B\M-/ \M-l\M^F\240!');
      expect(decoded, r'I ❤️ syslog ¯\_(ツ)_/¯ 솠!');
    });

    test('passes through un-decodeable lines as-is', () {
      final String decoded = decodeSyslog(r'I \M-b\M^O syslog!');
      expect(decoded, r'I \M-b\M^O syslog!');
    });
  });
  group('logging', () {
    MockIMobileDevice mockIMobileDevice;
    MockIosProject mockIosProject;

    setUp(() {
      mockIMobileDevice = MockIMobileDevice();
      mockIosProject = MockIosProject();
    });

    testUsingContext('suppresses non-Flutter lines from output', () async {
      when(mockIMobileDevice.startLogger('123456')).thenAnswer((Invocation invocation) {
        final Process mockProcess = MockProcess(
          stdout: Stream<List<int>>.fromIterable(<List<int>>['''
Runner(Flutter)[297] <Notice>: A is for ari
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestaltSupport.m:153: pid 123 (Runner) does not have sandbox access for frZQaeyWLUvLjeuEK43hmg and IS NOT appropriately entitled
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestalt.c:550: no access to InverseDeviceID (see <rdar://problem/11744455>)
Runner(Flutter)[297] <Notice>: I is for ichigo
Runner(UIKit)[297] <Notice>: E is for enpitsu"
'''.codeUnits])
        );
        return Future<Process>.value(mockProcess);
      });

      final IOSDevice device = IOSDevice('123456', name: 'iPhone 1', sdkVersion: '10.3', cpuArchitecture: DarwinArch.arm64);
      final DeviceLogReader logReader = device.getLogReader(
        app: await BuildableIOSApp.fromProject(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>['A is for ari', 'I is for ichigo']);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
      Platform: () => macPlatform,
    });

    testUsingContext('includes multi-line Flutter logs in the output', () async {
      when(mockIMobileDevice.startLogger('123456')).thenAnswer((Invocation invocation) {
        final Process mockProcess = MockProcess(
          stdout: Stream<List<int>>.fromIterable(<List<int>>['''
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with another Flutter message following it.
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with a non-Flutter log message following it.
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt
'''.codeUnits]),
        );
        return Future<Process>.value(mockProcess);
      });

      final IOSDevice device = IOSDevice('123456', name: 'iPhone 1', sdkVersion: '10.3', cpuArchitecture: DarwinArch.arm64);
      final DeviceLogReader logReader = device.getLogReader(
        app: await BuildableIOSApp.fromProject(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>[
        'This is a multi-line message,',
        '  with another Flutter message following it.',
        'This is a multi-line message,',
        '  with a non-Flutter log message following it.',
      ]);
      expect(device.category, Category.mobile);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
      Platform: () => macPlatform,
    });
  });
  testUsingContext('IOSDevice.isSupportedForProject is true on module project', () async {
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example

flutter:
  module: {}
''');
    globals.fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64).isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macPlatform,
  });
  testUsingContext('IOSDevice.isSupportedForProject is true with editable host app', () async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.directory('ios').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64).isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macPlatform,
  });

  testUsingContext('IOSDevice.isSupportedForProject is false with no host app and no module', () async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test', name: 'iPhone 1', sdkVersion: '13.3', cpuArchitecture: DarwinArch.arm64).isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macPlatform,
  });
}

class AbsoluteBuildableIOSApp extends BuildableIOSApp {
  AbsoluteBuildableIOSApp(IosProject project, String projectBundleId) :
    super(project, projectBundleId);

  static Future<AbsoluteBuildableIOSApp> fromProject(IosProject project) async {
    final String projectBundleId = await project.productBundleIdentifier;
    return AbsoluteBuildableIOSApp(project, projectBundleId);
  }

  @override
  String get deviceBundlePath =>
      globals.fs.path.join(project.parent.directory.path, 'build', 'ios', 'iphoneos', name);

}

class FakeIosDoctorProvider implements DoctorValidatorsProvider {
  List<Workflow> _workflows;

  @override
  List<DoctorValidator> get validators => <DoctorValidator>[];

  @override
  List<Workflow> get workflows {
    if (_workflows == null) {
      _workflows = <Workflow>[];
      if (iosWorkflow.appliesToHostPlatform) {
        _workflows.add(iosWorkflow);
      }
    }
    return _workflows;
  }
}
