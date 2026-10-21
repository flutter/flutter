// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/xcode_debug.dart';
import 'package:flutter_tools/src/macos/macos_ipad_device.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {
  group('MacOSDesignedForIPadDevices', () {
    testWithoutContext('does not support non-macOS platforms', () async {
      final discoverer = MacOSDesignedForIPadDevices(
        xcode: FakeXcode(),
        xcdevice: FakeXCDevice(),
        iosWorkflow: FakeIOSWorkflow(canListDevices: true),
        toolContext: FakeToolContext(
          fs: MemoryFileSystem.test(),
          logger: BufferLogger.test(),
          os: FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm64),
          platform: FakePlatform(operatingSystem: 'windows'),
          processManager: FakeProcessManager.any(),
        ),
      );

      expect(discoverer.supportsPlatform, isFalse);
    });

    testWithoutContext('discovery is enabled for ordinary commands', () async {
      final discoverer = MacOSDesignedForIPadDevices(
        xcode: FakeXcode(),
        xcdevice: FakeXCDevice(),
        iosWorkflow: FakeIOSWorkflow(canListDevices: true),
        toolContext: FakeToolContext(
          fs: MemoryFileSystem.test(),
          logger: BufferLogger.test(),
          os: FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm64),
          platform: FakePlatform(operatingSystem: 'macos'),
          processManager: FakeProcessManager.any(),
        ),
      );
      expect(discoverer.supportsPlatform, isTrue);

      final List<Device> devices = await discoverer.devices();
      expect(devices.single.id, 'mac-designed-for-ipad');
    });

    testWithoutContext('no device on x86', () async {
      final discoverer = MacOSDesignedForIPadDevices(
        xcode: FakeXcode(),
        xcdevice: FakeXCDevice(),
        iosWorkflow: FakeIOSWorkflow(canListDevices: true),
        toolContext: FakeToolContext(
          fs: MemoryFileSystem.test(),
          logger: BufferLogger.test(),
          os: FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_x64),
          platform: FakePlatform(operatingSystem: 'macos'),
          processManager: FakeProcessManager.any(),
        ),
      );
      expect(discoverer.supportsPlatform, isTrue);

      final List<Device> devices = await discoverer.devices();
      expect(devices, isEmpty);
    });

    testWithoutContext('no device on when iOS development off', () async {
      final discoverer = MacOSDesignedForIPadDevices(
        xcode: FakeXcode(),
        xcdevice: FakeXCDevice(),
        iosWorkflow: FakeIOSWorkflow(canListDevices: false),
        toolContext: FakeToolContext(
          fs: MemoryFileSystem.test(),
          logger: BufferLogger.test(),
          os: FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm64),
          platform: FakePlatform(operatingSystem: 'macos'),
          processManager: FakeProcessManager.any(),
        ),
      );
      expect(discoverer.supportsPlatform, isTrue);

      final List<Device> devices = await discoverer.devices();
      expect(devices, isEmpty);
    });

    testWithoutContext('reuses the device across polls and refreshes', () async {
      final discoverer = MacOSDesignedForIPadDevices(
        xcode: FakeXcode(),
        xcdevice: FakeXCDevice(),
        iosWorkflow: FakeIOSWorkflow(canListDevices: true),
        toolContext: FakeToolContext(
          fs: MemoryFileSystem.test(),
          logger: BufferLogger.test(),
          os: FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm64),
          platform: FakePlatform(operatingSystem: 'macos'),
          processManager: FakeProcessManager.any(),
        ),
      );
      expect(discoverer.supportsPlatform, isTrue);

      List<Device> devices = await discoverer.devices();
      expect(devices, hasLength(1));

      final Device device = devices.single;
      final DeviceLogReader logReader = await device.getLogReader();
      expect(device, isA<MacOSDesignedForIPadDevice>());
      expect(device.id, 'mac-designed-for-ipad');

      // Timeout ignored.
      devices = await discoverer.discoverDevices(timeout: const Duration(seconds: 10));
      expect(devices, hasLength(1));
      expect(devices.single, same(device));
      expect(await devices.single.getLogReader(), same(logReader));

      final List<Device> polledDevices = await discoverer.pollingGetDevices();
      expect(polledDevices.single, same(device));
    });
  });

  group('launching a prebuilt iOS app', () {
    late MemoryFileSystem fs;
    late FakeXcodeDebug debug;
    late FakeMacXCDevice xcdevice;
    late FakeMacMDns discovery;
    late MacOSDesignedForIPadDevice device;
    late List<Set<(int, String)>> ignoredServices;
    late List<FakeMacVmService> connections;
    late List<FakeMacVmService> connectedServices;

    setUp(() {
      fs = MemoryFileSystem.test();
      fs.directory('/build/Runner.app').createSync(recursive: true);
      debug = FakeXcodeDebug(fs);
      xcdevice = FakeMacXCDevice();
      discovery = FakeMacMDns();
      ignoredServices = <Set<(int, String)>>[];
      connections = <FakeMacVmService>[];
      connectedServices = <FakeMacVmService>[];
      device = MacOSDesignedForIPadDevice(
        xcode: FakeXcode(),
        xcdevice: xcdevice,
        xcodeDebug: debug,
        vmServiceDiscoveryFactory: (Set<(int, String)> ignored) {
          ignoredServices.add(Set<(int, String)>.of(ignored));
          return discovery;
        },
        vmServiceConnector: (_) async {
          final FakeMacVmService service = connections.isEmpty
              ? FakeMacVmService()
              : connections.removeAt(0);
          connectedServices.add(service);
          return service;
        },
        toolContext: FakeToolContext(
          fs: fs,
          platform: FakePlatform(operatingSystem: 'macos', localHostname: 'My-Mac.local'),
          projectFactory: FakeMacProjectFactory(fs),
        ),
      );
    });

    for (final mode in <BuildMode>[BuildMode.debug, BuildMode.profile, BuildMode.release]) {
      testUsingContext('launches ${mode.name} as a local iOS app', () async {
        final info = BuildInfo(
          mode,
          null,
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        );
        final options = mode == BuildMode.release
            ? DebuggingOptions.disabled(info)
            : DebuggingOptions.enabled(info, hostVmServicePort: 12345, deviceVmServicePort: 54321);
        final LaunchResult result = await device.startApp(
          FakeMacIOSApp(),
          prebuiltApplication: true,
          debuggingOptions: options,
        );
        expect(result.started, isTrue);
        expect(debug.mode, mode);
        expect(debug.copyApplicationBundle, isTrue);
        expect(debug.debuggerEnabled, mode == BuildMode.debug);
        expect(debug.deviceId, 'host-mac-id');
        expect(debug.devicePlatform, 'iphoneos');
        expect(debug.deviceArchitecture, 'arm64');
        expect(debug.lldbInitFile, '/ios/Flutter/ephemeral/flutter_lldbinit');
        expect(debug.arguments, isNot(contains('--enable-checked-mode')));
        if (mode != BuildMode.release) {
          expect(result.vmServiceUri, Uri.parse('http://127.0.0.1:12345/auth/'));
          expect(debug.arguments, contains('--vm-service-port=12345'));
          expect(debug.arguments, isNot(contains('--vm-service-port=54321')));
          expect(discovery.deviceName, 'My-Mac.local');
          expect(discovery.port, 12345);
        } else {
          expect(discovery.calls, 0);
        }
        expect(await device.stopApp(FakeMacIOSApp()), isTrue);
        expect(debug.exitCalls, 1);
      }, overrides: <Type, Generator>{MDnsVmServiceDiscovery: () => discovery});
    }

    testUsingContext('profile can explicitly attach the native debugger', () async {
      final LaunchResult result = await device.startApp(
        FakeMacIOSApp(),
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile, iosProfileDebugger: true),
      );
      expect(result.started, isTrue);
      expect(debug.mode, BuildMode.profile);
      expect(debug.debuggerEnabled, isTrue);
    }, overrides: <Type, Generator>{MDnsVmServiceDiscovery: () => discovery});

    testUsingContext('an ephemeral VM port is discovered by the local host name', () async {
      final LaunchResult result = await device.startApp(
        FakeMacIOSApp(),
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, hostVmServicePort: 0),
      );
      expect(result.started, isTrue);
      expect(debug.arguments, contains('--vm-service-port=0'));
      expect(discovery.port, isNull);
      expect(discovery.deviceName, 'My-Mac.local');
    }, overrides: <Type, Generator>{MDnsVmServiceDiscovery: () => discovery});

    testUsingContext(
      'a VM discovery exception stops the app and removes the temporary project',
      () async {
        discovery.failure = StateError('Discovery failed');
        await expectLater(
          () => device.startApp(
            FakeMacIOSApp(),
            prebuiltApplication: true,
            debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          ),
          throwsStateError,
        );
        expect(debug.exitCalls, 1);
        expect(fs.directory('/temporary').existsSync(), isFalse);
      },
      overrides: <Type, Generator>{MDnsVmServiceDiscovery: () => discovery},
    );

    testUsingContext('relaunch ignores a VM service belonging to the previous process', () async {
      connections.add(FakeMacVmService(startTime: 0));
      discovery.uris.addAll(<Uri>[
        Uri.parse('http://127.0.0.1:1111/old/'),
        Uri.parse('http://127.0.0.1:2222/new/'),
      ]);
      final LaunchResult result = await device.startApp(
        FakeMacIOSApp(),
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      );
      expect(result.vmServiceUri, Uri.parse('http://127.0.0.1:2222/new/'));
      expect(ignoredServices, <Set<(int, String)>>[
        <(int, String)>{},
        <(int, String)>{(1111, 'old/')},
      ]);
      expect(connectedServices, hasLength(2));
      expect(connectedServices.every((FakeMacVmService service) => service.disposed), isTrue);
    });

    testUsingContext('failed launch cleans up its temporary project', () async {
      debug.launchSucceeds = false;
      final LaunchResult result = await device.startApp(
        FakeMacIOSApp(),
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      );
      expect(result.started, isFalse);
      expect(debug.exitCalls, 1);
      expect(fs.directory('/temporary').existsSync(), isFalse);
    });

    testUsingContext('missing Xcode host does not create or launch a project', () async {
      xcdevice.identifier = null;
      await expectLater(
        () => device.startApp(
          FakeMacIOSApp(),
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        ),
        throwsToolExit(message: 'Unable to find this Mac in Xcode'),
      );
      expect(debug.deviceId, isNull);
      expect(fs.directory('/temporary').existsSync(), isFalse);
    });

    testUsingContext('missing VM service stops the launched app', () async {
      discovery.uri = null;
      final LaunchResult result = await device.startApp(
        FakeMacIOSApp(),
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      );
      expect(result.started, isFalse);
      expect(debug.exitCalls, 1);
      expect(fs.directory('/temporary').existsSync(), isFalse);
    }, overrides: <Type, Generator>{MDnsVmServiceDiscovery: () => discovery});

    testWithoutContext('disabled publication fails before launching', () async {
      await expectLater(
        () => device.startApp(
          FakeMacIOSApp(),
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, disablePortPublication: true),
        ),
        throwsToolExit(message: 'Disabling VM service publication is not supported'),
      );
      expect(debug.deviceId, isNull);
    });
  });

  testWithoutContext('MacOSDesignedForIPadDevice properties', () async {
    final device = MacOSDesignedForIPadDevice(
      xcode: FakeXcode(),
      xcdevice: FakeXCDevice(),
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm64),
        processManager: FakeProcessManager.any(),
      ),
    );
    expect(device.id, 'mac-designed-for-ipad');
    expect(await device.isLocalEmulator, isFalse);
    expect(device.name, 'Mac Designed for iPad');
    expect(device.portForwarder, isNot(isNull));
    expect(await device.targetPlatform, TargetPlatform.ios);
    expect(device.platformType, PlatformType.ios);
    expect(await device.cpuArch, CpuArch.arm64);

    await expectLater(
      () => device.installApp(FakeApplicationPackage()),
      throwsToolExit(message: 'Standalone installation is not supported'),
    );
    expect(await device.isAppInstalled(FakeApplicationPackage()), isTrue);
    expect(await device.isLatestBuildInstalled(FakeApplicationPackage()), isTrue);
    await expectLater(
      () => device.uninstallApp(FakeApplicationPackage()),
      throwsToolExit(message: 'Uninstalling applications is not supported'),
    );

    expect(await device.isSupported(), isTrue);
    expect(device.getLogReader(), isA<DeviceLogReader>());
    expect(await device.stopApp(FakeIOSApp()), isTrue);
    await expectLater(
      () => device.startApp(
        FakeApplicationPackage(),
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      ),
      throwsToolExit(message: 'An iOS application is required'),
    );
    expect(device.executablePathForDevice(FakeIOSApp(), BuildInfo.debug), null);
  });
}

class FakeIOSWorkflow extends Fake implements IOSWorkflow {
  FakeIOSWorkflow({required this.canListDevices});

  @override
  final bool canListDevices;
}

class FakeApplicationPackage extends Fake implements ApplicationPackage {}

class FakeIOSApp extends Fake implements IOSApp {}

class FakeXcode extends Fake implements Xcode {}

class FakeXCDevice extends Fake implements XCDevice {}

class FakeMacXCDevice extends Fake implements XCDevice {
  String? identifier = 'host-mac-id';
  @override
  Future<String?> getMacOSDeviceIdentifier() async => identifier;
}

class FakeMacIOSApp extends Fake implements IOSApp {
  @override
  String get id => 'com.example.ipadonmac';
  @override
  String get deviceBundlePath => '/build/Runner.app';
}

class FakeMacProjectFactory extends Fake implements FlutterProjectFactory {
  FakeMacProjectFactory(this.fs);
  final FileSystem fs;
  @override
  FlutterProject fromDirectory(Directory directory) => FakeMacProject(fs);
}

class FakeMacProject extends Fake implements FlutterProject {
  FakeMacProject(this.fs);
  final FileSystem fs;
  @override
  IosProject get ios => FakeMacIOSProject(fs);
}

class FakeMacIOSProject extends Fake implements IosProject {
  FakeMacIOSProject(this.fs);
  final FileSystem fs;
  @override
  Future<void> ensureReadyForPlatformSpecificTooling() async {}
  @override
  File get lldbInitFile => fs.file('/ios/Flutter/ephemeral/flutter_lldbinit');
}

class FakeXcodeDebug extends Fake implements XcodeDebug {
  FakeXcodeDebug(this.fs);
  final FileSystem fs;
  BuildMode? mode;
  bool? copyApplicationBundle;
  bool? debuggerEnabled;
  String? lldbInitFile;
  String? deviceId;
  String? devicePlatform;
  String? deviceArchitecture;
  List<String>? arguments;
  int exitCalls = 0;
  bool launchSucceeds = true;
  @override
  bool get debugStarted => deviceId != null;
  @override
  Future<XcodeDebugProject> createXcodeProjectWithCustomBundle(
    String deviceBundlePath, {
    required TemplateRenderer templateRenderer,
    Directory? projectDestination,
    bool verboseLogging = false,
    BuildMode buildMode = BuildMode.debug,
    bool copyApplicationBundle = false,
    bool debuggerEnabled = true,
    String? lldbInitFile,
  }) async {
    mode = buildMode;
    this.copyApplicationBundle = copyApplicationBundle;
    this.debuggerEnabled = debuggerEnabled;
    this.lldbInitFile = lldbInitFile;
    fs.directory('/temporary/Runner.xcodeproj').createSync(recursive: true);
    return XcodeDebugProject(
      scheme: 'Runner',
      hostAppProjectName: 'Runner',
      xcodeProject: fs.directory('/temporary/Runner.xcodeproj'),
      xcodeWorkspace: fs.directory('/temporary/Runner.xcworkspace'),
      isTemporaryProject: true,
    );
  }

  @override
  Future<bool> debugApp({
    required XcodeDebugProject project,
    required String deviceId,
    required List<String> launchArguments,
    String? devicePlatform,
    String? deviceArchitecture,
  }) async {
    this.deviceId = deviceId;
    this.devicePlatform = devicePlatform;
    this.deviceArchitecture = deviceArchitecture;
    arguments = launchArguments;
    return launchSucceeds;
  }

  @override
  Future<bool> exit({bool force = false, bool skipDelay = false}) async {
    exitCalls += 1;
    return true;
  }
}

class FakeMacMDns extends Fake implements MDnsVmServiceDiscovery {
  String? deviceName;
  int? port;
  int calls = 0;
  Uri? uri = Uri.parse('http://127.0.0.1:12345/auth/');
  StateError? failure;
  final uris = <Uri>[];
  @override
  Future<Uri?> getVMServiceUriForLaunch(
    String applicationId,
    Device device, {
    int? deviceVmservicePort,
    String? deviceName,
    int? hostVmservicePort,
    bool throwOnError = true,
    Duration timeout = const Duration(minutes: 10),
    bool useDeviceIPAsHost = false,
    bool usesIpv6 = false,
  }) async {
    calls += 1;
    if (failure != null) {
      throw failure!;
    }
    this.deviceName = deviceName;
    port = deviceVmservicePort;
    return uris.isEmpty ? uri : uris.removeAt(0);
  }
}

class FakeMacVmService extends Fake implements vm_service.VmService {
  FakeMacVmService({int? startTime})
    : startTime = startTime ?? DateTime.now().millisecondsSinceEpoch + 1000;
  final int startTime;
  bool disposed = false;
  @override
  Future<vm_service.VM> getVM() async => vm_service.VM(startTime: startTime);
  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
