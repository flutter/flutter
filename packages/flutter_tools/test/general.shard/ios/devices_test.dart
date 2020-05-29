// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  final FakePlatform macPlatform = FakePlatform(operatingSystem: 'macos');
  final FakePlatform linuxPlatform = FakePlatform(operatingSystem: 'linux');
  final FakePlatform windowsPlatform = FakePlatform(operatingSystem: 'windows');

  group('IOSDevice', () {
    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];
    Artifacts mockArtifacts;
    MockCache mockCache;
    Logger logger;
    IOSDeploy iosDeploy;
    IMobileDevice iMobileDevice;
    FileSystem mockFileSystem;

    setUp(() {
      mockArtifacts = MockArtifacts();
      mockCache = MockCache();
      const MapEntry<String, String> dyLdLibEntry = MapEntry<String, String>('DYLD_LIBRARY_PATH', '/path/to/libs');
      when(mockCache.dyLdLibEntry).thenReturn(dyLdLibEntry);
      logger = BufferLogger.test();
      iosDeploy = IOSDeploy(
        artifacts: mockArtifacts,
        cache: mockCache,
        logger: logger,
        platform: macPlatform,
        processManager: FakeProcessManager.any(),
      );
      iMobileDevice = IMobileDevice(
        artifacts: mockArtifacts,
        cache: mockCache,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );
    });

    testWithoutContext('successfully instantiates on Mac OS', () {
      IOSDevice(
        'device-123',
        artifacts: mockArtifacts,
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        sdkVersion: '13.3',
        cpuArchitecture: DarwinArch.arm64,
        interfaceType: IOSDeviceInterface.usb,
      );
    });

    testWithoutContext('parses major version', () {
      expect(IOSDevice(
        'device-123',
        artifacts: mockArtifacts,
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: '1.0.0',
        interfaceType: IOSDeviceInterface.usb,
      ).majorSdkVersion, 1);
      expect(IOSDevice(
        'device-123',
        artifacts: mockArtifacts,
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: '13.1.1',
        interfaceType: IOSDeviceInterface.usb,
      ).majorSdkVersion, 13);
      expect(IOSDevice(
        'device-123',
        artifacts: mockArtifacts,
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: '10',
        interfaceType: IOSDeviceInterface.usb,
      ).majorSdkVersion, 10);
      expect(IOSDevice(
        'device-123',
        artifacts: mockArtifacts,
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: '0',
        interfaceType: IOSDeviceInterface.usb,
      ).majorSdkVersion, 0);
      expect(IOSDevice(
        'device-123',
        artifacts: mockArtifacts,
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: 'bogus',
        interfaceType: IOSDeviceInterface.usb,
      ).majorSdkVersion, 0);
    });

    for (final Platform platform in unsupportedPlatforms) {
      testWithoutContext('throws UnsupportedError exception if instantiated on ${platform.operatingSystem}', () {
        expect(
          () {
            IOSDevice(
              'device-123',
              artifacts: mockArtifacts,
              fileSystem: mockFileSystem,
              logger: logger,
              platform: platform,
              iosDeploy: iosDeploy,
              iMobileDevice: iMobileDevice,
              name: 'iPhone 1',
              sdkVersion: '13.3',
              cpuArchitecture: DarwinArch.arm64,
              interfaceType: IOSDeviceInterface.usb,
            );
          },
          throwsAssertionError,
        );
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
      Artifacts mockArtifacts;
      MockCache mockCache;
      Logger logger;
      IOSDeploy iosDeploy;
      FileSystem mockFileSystem;

      IOSDevicePortForwarder createPortForwarder(
          ForwardedPort forwardedPort,
          IOSDevice device) {
        final IOSDevicePortForwarder portForwarder = IOSDevicePortForwarder(
          dyLdLibEntry: mockCache.dyLdLibEntry,
          id: device.id,
          iproxyPath: mockArtifacts.getArtifactPath(Artifact.iproxy, platform: TargetPlatform.ios),
          logger: logger,
          processManager: FakeProcessManager.any(),
        );
        portForwarder.addForwardedPorts(<ForwardedPort>[forwardedPort]);
        return portForwarder;
      }

      IOSDeviceLogReader createLogReader(
          IOSDevice device,
          IOSApp appPackage,
          Process process) {
        final IOSDeviceLogReader logReader = IOSDeviceLogReader.create(
          device: device,
          app: appPackage,
          iMobileDevice: null, // not used by this test.
        );
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
        mockArtifacts = MockArtifacts();
        mockCache = MockCache();
        iosDeploy = IOSDeploy(
          artifacts: mockArtifacts,
          cache: mockCache,
          logger: logger,
          platform: macPlatform,
          processManager: FakeProcessManager.any(),
        );
      });

      testWithoutContext('kills all log readers & port forwarders', () async {
        device = IOSDevice(
          '123',
          artifacts: mockArtifacts,
          fileSystem: mockFileSystem,
          logger: logger,
          platform: macPlatform,
          iosDeploy: iosDeploy,
          iMobileDevice: iMobileDevice,
          name: 'iPhone 1',
          sdkVersion: '13.3',
          cpuArchitecture: DarwinArch.arm64,
          interfaceType: IOSDeviceInterface.usb,
        );
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
      });
    });
  });

  group('pollingGetDevices', () {
    MockXcdevice mockXcdevice;
    MockArtifacts mockArtifacts;
    MockCache mockCache;
    FakeProcessManager fakeProcessManager;
    Logger logger;
    IOSDeploy iosDeploy;
    IMobileDevice iMobileDevice;
    IOSWorkflow mockIosWorkflow;

    setUp(() {
      mockXcdevice = MockXcdevice();
      mockArtifacts = MockArtifacts();
      mockCache = MockCache();
      logger = BufferLogger.test();
      mockIosWorkflow = MockIOSWorkflow();
      fakeProcessManager = FakeProcessManager.any();
      iosDeploy = IOSDeploy(
        artifacts: mockArtifacts,
        cache: mockCache,
        logger: logger,
        platform: macPlatform,
        processManager: fakeProcessManager,
      );
      iMobileDevice = IMobileDevice(
        artifacts: mockArtifacts,
        cache: mockCache,
        processManager: fakeProcessManager,
        logger: logger,
      );
    });

    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];
    for (final Platform unsupportedPlatform in unsupportedPlatforms) {
      testWithoutContext('throws Unsupported Operation exception on ${unsupportedPlatform.operatingSystem}', () async {
        final IOSDevices iosDevices = IOSDevices(
          platform: unsupportedPlatform,
          xcdevice: mockXcdevice,
          iosWorkflow: mockIosWorkflow,
        );
        when(mockXcdevice.isInstalled).thenReturn(false);
        expect(
            () async { await iosDevices.pollingGetDevices(); },
            throwsA(isA<UnsupportedError>()),
        );
      });
    }

    testWithoutContext('returns attached devices', () async {
      final IOSDevices iosDevices = IOSDevices(
        platform: macPlatform,
        xcdevice: mockXcdevice,
        iosWorkflow: mockIosWorkflow,
      );
      when(mockXcdevice.isInstalled).thenReturn(true);

      final IOSDevice device = IOSDevice(
        'd83d5bc53967baa0ee18626ba87b6254b2ab5418',
        name: 'Paired iPhone',
        sdkVersion: '13.3',
        cpuArchitecture: DarwinArch.arm64,
        artifacts: mockArtifacts,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        logger: logger,
        platform: macPlatform,
        fileSystem: MemoryFileSystem.test(),
        interfaceType: IOSDeviceInterface.usb,
      );
      when(mockXcdevice.getAvailableIOSDevices())
          .thenAnswer((Invocation invocation) => Future<List<IOSDevice>>.value(<IOSDevice>[device]));

      final List<Device> devices = await iosDevices.pollingGetDevices();
      expect(devices, hasLength(1));
      expect(identical(devices.first, device), isTrue);
    });
  });

  group('getDiagnostics', () {
    MockXcdevice mockXcdevice;
    IOSWorkflow mockIosWorkflow;

    setUp(() {
      mockXcdevice = MockXcdevice();
      mockIosWorkflow = MockIOSWorkflow();
    });

    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];
    for (final Platform unsupportedPlatform in unsupportedPlatforms) {
      testWithoutContext('throws returns platform diagnostic exception on ${unsupportedPlatform.operatingSystem}', () async {
        final IOSDevices iosDevices = IOSDevices(
          platform: unsupportedPlatform,
          xcdevice: mockXcdevice,
          iosWorkflow: mockIosWorkflow,
        );
        when(mockXcdevice.isInstalled).thenReturn(false);
        expect((await iosDevices.getDiagnostics()).first, 'Control of iOS devices or simulators only supported on macOS.');
      });
    }

    testWithoutContext('returns diagnostics', () async {
      final IOSDevices iosDevices = IOSDevices(
        platform: macPlatform,
        xcdevice: mockXcdevice,
        iosWorkflow: mockIosWorkflow,
      );
      when(mockXcdevice.isInstalled).thenReturn(true);
      when(mockXcdevice.getDiagnostics())
          .thenAnswer((Invocation invocation) => Future<List<String>>.value(<String>['Generic pairing error']));

      final List<String> diagnostics = await iosDevices.getDiagnostics();
      expect(diagnostics, hasLength(1));
      expect(diagnostics.first, 'Generic pairing error');
    });
  });
}

class MockIOSApp extends Mock implements IOSApp {}
class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockIOSDeploy extends Mock implements IOSDeploy {}
class MockIOSWorkflow extends Mock implements IOSWorkflow {}
class MockXcdevice extends Mock implements XCDevice {}
