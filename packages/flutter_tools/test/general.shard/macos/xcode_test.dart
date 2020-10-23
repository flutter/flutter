// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessException, ProcessResult;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
  });

  // Group exists to work around https://github.com/flutter/flutter/issues/56415.
  // Do not add more `MockProcessManager` tests.
  group('MockProcessManager', () {
    ProcessManager processManager;

    setUp(() {
      processManager = MockProcessManager();
    });

    group('Xcode', () {
      Xcode xcode;

      setUp(() {
        xcode = Xcode(
          logger: logger,
          platform: FakePlatform(operatingSystem: 'macos'),
          fileSystem: MemoryFileSystem.test(),
          processManager: processManager,
          xcodeProjectInterpreter: MockXcodeProjectInterpreter(),
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

      testWithoutContext('eulaSigned is false when clang is not installed', () {
        when(processManager.runSync(<String>['sysctl', 'hw.optional.arm64']))
            .thenReturn(ProcessResult(123, 1, '', ''));
        when(processManager.runSync(<String>['xcrun', 'clang']))
          .thenThrow(const ProcessException('xcrun', <String>['clang']));

        expect(xcode.eulaSigned, isFalse);
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
          platform: null,
          artifacts: MockArtifacts(),
          cache: MockCache(),
          iproxy: IProxy.test(logger: logger, processManager: processManager),
        );
        when(mockXcode.xcrunCommand()).thenReturn(<String>['xcrun']);
      });

      testWithoutContext('available devices xcdevice fails', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '2']))
          .thenThrow(const ProcessException('xcrun', <String>['xcdevice', 'list', '--timeout', '2']));

        expect(await xcdevice.getAvailableIOSDevices(), isEmpty);
      });

      testWithoutContext('diagnostics xcdevice fails', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

        when(processManager.run(<String>['xcrun', 'xcdevice', 'list', '--timeout', '2']))
          .thenThrow(const ProcessException('xcrun', <String>['xcdevice', 'list', '--timeout', '2']));

        expect(await xcdevice.getDiagnostics(), isEmpty);
      });
    });
  });

  group('FakeProcessManager', () {
    FakeProcessManager fakeProcessManager;

    setUp(() {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
    });

    group('Xcode', () {
      MockXcodeProjectInterpreter mockXcodeProjectInterpreter;

      setUp(() {
        mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
      });

      testWithoutContext('isInstalledAndMeetsVersionCheck is false when not macOS', () {
        final Xcode xcode = Xcode(
          logger: logger,
          platform: FakePlatform(operatingSystem: 'windows'),
          fileSystem: MemoryFileSystem.test(),
          processManager: fakeProcessManager,
          xcodeProjectInterpreter: mockXcodeProjectInterpreter,
        );

        expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
      });

      group('macOS', () {
        Xcode xcode;
        FakePlatform platform;

        setUp(() {
          mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
          platform = FakePlatform(operatingSystem: 'macos');
          xcode = Xcode(
            logger: logger,
            platform: platform,
            fileSystem: MemoryFileSystem.test(),
            processManager: fakeProcessManager,
            xcodeProjectInterpreter: mockXcodeProjectInterpreter,
          );
        });

        testWithoutContext('xcodeSelectPath returns path when xcode-select is installed', () {
          const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['/usr/bin/xcode-select', '--print-path'],
            stdout: xcodePath,
          ));

          expect(xcode.xcodeSelectPath, xcodePath);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testWithoutContext('xcodeVersionSatisfactory is false when version is less than minimum', () {
          when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
          when(mockXcodeProjectInterpreter.majorVersion).thenReturn(9);
          when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);
          when(mockXcodeProjectInterpreter.patchVersion).thenReturn(0);

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
          when(mockXcodeProjectInterpreter.patchVersion).thenReturn(0);

          expect(xcode.isVersionSatisfactory, isTrue);
        });

        testWithoutContext('xcodeVersionSatisfactory is true when major version exceeds minimum', () {
          when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
          when(mockXcodeProjectInterpreter.majorVersion).thenReturn(12);
          when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);
          when(mockXcodeProjectInterpreter.patchVersion).thenReturn(0);

          expect(xcode.isVersionSatisfactory, isTrue);
        });

        testWithoutContext('xcodeVersionSatisfactory is true when minor version exceeds minimum', () {
          when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
          when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
          when(mockXcodeProjectInterpreter.minorVersion).thenReturn(3);
          when(mockXcodeProjectInterpreter.patchVersion).thenReturn(0);

          expect(xcode.isVersionSatisfactory, isTrue);
        });

        testWithoutContext('xcodeVersionSatisfactory is true when patch version exceeds minimum', () {
          when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
          when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
          when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);
          when(mockXcodeProjectInterpreter.patchVersion).thenReturn(1);

          expect(xcode.isVersionSatisfactory, isTrue);
        });

        testWithoutContext('isInstalledAndMeetsVersionCheck is false when not installed', () {
          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['/usr/bin/xcode-select', '--print-path'],
            stdout: '/Applications/Xcode8.0.app/Contents/Developer',
          ));
          when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

          expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testWithoutContext('isInstalledAndMeetsVersionCheck is false when no xcode-select', () {
          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['/usr/bin/xcode-select', '--print-path'],
            exitCode: 127,
            stderr: 'ERROR',
          ));
          when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
          when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
          when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);
          when(mockXcodeProjectInterpreter.patchVersion).thenReturn(0);

          expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testWithoutContext('isInstalledAndMeetsVersionCheck is false when version not satisfied', () {
          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['/usr/bin/xcode-select', '--print-path'],
            stdout: '/Applications/Xcode8.0.app/Contents/Developer',
          ));
          when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
          when(mockXcodeProjectInterpreter.majorVersion).thenReturn(10);
          when(mockXcodeProjectInterpreter.minorVersion).thenReturn(2);
          when(mockXcodeProjectInterpreter.patchVersion).thenReturn(0);

          expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testWithoutContext('xcrun runs natively on arm64', () {
          fakeProcessManager.addCommands(const <FakeCommand>[
            FakeCommand(
              command: <String>[
                'sysctl',
                'hw.optional.arm64',
              ],
              stdout: 'hw.optional.arm64: 1',
            ),
          ]);

          expect(xcode.xcrunCommand(), <String>[
            '/usr/bin/arch',
            '-arm64e',
            'xcrun',
          ]);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testWithoutContext('isInstalledAndMeetsVersionCheck is true when macOS and installed and version is satisfied', () {
          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['/usr/bin/xcode-select', '--print-path'],
            stdout: '/Applications/Xcode8.0.app/Contents/Developer',
          ));
          when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
          when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
          when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);
          when(mockXcodeProjectInterpreter.patchVersion).thenReturn(0);

          expect(xcode.isInstalledAndMeetsVersionCheck, isTrue);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testWithoutContext('eulaSigned is false when clang output indicates EULA not yet accepted', () {
          fakeProcessManager.addCommands(const <FakeCommand>[
            FakeCommand(
              command: <String>[
                'sysctl',
                'hw.optional.arm64',
              ],
              exitCode: 1,
            ),
            FakeCommand(
              command: <String>['xcrun', 'clang'],
              exitCode: 1,
              stderr:
                  'Xcode EULA has not been accepted.\nLaunch Xcode and accept the license.',
            ),
          ]);

          expect(xcode.eulaSigned, isFalse);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testWithoutContext('eulaSigned is true when clang output indicates EULA has been accepted', () {
          fakeProcessManager.addCommands(
            const <FakeCommand>[
              FakeCommand(
                command: <String>[
                  'sysctl',
                  'hw.optional.arm64',
                ],
                exitCode: 1,
              ),
              FakeCommand(
                command: <String>['xcrun', 'clang'],
                exitCode: 1,
                stderr: 'clang: error: no input files',
              ),
            ],
          );
          expect(xcode.eulaSigned, isTrue);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testWithoutContext('SDK name', () {
          expect(getNameForSdk(SdkType.iPhone), 'iphoneos');
          expect(getNameForSdk(SdkType.iPhoneSimulator), 'iphonesimulator');
          expect(getNameForSdk(SdkType.macOS), 'macosx');
        });

        group('SDK location', () {
          setUp(() {
            fakeProcessManager.addCommand(
              const FakeCommand(
                command: <String>[
                  'sysctl',
                  'hw.optional.arm64',
                ],
                exitCode: 1,
              ),
            );
          });

          const String sdkroot = 'Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS13.2.sdk';

          testWithoutContext('--show-sdk-path iphoneos', () async {
            fakeProcessManager.addCommand(const FakeCommand(
              command: <String>['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'],
              stdout: sdkroot,
            ));

            expect(await xcode.sdkLocation(SdkType.iPhone), sdkroot);
            expect(fakeProcessManager.hasRemainingExpectations, isFalse);
          });

          testWithoutContext('--show-sdk-path macosx', () async {
            fakeProcessManager.addCommand(const FakeCommand(
              command: <String>['xcrun', '--sdk', 'macosx', '--show-sdk-path'],
              stdout: sdkroot,
            ));

            expect(await xcode.sdkLocation(SdkType.macOS), sdkroot);
            expect(fakeProcessManager.hasRemainingExpectations, isFalse);
          });

          testWithoutContext('--show-sdk-path fails', () async {
            fakeProcessManager.addCommand(const FakeCommand(
              command: <String>['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'],
              exitCode: 1,
              stderr: 'xcrun: error:',
            ));

            expect(() async => await xcode.sdkLocation(SdkType.iPhone),
              throwsToolExit(message: 'Could not find SDK location'));
            expect(fakeProcessManager.hasRemainingExpectations, isFalse);
          });
        });
      });
    });

    group('xcdevice', () {
      XCDevice xcdevice;
      MockXcode mockXcode;
      MockArtifacts mockArtifacts;
      MockCache mockCache;

      setUp(() {
        mockXcode = MockXcode();
        mockArtifacts = MockArtifacts();
        mockCache = MockCache();
        xcdevice = XCDevice(
          processManager: fakeProcessManager,
          logger: logger,
          xcode: mockXcode,
          platform: null,
          artifacts: mockArtifacts,
          cache: mockCache,
          iproxy: IProxy.test(logger: logger, processManager: fakeProcessManager),
        );
        when(mockXcode.xcrunCommand()).thenReturn(<String>['xcrun']);
      });

      group('installed', () {
        testWithoutContext('Xcode not installed', () {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);
          expect(xcdevice.isInstalled, false);
        });
      });

      group('observe device events', () {
        testWithoutContext('Xcode not installed', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);

          expect(xcdevice.observedDeviceEvents(), isNull);
          expect(logger.traceText, contains("Xcode not found. Run 'flutter doctor' for more information."));
        });

        testUsingContext('relays events', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>[
              'script',
              '-t',
              '0',
              '/dev/null',
              'xcrun',
              'xcdevice',
              'observe',
              '--both',
            ], stdout: 'Attach: d83d5bc53967baa0ee18626ba87b6254b2ab5418\n'
              'Attach: 00008027-00192736010F802E\n'
              'Detach: d83d5bc53967baa0ee18626ba87b6254b2ab5418',
            stderr: 'Some error',
          ));

          final Completer<void> attach1 = Completer<void>();
          final Completer<void> attach2 = Completer<void>();
          final Completer<void> detach1 = Completer<void>();

          // Attach: d83d5bc53967baa0ee18626ba87b6254b2ab5418
          // Attach: 00008027-00192736010F802E
          // Detach: d83d5bc53967baa0ee18626ba87b6254b2ab5418
          xcdevice.observedDeviceEvents().listen((Map<XCDeviceEvent, String> event) {
            expect(event.length, 1);
            if (event.containsKey(XCDeviceEvent.attach)) {
              if (event[XCDeviceEvent.attach] == 'd83d5bc53967baa0ee18626ba87b6254b2ab5418') {
                attach1.complete();
              } else
              if (event[XCDeviceEvent.attach] == '00008027-00192736010F802E') {
                attach2.complete();
              }
            } else if (event.containsKey(XCDeviceEvent.detach)) {
              expect(event[XCDeviceEvent.detach], 'd83d5bc53967baa0ee18626ba87b6254b2ab5418');
              detach1.complete();
            } else {
              fail('Unexpected event');
            }
          });
          await attach1.future;
          await attach2.future;
          await detach1.future;
          expect(logger.traceText, contains('xcdevice observe error: Some error'));
        });
      });

      group('available devices', () {
        final FakePlatform macPlatform = FakePlatform(operatingSystem: 'macos');

        testWithoutContext('Xcode not installed', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);

          expect(await xcdevice.getAvailableIOSDevices(), isEmpty);
        });

        testUsingContext('returns devices', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

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
    "identifier" : "00008027-00192736010F802E",
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

          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['xcrun', 'xcdevice', 'list', '--timeout', '2'],
            stdout: devicesOutput,
          ));
          final List<IOSDevice> devices = await xcdevice.getAvailableIOSDevices();
          expect(devices, hasLength(3));
          expect(devices[0].id, '00008027-00192736010F802E');
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
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        }, overrides: <Type, Generator>{
          Platform: () => macPlatform,
          Artifacts: () => Artifacts.test(),
        });

        testWithoutContext('uses timeout', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['xcrun', 'xcdevice', 'list', '--timeout', '20'],
            stdout: '[]',
          ));
          await xcdevice.getAvailableIOSDevices(timeout: const Duration(seconds: 20));
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        });

        testUsingContext('ignores "Preparing debugger support for iPhone" error', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

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

          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['xcrun', 'xcdevice', 'list', '--timeout', '2'],
            stdout: devicesOutput,
          ));
          final List<IOSDevice> devices = await xcdevice.getAvailableIOSDevices();
          expect(devices, hasLength(1));
          expect(devices[0].id, '43ad2fda7991b34fe1acbda82f9e2fd3d6ddc9f7');
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        }, overrides: <Type, Generator>{
          Platform: () => macPlatform,
          Artifacts: () => Artifacts.test(),
        });

        testUsingContext('handles unknown architectures', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

          const String devicesOutput = '''
[
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "usb",
    "available" : true,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "d83d5bc53967baa0ee18626ba87b6254b2ab5418",
    "architecture" : "armv7x",
    "modelName" : "iPad 3 BOGUS",
    "name" : "iPad"
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "13.3 (17C54)",
    "interface" : "usb",
    "available" : true,
    "platform" : "com.apple.platform.iphoneos",
    "modelCode" : "iPhone8,1",
    "identifier" : "d83d5bc53967baa0ee18626ba87b6254b2ab5418",
    "architecture" : "BOGUS",
    "modelName" : "Future iPad",
    "name" : "iPad"
  }
]
''';

          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['xcrun', 'xcdevice', 'list', '--timeout', '2'],
            stdout: devicesOutput,
          ));
          final List<IOSDevice> devices = await xcdevice.getAvailableIOSDevices();
          expect(devices[0].cpuArchitecture, DarwinArch.armv7);
          expect(devices[1].cpuArchitecture, DarwinArch.arm64);
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        }, overrides: <Type, Generator>{
          Platform: () => macPlatform,
          Artifacts: () => Artifacts.test(),
        });
      });

      group('diagnostics', () {
        final FakePlatform macPlatform = FakePlatform(operatingSystem: 'macos');

        testWithoutContext('Xcode not installed', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);

          expect(await xcdevice.getDiagnostics(), isEmpty);
        });

        testUsingContext('uses cache', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

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

          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['xcrun', 'xcdevice', 'list', '--timeout', '2'],
            stdout: devicesOutput,
          ));

          await xcdevice.getAvailableIOSDevices();
          final List<String> errors = await xcdevice.getDiagnostics();
          expect(errors, hasLength(1));
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        }, overrides: <Type, Generator>{
          Platform: () => macPlatform,
        });

        testUsingContext('returns error message', () async {
          when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);

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

          fakeProcessManager.addCommand(const FakeCommand(
            command: <String>['xcrun', 'xcdevice', 'list', '--timeout', '2'],
            stdout: devicesOutput,
          ));

          final List<String> errors = await xcdevice.getDiagnostics();
          expect(errors, hasLength(4));
          expect(errors[0], 'Error: iPhone is not paired with your computer. To use iPhone with Xcode, unlock it and choose to trust this computer when prompted. (code -9)');
          expect(errors[1], 'Error: iPhone is not paired with your computer.');
          expect(errors[2], 'Error: Xcode pairing error. (code -13)');
          expect(errors[3], 'Error: iPhone is busy: Preparing debugger support for iPhone. Xcode will continue when iPhone is finished. (code -10)');
          expect(fakeProcessManager.hasRemainingExpectations, isFalse);
        }, overrides: <Type, Generator>{
          Platform: () => macPlatform,
        });
      });
    });
  });
}

class MockXcode extends Mock implements Xcode {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
