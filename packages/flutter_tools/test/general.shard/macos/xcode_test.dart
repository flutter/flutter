// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessException, ProcessResult;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  ProcessManager processManager;
  Logger logger;

  setUp(() {
    logger = BufferLogger.test();
    processManager = MockProcessManager();
  });

  group('Xcode', () {
    Xcode xcode;
    MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
    MockPlatform platform;
    FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem();
      mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
      platform = MockPlatform();
      xcode = Xcode(
        logger: logger,
        platform: platform,
        fileSystem: fileSystem,
        processManager: processManager,
        xcodeProjectInterpreter: mockXcodeProjectInterpreter,
      );
    });

    testWithoutContext('xcodeSelectPath returns null when xcode-select is not installed', () {
      when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
          .thenThrow(const ProcessException('/usr/bin/xcode-select', <String>['--print-path']));
      expect(xcode.xcodeSelectPath, isNull);
      when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
          .thenThrow(ArgumentError('Invalid argument(s): Cannot find executable for /usr/bin/xcode-select'));

      expect(xcode.xcodeSelectPath, isNull);
    });

    testWithoutContext('xcodeSelectPath returns path when xcode-select is installed', () {
      const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
      when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
          .thenReturn(ProcessResult(1, 0, xcodePath, ''));

      expect(xcode.xcodeSelectPath, xcodePath);
    });

    testWithoutContext('xcodeVersionSatisfactory is false when version is less than minimum', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(9);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);

      expect(xcode.isVersionSatisfactory, isFalse);
    });

    testWithoutContext('xcodeVersionSatisfactory is false when xcodebuild tools are not installed', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

      expect(xcode.isVersionSatisfactory, isFalse);
    });

    testWithoutContext('xcodeVersionSatisfactory is true when version meets minimum', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);

      expect(xcode.isVersionSatisfactory, isTrue);
    });

    testWithoutContext('xcodeVersionSatisfactory is true when major version exceeds minimum', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(12);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);

      expect(xcode.isVersionSatisfactory, isTrue);
    });

    testWithoutContext('xcodeVersionSatisfactory is true when minor version exceeds minimum', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(3);

      expect(xcode.isVersionSatisfactory, isTrue);
    });

    testWithoutContext('isInstalledAndMeetsVersionCheck is false when not macOS', () {
      when(platform.isMacOS).thenReturn(false);

      expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
    });

    testWithoutContext('isInstalledAndMeetsVersionCheck is false when not installed', () {
      when(platform.isMacOS).thenReturn(true);
      const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
      when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 0, xcodePath, ''));
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

      expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
    });

    testWithoutContext('isInstalledAndMeetsVersionCheck is false when no xcode-select', () {
      when(platform.isMacOS).thenReturn(true);
      when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 127, '', 'ERROR'));
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);

      expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
    });

    testWithoutContext('isInstalledAndMeetsVersionCheck is false when version not satisfied', () {
      when(platform.isMacOS).thenReturn(true);
      const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
      when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 0, xcodePath, ''));
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(10);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(2);

      expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
    });

    testWithoutContext('isInstalledAndMeetsVersionCheck is true when macOS and installed and version is satisfied', () {
      when(platform.isMacOS).thenReturn(true);
      const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
      when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 0, xcodePath, ''));
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);

      expect(xcode.isInstalledAndMeetsVersionCheck, isTrue);
    });

    testWithoutContext('eulaSigned is false when clang is not installed', () {
      when(processManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
          .thenThrow(const ProcessException('/usr/bin/xcrun', <String>['clang']));

      expect(xcode.eulaSigned, isFalse);
    });

    testWithoutContext('eulaSigned is false when clang output indicates EULA not yet accepted', () {
      when(processManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
          .thenReturn(ProcessResult(1, 1, '', 'Xcode EULA has not been accepted.\nLaunch Xcode and accept the license.'));

      expect(xcode.eulaSigned, isFalse);
    });

    testWithoutContext('eulaSigned is true when clang output indicates EULA has been accepted', () {
      when(processManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
          .thenReturn(ProcessResult(1, 1, '', 'clang: error: no input files'));

      expect(xcode.eulaSigned, isTrue);
    });

    testWithoutContext('SDK name', () {
      expect(getNameForSdk(SdkType.iPhone), 'iphoneos');
      expect(getNameForSdk(SdkType.iPhoneSimulator), 'iphonesimulator');
      expect(getNameForSdk(SdkType.macOS), 'macosx');
    });

    group('SDK location', () {
      const String sdkroot = 'Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS13.2.sdk';

      testWithoutContext('--show-sdk-path iphoneos', () async {
        when(processManager.run(<String>['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'])).thenAnswer((_) =>
        Future<ProcessResult>.value(ProcessResult(1, 0, sdkroot, '')));

        expect(await xcode.sdkLocation(SdkType.iPhone), sdkroot);
      });

      testWithoutContext('--show-sdk-path macosx', () async {
        when(processManager.run(<String>['xcrun', '--sdk', 'macosx', '--show-sdk-path'])).thenAnswer((_) =>
        Future<ProcessResult>.value(ProcessResult(1, 0, sdkroot, '')));

        expect(await xcode.sdkLocation(SdkType.macOS), sdkroot);
      });

      testWithoutContext('--show-sdk-path fails', () async {
        when(processManager.run(<String>['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'])).thenAnswer((_) =>
        Future<ProcessResult>.value(ProcessResult(1, 1, '', 'xcrun: error:')));

        expect(() async => await xcode.sdkLocation(SdkType.iPhone),
          throwsToolExit(message: 'Could not find SDK location'));
      });
    });
  });

  group('xcdevice', () {
    XCDevice xcdevice;
    MockXcode mockXcode;

    setUp(() {
      mockXcode = MockXcode();
      xcdevice = XCDevice(
        processManager: processManager,
        logger: logger,
        xcode: mockXcode,
        iMobileDevice: null,
        iosDeploy: null,
      );
    });

    group('installed', () {
      testWithoutContext('Xcode not installed', () {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);
        expect(xcdevice.isInstalled, false);
      });

      testWithoutContext("xcrun can't find xcdevice", () {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
            .thenThrow(const ProcessException('xcrun', <String>['--find', 'xcdevice']));
        expect(xcdevice.isInstalled, false);
        verify(processManager.runSync(any)).called(1);
      });

      testWithoutContext('is installed', () {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
            .thenReturn(ProcessResult(1, 0, '/path/to/xcdevice', ''));
        expect(xcdevice.isInstalled, true);
      });
    });

    group('available devices', () {
      final FakePlatform macPlatform = FakePlatform.fromPlatform(const LocalPlatform());
      macPlatform.operatingSystem = 'macos';

      testWithoutContext('Xcode not installed', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);

        expect(await xcdevice.getAvailableTetheredIOSDevices(), isEmpty);
        verifyNever(processManager.run(any));
      });

      testWithoutContext('xcdevice fails', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
            .thenReturn(ProcessResult(1, 0, '/path/to/xcdevice', ''));

        when(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '1']))
            .thenThrow(const ProcessException('xcrun', <String>['xcdevice', 'list', '--timeout', '1']));

        expect(await xcdevice.getAvailableTetheredIOSDevices(), isEmpty);
      });

      testUsingContext('returns devices', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
            .thenReturn(ProcessResult(1, 0, '/path/to/xcdevice', ''));

        const String devicesOutput = '''
[
  {
    "simulator" : true,
    "operatingSystemVersion" : "13.3 (17K446)",
    "available" : true,
    "platform" : "com.apple.platform.appletvsimulator",
    "modelCode" : "AppleTV5,3",
    "identifier" : "CBB5E1ED-2172-446E-B4E7-F2B5823DBBA6",
    "architecture" : "x86_64",
    "modelName" : "Apple TV",
    "name" : "Apple TV"
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "usb",
    "available" : true,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "d83d5bc53967baa0ee18626ba87b6254b2ab5418",
    "architecture" : "arm64",
    "modelName" : "iPhone 6s",
    "name" : "An iPhone (Space Gray)"
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "10.1 (14C54)",
    "interface" : "usb",
    "available" : true,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPad11,4",
    "identifier" : "98206e7a4afd4aedaff06e687594e089dede3c44",
    "architecture" : "armv7",
    "modelName" : "iPad Air 3rd Gen",
    "name" : "iPad 1"
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "10.1 (14C54)",
    "interface" : "network",
    "available" : true,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPad11,4",
    "identifier" : "234234234234234234345445687594e089dede3c44",
    "architecture" : "arm64",
    "modelName" : "iPad Air 3rd Gen",
    "name" : "A networked iPad"
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "10.1 (14C54)",
    "interface" : "usb",
    "available" : true,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPad11,4",
    "identifier" : "f577a7903cc54959be2e34bc4f7f80b7009efcf4",
    "architecture" : "BOGUS",
    "modelName" : "iPad Air 3rd Gen",
    "name" : "iPad 2"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "6.1.1 (17S445)",
    "available" : true,
    "platform" : "com.apple.platform.watchsimulator",
    "modelCode" : "Watch5,4",
    "identifier" : "2D74FB11-88A0-44D0-B81E-C0C142B1C94A",
    "architecture" : "i386",
    "modelName" : "Apple Watch Series 5 - 44mm",
    "name" : "Apple Watch Series 5 - 44mm"
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "usb",
    "available" : false,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "c4ca6f7a53027d1b7e4972e28478e7a28e2faee2",
    "architecture" : "arm64",
    "modelName" : "iPhone 6s",
    "name" : "iPhone",
    "error" : {
      "code" : -9,
      "failureReason" : "",
      "description" : "iPhone is not paired with your computer.",
      "domain" : "com.apple.platform.iphoneos"
    }
  }
]
''';

        when(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '1']))
            .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 0, devicesOutput, '')));
        final List<IOSDevice> devices = await xcdevice.getAvailableTetheredIOSDevices();
        expect(devices, hasLength(3));
        expect(devices[0].id, 'd83d5bc53967baa0ee18626ba87b6254b2ab5418');
        expect(devices[0].name, 'An iPhone (Space Gray)');
        expect(await devices[0].sdkNameAndVersion, 'iOS 13.3');
        expect(devices[0].cpuArchitecture, DarwinArch.arm64);
        expect(devices[1].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
        expect(devices[1].name, 'iPad 1');
        expect(await devices[1].sdkNameAndVersion, 'iOS 10.1');
        expect(devices[1].cpuArchitecture, DarwinArch.armv7);
        expect(devices[2].id, 'f577a7903cc54959be2e34bc4f7f80b7009efcf4');
        expect(devices[2].name, 'iPad 2');
        expect(await devices[2].sdkNameAndVersion, 'iOS 10.1');
        expect(devices[2].cpuArchitecture, DarwinArch.arm64); // Defaults to arm64 for unknown architecture.
      }, overrides: <Type, Generator>{
        Platform: () => macPlatform,
      });

      testWithoutContext('uses timeout', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
          .thenReturn(ProcessResult(1, 0, '/path/to/xcdevice', ''));

        when(processManager.run(any))
          .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 0, '[]', '')));
        await xcdevice.getAvailableTetheredIOSDevices(timeout: const Duration(seconds: 20));
        verify(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '20'])).called(1);
      });

      testUsingContext('ignores "Preparing debugger support for iPhone" error', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
            .thenReturn(ProcessResult(1, 0, '/path/to/xcdevice', ''));

        const String devicesOutput = '''
[
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "usb",
    "available" : false,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "43ad2fda7991b34fe1acbda82f9e2fd3d6ddc9f7",
    "architecture" : "arm64",
    "modelName" : "iPhone 6s",
    "name" : "iPhone",
    "error" : {
      "code" : -10,
      "failureReason" : "",
      "description" : "iPhone is busy: Preparing debugger support for iPhone",
      "recoverySuggestion" : "Xcode will continue when iPhone is finished.",
      "domain" : "com.apple.platform.iphoneos"
    }
  }
]
''';

        when(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '1']))
            .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 0, devicesOutput, '')));
        final List<IOSDevice> devices = await xcdevice.getAvailableTetheredIOSDevices();
        expect(devices, hasLength(1));
        expect(devices[0].id, '43ad2fda7991b34fe1acbda82f9e2fd3d6ddc9f7');
      }, overrides: <Type, Generator>{
        Platform: () => macPlatform,
      });
    });

    group('diagnostics', () {
      final FakePlatform macPlatform = FakePlatform.fromPlatform(const LocalPlatform());
      macPlatform.operatingSystem = 'macos';

      testWithoutContext('Xcode not installed', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);

        expect(await xcdevice.getDiagnostics(), isEmpty);
        verifyNever(processManager.run(any));
      });

      testWithoutContext('xcdevice fails', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
            .thenReturn(ProcessResult(1, 0, '/path/to/xcdevice', ''));

        when(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '1']))
            .thenThrow(const ProcessException('xcrun', <String>['xcdevice', 'list', '--timeout', '1']));

        expect(await xcdevice.getDiagnostics(), isEmpty);
      });

      testUsingContext('uses cache', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
            .thenReturn(ProcessResult(1, 0, '/path/to/xcdevice', ''));

        const String devicesOutput = '''
[
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "network",
    "available" : false,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "d83d5bc53967baa0ee18626ba87b6254b2ab5418",
    "architecture" : "arm64",
    "modelName" : "iPhone 6s",
    "error" : {
      "code" : -13,
      "failureReason" : "",
      "domain" : "com.apple.platform.iphoneos"
    }
  }
]
''';

        when(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '1']))
            .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 0, devicesOutput, '')));
        await xcdevice.getAvailableTetheredIOSDevices();
        final List<String> errors = await xcdevice.getDiagnostics();
        expect(errors, hasLength(1));

        verify(processManager.run(any)).called(1);
      }, overrides: <Type, Generator>{
        Platform: () => macPlatform,
      });

      testUsingContext('returns error message', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.runSync(<String>['xcrun', '--find', 'xcdevice']))
            .thenReturn(ProcessResult(1, 0, '/path/to/xcdevice', ''));

        const String devicesOutput = '''
[
   {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "usb",
    "available" : false,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "98206e7a4afd4aedaff06e687594e089dede3c44",
    "architecture" : "arm64",
    "modelName" : "iPhone 6s",
    "name" : "An iPhone (Space Gray)",
    "error" : {
      "code" : -9,
      "failureReason" : "",
      "underlyingErrors" : [
        {
          "code" : 5,
          "failureReason" : "allowsSecureServices: 1. isConnected: 0. Platform: <DVTPlatform:0x7f804ce32880:'com.apple.platform.iphoneos':<DVTFilePath:0x7f804ce32800:'\/Users\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform'>>. DTDKDeviceIdentifierIsIDID: 0",
          "description" : "📱<DVTiOSDevice (0x7f801f190450), iPhone, iPhone, 13.3 (17C54), d83d5bc53967baa0ee18626ba87b6254b2ab5418> -- Failed _shouldMakeReadyForDevelopment check even though device is not locked by passcode.",
          "recoverySuggestion" : "",
          "domain" : "com.apple.platform.iphoneos"
        }
      ],
      "description" : "iPhone is not paired with your computer.",
      "recoverySuggestion" : "To use iPhone with Xcode, unlock it and choose to trust this computer when prompted.",
      "domain" : "com.apple.platform.iphoneos"
    }
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "usb",
    "available" : false,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "d83d5bc53967baa0ee18626ba87b6254b2ab5418",
    "architecture" : "arm64",
    "modelName" : "iPhone 6s",
    "name" : "iPhone",
    "error" : {
      "failureReason" : "",
      "description" : "iPhone is not paired with your computer",
      "domain" : "com.apple.platform.iphoneos"
    }
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "network",
    "available" : false,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "d83d5bc53967baa0ee18626ba87b6254b2ab5418",
    "architecture" : "arm64",
    "modelName" : "iPhone 6s",
    "error" : {
      "code" : -13,
      "failureReason" : "",
      "domain" : "com.apple.platform.iphoneos"
    }
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "usb",
    "available" : false,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "43ad2fda7991b34fe1acbda82f9e2fd3d6ddc9f7",
    "architecture" : "arm64",
    "modelName" : "iPhone 6s",
    "name" : "iPhone",
    "error" : {
      "code" : -10,
      "failureReason" : "",
      "description" : "iPhone is busy: Preparing debugger support for iPhone",
      "recoverySuggestion" : "Xcode will continue when iPhone is finished.",
      "domain" : "com.apple.platform.iphoneos"
    }
  }
]
''';

        when(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '1']))
            .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 0, devicesOutput, '')));
        final List<String> errors = await xcdevice.getDiagnostics();
        expect(errors, hasLength(4));
        expect(errors[0], 'Error: iPhone is not paired with your computer. To use iPhone with Xcode, unlock it and choose to trust this computer when prompted. (code -9)');
        expect(errors[1], 'Error: iPhone is not paired with your computer.');
        expect(errors[2], 'Error: Xcode pairing error. (code -13)');
        expect(errors[3], 'Error: iPhone is busy: Preparing debugger support for iPhone. Xcode will continue when iPhone is finished. (code -10)');
      }, overrides: <Type, Generator>{
        Platform: () => macPlatform,
      });
    });
  });
}

class MockXcode extends Mock implements Xcode {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockPlatform extends Mock implements Platform {}
