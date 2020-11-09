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
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart';

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
    MockVmService mockVmService;
    Logger logger;
    IOSDeploy iosDeploy;
    IMobileDevice iMobileDevice;
    FileSystem mockFileSystem;

    setUp(() {
      mockArtifacts = MockArtifacts();
      mockCache = MockCache();
      mockVmService = MockVmService();
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
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        sdkVersion: '13.3',
        cpuArchitecture: DarwinArch.arm64,
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
      );
    });

    testWithoutContext('parses major version', () {
      expect(IOSDevice(
        'device-123',
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: '1.0.0',
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
      ).majorSdkVersion, 1);
      expect(IOSDevice(
        'device-123',
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: '13.1.1',
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
      ).majorSdkVersion, 13);
      expect(IOSDevice(
        'device-123',
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: '10',
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
      ).majorSdkVersion, 10);
      expect(IOSDevice(
        'device-123',
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: '0',
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
      ).majorSdkVersion, 0);
      expect(IOSDevice(
        'device-123',
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        cpuArchitecture: DarwinArch.arm64,
        sdkVersion: 'bogus',
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
      ).majorSdkVersion, 0);
    });

    testWithoutContext('Supports debug, profile, and release modes', () {
      final IOSDevice device = IOSDevice(
        'device-123',
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        fileSystem: mockFileSystem,
        logger: logger,
        platform: macPlatform,
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        name: 'iPhone 1',
        sdkVersion: '13.3',
        cpuArchitecture: DarwinArch.arm64,
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
      );

      expect(device.supportsRuntimeMode(BuildMode.debug), true);
      expect(device.supportsRuntimeMode(BuildMode.profile), true);
      expect(device.supportsRuntimeMode(BuildMode.release), true);
      expect(device.supportsRuntimeMode(BuildMode.jitRelease), false);
    });

    for (final Platform platform in unsupportedPlatforms) {
      testWithoutContext('throws UnsupportedError exception if instantiated on ${platform.operatingSystem}', () {
        expect(
          () {
            IOSDevice(
              'device-123',
              iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
              fileSystem: mockFileSystem,
              logger: logger,
              platform: platform,
              iosDeploy: iosDeploy,
              iMobileDevice: iMobileDevice,
              name: 'iPhone 1',
              sdkVersion: '13.3',
              cpuArchitecture: DarwinArch.arm64,
              interfaceType: IOSDeviceInterface.usb,
              vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
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
      IProxy iproxy;

      IOSDevicePortForwarder createPortForwarder(
          ForwardedPort forwardedPort,
          IOSDevice device) {
        iproxy = IProxy.test(logger: logger, processManager: FakeProcessManager.any());
        final IOSDevicePortForwarder portForwarder = IOSDevicePortForwarder(
          id: device.id,
          logger: logger,
          operatingSystemUtils: OperatingSystemUtils(
            fileSystem: mockFileSystem,
            logger: logger,
            platform: FakePlatform(operatingSystem: 'macos'),
            processManager: FakeProcessManager.any(),
          ),
          iproxy: iproxy,
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
          iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
          fileSystem: mockFileSystem,
          logger: logger,
          platform: macPlatform,
          iosDeploy: iosDeploy,
          iMobileDevice: iMobileDevice,
          name: 'iPhone 1',
          sdkVersion: '13.3',
          cpuArchitecture: DarwinArch.arm64,
          interfaceType: IOSDeviceInterface.usb,
          vmServiceConnectUri: (String string, {Log log}) async => mockVmService,
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

  group('polling', () {
    MockXcdevice mockXcdevice;
    MockArtifacts mockArtifacts;
    MockCache mockCache;
    MockVmService mockVmService1;
    MockVmService mockVmService2;
    FakeProcessManager fakeProcessManager;
    BufferLogger logger;
    IOSDeploy iosDeploy;
    IMobileDevice iMobileDevice;
    IOSWorkflow mockIosWorkflow;
    IOSDevice device1;
    IOSDevice device2;

    setUp(() {
      mockXcdevice = MockXcdevice();
      mockArtifacts = MockArtifacts();
      mockCache = MockCache();
      mockVmService1 = MockVmService();
      mockVmService2 = MockVmService();
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

      device1 = IOSDevice(
        'd83d5bc53967baa0ee18626ba87b6254b2ab5418',
        name: 'Paired iPhone',
        sdkVersion: '13.3',
        cpuArchitecture: DarwinArch.arm64,
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        logger: logger,
        platform: macPlatform,
        fileSystem: MemoryFileSystem.test(),
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService1,
      );

      device2 = IOSDevice(
        '00008027-00192736010F802E',
        name: 'iPad Pro',
        sdkVersion: '13.3',
        cpuArchitecture: DarwinArch.arm64,
        iProxy: IProxy.test(logger: logger, processManager: FakeProcessManager.any()),
        iosDeploy: iosDeploy,
        iMobileDevice: iMobileDevice,
        logger: logger,
        platform: macPlatform,
        fileSystem: MemoryFileSystem.test(),
        interfaceType: IOSDeviceInterface.usb,
        vmServiceConnectUri: (String string, {Log log}) async => mockVmService2,
      );
    });

    testWithoutContext('start polling without Xcode', () async {
      final IOSDevices iosDevices = IOSDevices(
        platform: macPlatform,
        xcdevice: mockXcdevice,
        iosWorkflow: mockIosWorkflow,
        logger: logger,
      );
      when(mockXcdevice.isInstalled).thenReturn(false);

      await iosDevices.startPolling();
      verifyNever(mockXcdevice.getAvailableIOSDevices());
    });

    testWithoutContext('start polling', () async {
      final IOSDevices iosDevices = IOSDevices(
        platform: macPlatform,
        xcdevice: mockXcdevice,
        iosWorkflow: mockIosWorkflow,
        logger: logger,
      );
      when(mockXcdevice.isInstalled).thenReturn(true);

      int fetchDevicesCount = 0;
      when(mockXcdevice.getAvailableIOSDevices())
        .thenAnswer((Invocation invocation) {
          if (fetchDevicesCount == 0) {
            // Initial time, no devices.
            fetchDevicesCount++;
            return Future<List<IOSDevice>>.value(<IOSDevice>[]);
          } else if (fetchDevicesCount == 1) {
            // Simulate 2 devices added later.
            fetchDevicesCount++;
            return Future<List<IOSDevice>>.value(<IOSDevice>[device1, device2]);
          }
          fail('Too many calls to getAvailableTetheredIOSDevices');
      });

      int addedCount = 0;
      final Completer<void> added = Completer<void>();
      iosDevices.onAdded.listen((Device device) {
        addedCount++;
        // 2 devices will be added.
        // Will throw over-completion if called more than twice.
        if (addedCount >= 2) {
          added.complete();
        }
      });

      final Completer<void> removed = Completer<void>();
      iosDevices.onRemoved.listen((Device device) {
        // Will throw over-completion if called more than once.
        removed.complete();
      });

      final StreamController<Map<XCDeviceEvent, String>> eventStream = StreamController<Map<XCDeviceEvent, String>>();
      when(mockXcdevice.observedDeviceEvents()).thenAnswer((_) => eventStream.stream);

      await iosDevices.startPolling();
      verify(mockXcdevice.getAvailableIOSDevices()).called(1);

      expect(iosDevices.deviceNotifier.items, isEmpty);
      expect(eventStream.hasListener, isTrue);

      eventStream.add(<XCDeviceEvent, String>{
        XCDeviceEvent.attach: 'd83d5bc53967baa0ee18626ba87b6254b2ab5418'
      });
      await added.future;
      expect(iosDevices.deviceNotifier.items.length, 2);
      expect(iosDevices.deviceNotifier.items, contains(device1));
      expect(iosDevices.deviceNotifier.items, contains(device2));

      eventStream.add(<XCDeviceEvent, String>{
        XCDeviceEvent.detach: 'd83d5bc53967baa0ee18626ba87b6254b2ab5418'
      });
      await removed.future;
      expect(iosDevices.deviceNotifier.items, <Device>[device2]);

      // Remove stream will throw over-completion if called more than once
      // which proves this is ignored.
      eventStream.add(<XCDeviceEvent, String>{
        XCDeviceEvent.detach: 'bogus'
      });

      expect(addedCount, 2);

      await iosDevices.stopPolling();

      expect(eventStream.hasListener, isFalse);
    });

    testWithoutContext('polling can be restarted if stream is closed', () async {
      final IOSDevices iosDevices = IOSDevices(
        platform: macPlatform,
        xcdevice: mockXcdevice,
        iosWorkflow: mockIosWorkflow,
        logger: logger,
      );
      when(mockXcdevice.isInstalled).thenReturn(true);

      when(mockXcdevice.getAvailableIOSDevices())
        .thenAnswer((Invocation invocation) => Future<List<IOSDevice>>.value(<IOSDevice>[]));

      final StreamController<Map<XCDeviceEvent, String>> eventStream = StreamController<Map<XCDeviceEvent, String>>();
      final StreamController<Map<XCDeviceEvent, String>> rescheduledStream = StreamController<Map<XCDeviceEvent, String>>();

      bool reschedule = false;
      when(mockXcdevice.observedDeviceEvents()).thenAnswer((Invocation invocation) {
        if (!reschedule) {
          reschedule = true;
          return eventStream.stream;
        }
        return rescheduledStream.stream;
      });

      await iosDevices.startPolling();
      expect(eventStream.hasListener, isTrue);
      verify(mockXcdevice.getAvailableIOSDevices()).called(1);

      // Pretend xcdevice crashed.
      await eventStream.close();
      expect(logger.traceText, contains('xcdevice observe stopped'));

      // Confirm a restart still gets streamed events.
      await iosDevices.startPolling();

      expect(eventStream.hasListener, isFalse);
      expect(rescheduledStream.hasListener, isTrue);

      await iosDevices.stopPolling();
      expect(rescheduledStream.hasListener, isFalse);
    });

    testWithoutContext('dispose cancels polling subscription', () async {
      final IOSDevices iosDevices = IOSDevices(
        platform: macPlatform,
        xcdevice: mockXcdevice,
        iosWorkflow: mockIosWorkflow,
        logger: logger,
      );
      when(mockXcdevice.isInstalled).thenReturn(true);
      when(mockXcdevice.getAvailableIOSDevices())
          .thenAnswer((Invocation invocation) => Future<List<IOSDevice>>.value(<IOSDevice>[]));

      final StreamController<Map<XCDeviceEvent, String>> eventStream = StreamController<Map<XCDeviceEvent, String>>();
      when(mockXcdevice.observedDeviceEvents()).thenAnswer((_) => eventStream.stream);

      await iosDevices.startPolling();
      expect(iosDevices.deviceNotifier.items, isEmpty);
      expect(eventStream.hasListener, isTrue);

      await iosDevices.dispose();
      expect(eventStream.hasListener, isFalse);
    });

    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];
    for (final Platform unsupportedPlatform in unsupportedPlatforms) {
      testWithoutContext('pollingGetDevices throws Unsupported Operation exception on ${unsupportedPlatform.operatingSystem}', () async {
        final IOSDevices iosDevices = IOSDevices(
          platform: unsupportedPlatform,
          xcdevice: mockXcdevice,
          iosWorkflow: mockIosWorkflow,
          logger: logger,
        );
        when(mockXcdevice.isInstalled).thenReturn(false);
        expect(
            () async { await iosDevices.pollingGetDevices(); },
            throwsA(isA<UnsupportedError>()),
        );
      });
    }

    testWithoutContext('pollingGetDevices returns attached devices', () async {
      final IOSDevices iosDevices = IOSDevices(
        platform: macPlatform,
        xcdevice: mockXcdevice,
        iosWorkflow: mockIosWorkflow,
        logger: logger,
      );
      when(mockXcdevice.isInstalled).thenReturn(true);

      when(mockXcdevice.getAvailableIOSDevices())
          .thenAnswer((Invocation invocation) => Future<List<IOSDevice>>.value(<IOSDevice>[device1]));

      final List<Device> devices = await iosDevices.pollingGetDevices();
      expect(devices, hasLength(1));
      expect(identical(devices.first, device1), isTrue);
    });
  });

  group('getDiagnostics', () {
    MockXcdevice mockXcdevice;
    IOSWorkflow mockIosWorkflow;
    Logger logger;

    setUp(() {
      mockXcdevice = MockXcdevice();
      mockIosWorkflow = MockIOSWorkflow();
      logger = BufferLogger.test();
    });

    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];
    for (final Platform unsupportedPlatform in unsupportedPlatforms) {
      testWithoutContext('throws returns platform diagnostic exception on ${unsupportedPlatform.operatingSystem}', () async {
        final IOSDevices iosDevices = IOSDevices(
          platform: unsupportedPlatform,
          xcdevice: mockXcdevice,
          iosWorkflow: mockIosWorkflow,
          logger: logger,
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
        logger: logger,
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
class MockVmService extends Mock implements VmService {}
