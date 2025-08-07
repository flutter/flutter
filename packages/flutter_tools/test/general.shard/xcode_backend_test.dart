// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../../bin/xcode_backend.dart';
import '../src/common.dart' hide Context;
import '../src/fake_process_manager.dart';

void main() {
  late MemoryFileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem();
  });

  test('prints warning and defaults to iOS if unknown platform', () {
    final Directory buildDir = fileSystem.directory('/path/to/builds')..createSync(recursive: true);
    final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
      ..createSync(recursive: true);
    const buildMode = 'Debug';
    final context = TestContext(
      <String>['build'],
      <String, String>{
        'BUILT_PRODUCTS_DIR': buildDir.path,
        'CONFIGURATION': buildMode,
        'FLUTTER_ROOT': flutterRoot.path,
        'INFOPLIST_PATH': 'Info.plist',
      },
      commands: <FakeCommand>[
        FakeCommand(
          command: <String>[
            '${flutterRoot.path}/bin/flutter',
            'assemble',
            '--no-version-check',
            '--output=${buildDir.path}/',
            '-dTargetPlatform=ios',
            '-dTargetFile=lib/main.dart',
            '-dBuildMode=${buildMode.toLowerCase()}',
            '-dConfiguration=$buildMode',
            '-dIosArchs=',
            '-dSdkRoot=',
            '-dSplitDebugInfo=',
            '-dTreeShakeIcons=',
            '-dTrackWidgetCreation=',
            '-dDartObfuscation=',
            '-dAction=',
            '-dFrontendServerStarterPath=',
            '--ExtraGenSnapshotOptions=',
            '--DartDefines=',
            '--ExtraFrontEndOptions=',
            '-dSrcRoot=',
            '-dTargetDeviceOSVersion=',
            'debug_ios_bundle_flutter_assets',
          ],
        ),
      ],
      fileSystem: fileSystem,
    )..run();
    expect(context.stderr, contains('warning: Unrecognized platform: null. Defaulting to iOS.\n'));
  });

  const List<TargetPlatform> platforms = TargetPlatform.values;
  for (final platform in platforms) {
    final String platformName = platform.name;
    group('build for $platformName', () {
      test('exits with useful error message when build mode not set', () {
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        final context = TestContext(
          <String>['build', platformName],
          <String, String>{
            'ACTION': 'build',
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
          },
          commands: <FakeCommand>[],
          fileSystem: fileSystem,
        );
        expect(() => context.run(), throwsException);
        expect(context.stderr, contains('ERROR: Unknown FLUTTER_BUILD_MODE: null.\n'));
      });

      test('calls flutter assemble', () {
        final targetPlatform = platform == TargetPlatform.ios ? 'Ios' : 'Darwin';
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        final File pipe = fileSystem.file('/tmp/pipe')..createSync(recursive: true);
        const buildMode = 'Debug';

        final context = TestContext(
          <String>['build', platformName],
          <String, String>{
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'CONFIGURATION': buildMode,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
            'FLUTTER_CLI_BUILD_MODE': buildMode.toLowerCase(),
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                '${flutterRoot.path}/bin/flutter',
                'assemble',
                '--no-version-check',
                '--output=${buildDir.path}/',
                '-dTargetPlatform=${targetPlatform.toLowerCase()}',
                '-dTargetFile=lib/main.dart',
                '-dBuildMode=${buildMode.toLowerCase()}',
                '-dConfiguration=$buildMode',
                '-d${targetPlatform}Archs=',
                '-dSdkRoot=',
                '-dSplitDebugInfo=',
                '-dTreeShakeIcons=',
                '-dTrackWidgetCreation=',
                '-dDartObfuscation=',
                '-dAction=',
                '-dFrontendServerStarterPath=',
                '--ExtraGenSnapshotOptions=',
                '--DartDefines=',
                '--ExtraFrontEndOptions=',
                '-dSrcRoot=',
                if (platform == TargetPlatform.ios) ...<String>['-dTargetDeviceOSVersion='],
                if (platform == TargetPlatform.macos) ...<String>[
                  '--build-inputs=/Flutter/ephemeral/FlutterInputs.xcfilelist',
                  '--build-outputs=/Flutter/ephemeral/FlutterOutputs.xcfilelist',
                ],
                'debug_${platformName}_bundle_flutter_assets',
              ],
            ),
          ],
          fileSystem: fileSystem,
          scriptOutputStreamFile: pipe,
        )..run();
        final List<String> streamedLines = pipe.readAsLinesSync();
        // Ensure after line splitting, the exact string 'done' appears
        expect(streamedLines, contains('done'));
        expect(streamedLines, contains(' └─Compiling, linking and signing...'));
        expect(context.stdout, contains('built and packaged successfully.'));
        expect(context.stderr, isEmpty);
      });

      test('forwards all env variables to flutter assemble', () {
        final targetPlatform = platform == TargetPlatform.ios ? 'Ios' : 'Darwin';
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        const archs = 'arm64';
        const buildMode = 'Release';
        const dartObfuscation = 'false';
        const dartDefines = 'flutter.inspector.structuredErrors%3Dtrue';
        const expandedCodeSignIdentity = 'F1326572E0B71C3C8442805230CB4B33B708A2E2';
        const extraFrontEndOptions = '--some-option';
        const extraGenSnapshotOptions = '--obfuscate';
        const frontendServerStarterPath = '/path/to/frontend_server_starter.dart';
        const sdkRoot = '/path/to/sdk';
        const splitDebugInfo = '/path/to/split/debug/info';
        const trackWidgetCreation = 'true';
        const treeShake = 'true';
        const srcRoot = '/path/to/project';
        const iOSVersion = '18.3.1';
        final context = TestContext(
          <String>['build', platformName],
          <String, String>{
            'ACTION': 'install',
            'ARCHS': archs,
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'CODE_SIGNING_REQUIRED': 'YES',
            'CONFIGURATION': '$buildMode-strawberry',
            'DART_DEFINES': dartDefines,
            'DART_OBFUSCATION': dartObfuscation,
            'EXPANDED_CODE_SIGN_IDENTITY': expandedCodeSignIdentity,
            'EXTRA_FRONT_END_OPTIONS': extraFrontEndOptions,
            'EXTRA_GEN_SNAPSHOT_OPTIONS': extraGenSnapshotOptions,
            'FLUTTER_ROOT': flutterRoot.path,
            'FRONTEND_SERVER_STARTER_PATH': frontendServerStarterPath,
            'INFOPLIST_PATH': 'Info.plist',
            'SDKROOT': sdkRoot,
            'FLAVOR': 'strawberry',
            'SPLIT_DEBUG_INFO': splitDebugInfo,
            'TRACK_WIDGET_CREATION': trackWidgetCreation,
            'TREE_SHAKE_ICONS': treeShake,
            'SRCROOT': srcRoot,
            'TARGET_DEVICE_OS_VERSION': iOSVersion,
            'FLUTTER_CLI_BUILD_MODE': buildMode.toLowerCase(),
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                '${flutterRoot.path}/bin/flutter',
                'assemble',
                '--no-version-check',
                '--output=${buildDir.path}/',
                '-dTargetPlatform=${targetPlatform.toLowerCase()}',
                '-dTargetFile=lib/main.dart',
                '-dBuildMode=${buildMode.toLowerCase()}',
                '-dFlavor=strawberry',
                '-dConfiguration=$buildMode-strawberry',
                '-d${targetPlatform}Archs=$archs',
                '-dSdkRoot=$sdkRoot',
                '-dSplitDebugInfo=$splitDebugInfo',
                '-dTreeShakeIcons=$treeShake',
                '-dTrackWidgetCreation=$trackWidgetCreation',
                '-dDartObfuscation=$dartObfuscation',
                '-dAction=install',
                '-dFrontendServerStarterPath=$frontendServerStarterPath',
                '--ExtraGenSnapshotOptions=$extraGenSnapshotOptions',
                '--DartDefines=$dartDefines',
                '--ExtraFrontEndOptions=$extraFrontEndOptions',
                '-dSrcRoot=$srcRoot',
                if (platform == TargetPlatform.ios) ...<String>[
                  '-dTargetDeviceOSVersion=$iOSVersion',
                  '-dCodesignIdentity=$expandedCodeSignIdentity',
                ],
                if (platform == TargetPlatform.macos) ...<String>[
                  '--build-inputs=/Flutter/ephemeral/FlutterInputs.xcfilelist',
                  '--build-outputs=/Flutter/ephemeral/FlutterOutputs.xcfilelist',
                ],
                'release_${platformName}_bundle_flutter_assets',
              ],
            ),
          ],
          fileSystem: fileSystem,
        )..run();
        expect(context.stdout, contains('built and packaged successfully.'));
        expect(context.stderr, isEmpty);
      });

      test(
        'exits with useful error message when missing FLUTTER_CLI_BUILD_MODE during archive',
        () {
          final Directory buildDir = fileSystem.directory('/path/to/builds')
            ..createSync(recursive: true);
          final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
            ..createSync(recursive: true);

          const buildMode = 'Release';

          final context = TestContext(
            <String>['build', platformName],
            <String, String>{
              'ACTION': 'install',
              'CONFIGURATION': buildMode,
              'BUILT_PRODUCTS_DIR': buildDir.path,
              'FLUTTER_ROOT': flutterRoot.path,
              'INFOPLIST_PATH': 'Info.plist',
            },
            commands: <FakeCommand>[],
            fileSystem: fileSystem,
          );
          expect(() => context.run(), throwsException);
          expect(
            context.stderr,
            contains(
              'error: Your Flutter build settings are outdated. '
              'Please run "flutter build ${platform.name} --config-only --release" '
              'in your Flutter project and try again.',
            ),
          );
        },
      );

      test('exits with useful error message when build mode mismatches during archive', () {
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);

        const buildMode = 'Release';

        final context = TestContext(
          <String>['build', platformName],
          <String, String>{
            'ACTION': 'install',
            'CONFIGURATION': buildMode,
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
            'FLUTTER_CLI_BUILD_MODE': 'debug',
          },
          commands: <FakeCommand>[],
          fileSystem: fileSystem,
        );
        expect(() => context.run(), throwsException);
        expect(
          context.stderr,
          contains(
            'error: Your Flutter project is currently configured for debug mode. '
            'Please run `flutter build ${platform.name} --config-only --release` '
            'in your Flutter project to update your settings.',
          ),
        );
      });

      test('prints useful warning message when missing FLUTTER_CLI_BUILD_MODE', () {
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);

        const buildMode = 'Release';

        final context = TestContext(
          <String>['build', platformName],
          <String, String>{
            'ACTION': 'build',
            'CONFIGURATION': buildMode,
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
          },
          commands: <FakeCommand>[],
          fileSystem: fileSystem,
          fakeProcessManager: FakeProcessManager.any(),
        );
        context.run();
        expect(
          context.stderr,
          contains(
            'warning: Your Flutter build settings are outdated. '
            'Please run "flutter build ${platform.name} --config-only --release" '
            'in your Flutter project and try again.',
          ),
        );
      });

      test('prints useful warning message when build mode mismatches', () {
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);

        const buildMode = 'Release';

        final context = TestContext(
          <String>['build', platformName],
          <String, String>{
            'ACTION': 'debug',
            'CONFIGURATION': buildMode,
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
            'FLUTTER_CLI_BUILD_MODE': 'debug',
          },
          commands: <FakeCommand>[],
          fileSystem: fileSystem,
          fakeProcessManager: FakeProcessManager.any(),
        );
        context.run();
        expect(
          context.stderr,
          contains(
            'warning: Your Flutter project is currently configured for debug mode. '
            'Please run `flutter build ${platform.name} --config-only --release` '
            'in your Flutter project to update your settings.',
          ),
        );
      });
    });
  }

  group('test_vm_service_bonjour_service', () {
    test('handles when the Info.plist is missing', () {
      final Directory buildDir = fileSystem.directory('/path/to/builds')
        ..createSync(recursive: true);
      final context = TestContext(
        <String>['test_vm_service_bonjour_service'],
        <String, String>{
          'CONFIGURATION': 'Debug',
          'BUILT_PRODUCTS_DIR': buildDir.path,
          'INFOPLIST_PATH': 'Info.plist',
        },
        commands: <FakeCommand>[],
        fileSystem: fileSystem,
      )..run();
      expect(
        context.stdout,
        contains(
          'Info.plist does not exist. Skipping _dartVmService._tcp NSBonjourServices insertion.',
        ),
      );
    });

    test('Missing NSBonjourServices key in Info.plist should not fail Xcode compilation', () {
      final Directory buildDir = fileSystem.directory('/path/to/builds')
        ..createSync(recursive: true);
      final File infoPlist = buildDir.childFile('Info.plist')..createSync();
      final context = TestContext(
        <String>['test_vm_service_bonjour_service'],
        <String, String>{
          'CONFIGURATION': 'Debug',
          'BUILT_PRODUCTS_DIR': buildDir.path,
          'INFOPLIST_PATH': 'Info.plist',
        },
        commands: <FakeCommand>[
          FakeCommand(
            command: <String>[
              'plutil',
              '-extract',
              'NSBonjourServices',
              'xml1',
              '-o',
              '-',
              infoPlist.path,
            ],
            exitCode: 1,
            stderr: 'No value at that key path or invalid key path: NSBonjourServices',
          ),
          FakeCommand(
            command: <String>[
              'plutil',
              '-insert',
              'NSBonjourServices',
              '-json',
              '["_dartVmService._tcp"]',
              infoPlist.path,
            ],
          ),
          FakeCommand(
            command: <String>[
              'plutil',
              '-extract',
              'NSLocalNetworkUsageDescription',
              'xml1',
              '-o',
              '-',
              infoPlist.path,
            ],
          ),
        ],
        fileSystem: fileSystem,
      )..run();
      expect(context.stderr, isNot(contains('error: ')));
    });

    test(
      'Missing NSLocalNetworkUsageDescription in Info.plist should not fail Xcode compilation',
      () {
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final File infoPlist = buildDir.childFile('Info.plist')..createSync();
        final context = TestContext(
          <String>['test_vm_service_bonjour_service'],
          <String, String>{
            'CONFIGURATION': 'Debug',
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'INFOPLIST_PATH': 'Info.plist',
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                'plutil',
                '-extract',
                'NSBonjourServices',
                'xml1',
                '-o',
                '-',
                infoPlist.path,
              ],
            ),
            FakeCommand(
              command: <String>[
                'plutil',
                '-insert',
                'NSBonjourServices.0',
                '-string',
                '_dartVmService._tcp',
                infoPlist.path,
              ],
            ),
            FakeCommand(
              command: <String>[
                'plutil',
                '-extract',
                'NSLocalNetworkUsageDescription',
                'xml1',
                '-o',
                '-',
                infoPlist.path,
              ],
              exitCode: 1,
              stderr:
                  'No value at that key path or invalid key path: NSLocalNetworkUsageDescription',
            ),
            FakeCommand(
              command: <String>[
                'plutil',
                '-insert',
                'NSLocalNetworkUsageDescription',
                '-string',
                'Allow Flutter tools on your computer to connect and debug your application. This prompt will not appear on release builds.',
                infoPlist.path,
              ],
            ),
          ],
          fileSystem: fileSystem,
        )..run();
        expect(context.stderr, isNot(contains('error: ')));
      },
    );
  });

  for (final platform in platforms) {
    final String platformName = platform.name;
    group('prepare for $platformName', () {
      test('exits with useful error message when build mode not set', () {
        final targetPlatform = platform == TargetPlatform.ios ? 'Ios' : 'Darwin';
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        final File pipe = fileSystem.file('/tmp/pipe')..createSync(recursive: true);
        const buildMode = 'Debug';
        final context = TestContext(
          <String>['prepare', platformName],
          <String, String>{
            'ACTION': 'build',
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
            'FLUTTER_CLI_BUILD_MODE': buildMode.toLowerCase(),
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                '${flutterRoot.path}/bin/flutter',
                'assemble',
                '--no-version-check',
                '--output=${buildDir.path}/',
                '-dTargetPlatform=${targetPlatform.toLowerCase()}',
                '-dTargetFile=lib/main.dart',
                '-dBuildMode=${buildMode.toLowerCase()}',
                '-d${targetPlatform}Archs=',
                '-dSdkRoot=',
                '-dSplitDebugInfo=',
                '-dTreeShakeIcons=',
                '-dTrackWidgetCreation=',
                '-dDartObfuscation=',
                '-dAction=build',
                '-dFrontendServerStarterPath=',
                '--ExtraGenSnapshotOptions=',
                '--DartDefines=',
                '--ExtraFrontEndOptions=',
                '-dPreBuildAction=PrepareFramework',
                '-dSrcRoot=',
                if (platform == TargetPlatform.ios) ...<String>['-dTargetDeviceOSVersion='],
                'debug_unpack_$platformName',
              ],
            ),
          ],
          fileSystem: fileSystem,
          scriptOutputStreamFile: pipe,
        );
        expect(() => context.run(), throwsException);
        expect(context.stderr, contains('ERROR: Unknown FLUTTER_BUILD_MODE: null.\n'));
      });

      test('calls flutter assemble', () {
        final targetPlatform = platform == TargetPlatform.ios ? 'Ios' : 'Darwin';
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        final File pipe = fileSystem.file('/tmp/pipe')..createSync(recursive: true);
        const buildMode = 'Debug';
        final context = TestContext(
          <String>['prepare', platformName],
          <String, String>{
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'CONFIGURATION': buildMode,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
            'FLUTTER_CLI_BUILD_MODE': buildMode.toLowerCase(),
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                '${flutterRoot.path}/bin/flutter',
                'assemble',
                '--no-version-check',
                '--output=${buildDir.path}/',
                '-dTargetPlatform=${targetPlatform.toLowerCase()}',
                '-dTargetFile=lib/main.dart',
                '-dBuildMode=${buildMode.toLowerCase()}',
                '-dConfiguration=$buildMode',
                '-d${targetPlatform}Archs=',
                '-dSdkRoot=',
                '-dSplitDebugInfo=',
                '-dTreeShakeIcons=',
                '-dTrackWidgetCreation=',
                '-dDartObfuscation=',
                '-dAction=',
                '-dFrontendServerStarterPath=',
                '--ExtraGenSnapshotOptions=',
                '--DartDefines=',
                '--ExtraFrontEndOptions=',
                '-dSrcRoot=',
                if (platform == TargetPlatform.ios) ...<String>['-dTargetDeviceOSVersion='],
                '-dPreBuildAction=PrepareFramework',
                'debug_unpack_$platformName',
              ],
            ),
          ],
          fileSystem: fileSystem,
          scriptOutputStreamFile: pipe,
        )..run();
        expect(context.stderr, isEmpty);
      });

      test('forwards all env variables to flutter assemble', () {
        final targetPlatform = platform == TargetPlatform.ios ? 'Ios' : 'Darwin';
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        const archs = 'arm64';
        const buildMode = 'Release';
        const dartObfuscation = 'false';
        const dartDefines = 'flutter.inspector.structuredErrors%3Dtrue';
        const expandedCodeSignIdentity = 'F1326572E0B71C3C8442805230CB4B33B708A2E2';
        const extraFrontEndOptions = '--some-option';
        const extraGenSnapshotOptions = '--obfuscate';
        const frontendServerStarterPath = '/path/to/frontend_server_starter.dart';
        const sdkRoot = '/path/to/sdk';
        const splitDebugInfo = '/path/to/split/debug/info';
        const trackWidgetCreation = 'true';
        const treeShake = 'true';
        const srcRoot = '/path/to/project';
        const iOSVersion = '18.3.1';
        final context = TestContext(
          <String>['prepare', platformName],
          <String, String>{
            'ACTION': 'install',
            'ARCHS': archs,
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'CODE_SIGNING_REQUIRED': 'YES',
            'DART_DEFINES': dartDefines,
            'DART_OBFUSCATION': dartObfuscation,
            'EXPANDED_CODE_SIGN_IDENTITY': expandedCodeSignIdentity,
            'EXTRA_FRONT_END_OPTIONS': extraFrontEndOptions,
            'EXTRA_GEN_SNAPSHOT_OPTIONS': extraGenSnapshotOptions,
            'FLUTTER_ROOT': flutterRoot.path,
            'FRONTEND_SERVER_STARTER_PATH': frontendServerStarterPath,
            'INFOPLIST_PATH': 'Info.plist',
            'SDKROOT': sdkRoot,
            'CONFIGURATION': '$buildMode-strawberry',
            'FLAVOR': 'strawberry',
            'SPLIT_DEBUG_INFO': splitDebugInfo,
            'TRACK_WIDGET_CREATION': trackWidgetCreation,
            'TREE_SHAKE_ICONS': treeShake,
            'SRCROOT': srcRoot,
            'TARGET_DEVICE_OS_VERSION': iOSVersion,
            'FLUTTER_CLI_BUILD_MODE': buildMode.toLowerCase(),
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                '${flutterRoot.path}/bin/flutter',
                'assemble',
                '--no-version-check',
                '--output=${buildDir.path}/',
                '-dTargetPlatform=${targetPlatform.toLowerCase()}',
                '-dTargetFile=lib/main.dart',
                '-dBuildMode=${buildMode.toLowerCase()}',
                '-dFlavor=strawberry',
                '-dConfiguration=$buildMode-strawberry',
                '-d${targetPlatform}Archs=$archs',
                '-dSdkRoot=$sdkRoot',
                '-dSplitDebugInfo=$splitDebugInfo',
                '-dTreeShakeIcons=$treeShake',
                '-dTrackWidgetCreation=$trackWidgetCreation',
                '-dDartObfuscation=$dartObfuscation',
                '-dAction=install',
                '-dFrontendServerStarterPath=$frontendServerStarterPath',
                '--ExtraGenSnapshotOptions=$extraGenSnapshotOptions',
                '--DartDefines=$dartDefines',
                '--ExtraFrontEndOptions=$extraFrontEndOptions',
                '-dSrcRoot=$srcRoot',
                if (platform == TargetPlatform.ios) ...<String>[
                  '-dTargetDeviceOSVersion=$iOSVersion',
                  '-dCodesignIdentity=$expandedCodeSignIdentity',
                ],
                '-dPreBuildAction=PrepareFramework',
                'release_unpack_$platformName',
              ],
            ),
          ],
          fileSystem: fileSystem,
        )..run();
        expect(context.stderr, isEmpty);
      });

      test('assumes ARCHS based on NATIVE_ARCH if ONLY_ACTIVE_ARCH is YES', () {
        final targetPlatform = platform == TargetPlatform.ios ? 'Ios' : 'Darwin';
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        final File pipe = fileSystem.file('/tmp/pipe')..createSync(recursive: true);
        const buildMode = 'Debug';
        final context = TestContext(
          <String>['prepare', platformName],
          <String, String>{
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'CONFIGURATION': buildMode,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
            'ARCHS': 'arm64 x86_64',
            'ONLY_ACTIVE_ARCH': 'YES',
            'NATIVE_ARCH': 'arm64e',
            'FLUTTER_CLI_BUILD_MODE': buildMode.toLowerCase(),
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                '${flutterRoot.path}/bin/flutter',
                'assemble',
                '--no-version-check',
                '--output=${buildDir.path}/',
                '-dTargetPlatform=${targetPlatform.toLowerCase()}',
                '-dTargetFile=lib/main.dart',
                '-dBuildMode=${buildMode.toLowerCase()}',
                '-dConfiguration=$buildMode',
                '-d${targetPlatform}Archs=arm64',
                '-dSdkRoot=',
                '-dSplitDebugInfo=',
                '-dTreeShakeIcons=',
                '-dTrackWidgetCreation=',
                '-dDartObfuscation=',
                '-dAction=',
                '-dFrontendServerStarterPath=',
                '--ExtraGenSnapshotOptions=',
                '--DartDefines=',
                '--ExtraFrontEndOptions=',
                '-dSrcRoot=',
                if (platform == TargetPlatform.ios) ...<String>['-dTargetDeviceOSVersion='],
                '-dPreBuildAction=PrepareFramework',
                'debug_unpack_$platformName',
              ],
            ),
          ],
          fileSystem: fileSystem,
          scriptOutputStreamFile: pipe,
        )..run();
        expect(context.stderr, isEmpty);
      });

      test('does not assumes ARCHS if ARCHS and NATIVE_ARCH are different', () {
        final targetPlatform = platform == TargetPlatform.ios ? 'Ios' : 'Darwin';
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        final File pipe = fileSystem.file('/tmp/pipe')..createSync(recursive: true);
        const buildMode = 'Debug';
        final context = TestContext(
          <String>['prepare', platformName],
          <String, String>{
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'CONFIGURATION': buildMode,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
            'ARCHS': 'arm64',
            'ONLY_ACTIVE_ARCH': 'YES',
            'NATIVE_ARCH': 'x86_64',
            'FLUTTER_CLI_BUILD_MODE': buildMode.toLowerCase(),
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                '${flutterRoot.path}/bin/flutter',
                'assemble',
                '--no-version-check',
                '--output=${buildDir.path}/',
                '-dTargetPlatform=${targetPlatform.toLowerCase()}',
                '-dTargetFile=lib/main.dart',
                '-dBuildMode=${buildMode.toLowerCase()}',
                '-dConfiguration=$buildMode',
                '-d${targetPlatform}Archs=arm64',
                '-dSdkRoot=',
                '-dSplitDebugInfo=',
                '-dTreeShakeIcons=',
                '-dTrackWidgetCreation=',
                '-dDartObfuscation=',
                '-dAction=',
                '-dFrontendServerStarterPath=',
                '--ExtraGenSnapshotOptions=',
                '--DartDefines=',
                '--ExtraFrontEndOptions=',
                '-dSrcRoot=',
                if (platform == TargetPlatform.ios) ...<String>['-dTargetDeviceOSVersion='],
                '-dPreBuildAction=PrepareFramework',
                'debug_unpack_$platformName',
              ],
            ),
          ],
          fileSystem: fileSystem,
          scriptOutputStreamFile: pipe,
        )..run();
        expect(context.stderr, isEmpty);
      });

      test('does not assumes ARCHS if ONLY_ACTIVE_ARCH is not YES', () {
        final targetPlatform = platform == TargetPlatform.ios ? 'Ios' : 'Darwin';
        final Directory buildDir = fileSystem.directory('/path/to/builds')
          ..createSync(recursive: true);
        final Directory flutterRoot = fileSystem.directory('/path/to/flutter')
          ..createSync(recursive: true);
        final File pipe = fileSystem.file('/tmp/pipe')..createSync(recursive: true);
        const buildMode = 'Debug';
        final context = TestContext(
          <String>['prepare', platformName],
          <String, String>{
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'CONFIGURATION': buildMode,
            'FLUTTER_ROOT': flutterRoot.path,
            'INFOPLIST_PATH': 'Info.plist',
            'ARCHS': 'arm64 x86_64',
            'NATIVE_ARCH': 'arm64e',
            'FLUTTER_CLI_BUILD_MODE': buildMode.toLowerCase(),
          },
          commands: <FakeCommand>[
            FakeCommand(
              command: <String>[
                '${flutterRoot.path}/bin/flutter',
                'assemble',
                '--no-version-check',
                '--output=${buildDir.path}/',
                '-dTargetPlatform=${targetPlatform.toLowerCase()}',
                '-dTargetFile=lib/main.dart',
                '-dBuildMode=${buildMode.toLowerCase()}',
                '-dConfiguration=$buildMode',
                '-d${targetPlatform}Archs=arm64 x86_64',
                '-dSdkRoot=',
                '-dSplitDebugInfo=',
                '-dTreeShakeIcons=',
                '-dTrackWidgetCreation=',
                '-dDartObfuscation=',
                '-dAction=',
                '-dFrontendServerStarterPath=',
                '--ExtraGenSnapshotOptions=',
                '--DartDefines=',
                '--ExtraFrontEndOptions=',
                '-dSrcRoot=',
                if (platform == TargetPlatform.ios) ...<String>['-dTargetDeviceOSVersion='],
                '-dPreBuildAction=PrepareFramework',
                'debug_unpack_$platformName',
              ],
            ),
          ],
          fileSystem: fileSystem,
          scriptOutputStreamFile: pipe,
        )..run();
        expect(context.stderr, isEmpty);
      });
    });
  }

  test('embed for iOS copies frameworks', () {
    final Directory buildDir = fileSystem.directory('/path/to/Build/Products/Debug-iphoneos')
      ..createSync(recursive: true);
    final Directory targetBuildDir = fileSystem.directory('/path/to/Build/Products/Debug-iphoneos')
      ..createSync(recursive: true);
    const appPath = '/path/to/my_flutter_app';
    const platformDirPath = '$appPath/ios';
    const frameworksFolderPath = 'Runner.app/Frameworks';
    const flutterBuildDir = 'build';
    final Directory nativeAssetsDir = fileSystem.directory(
      '/path/to/my_flutter_app/$flutterBuildDir/native_assets/ios/',
    );
    nativeAssetsDir.createSync(recursive: true);
    const ffiPackageName = 'package_a';
    final Directory ffiPackageDir = nativeAssetsDir.childDirectory('$ffiPackageName.framework')
      ..createSync();
    nativeAssetsDir.childFile('random.txt').createSync();
    const infoPlistPath = 'Runner.app/Info.plist';
    final File infoPlist = fileSystem.file('${buildDir.path}/$infoPlistPath');
    infoPlist.createSync(recursive: true);
    const buildMode = 'Debug';
    final testContext = TestContext(
      <String>['embed_and_thin', 'ios'],
      <String, String>{
        'BUILT_PRODUCTS_DIR': buildDir.path,
        'CONFIGURATION': buildMode,
        'INFOPLIST_PATH': infoPlistPath,
        'SOURCE_ROOT': platformDirPath,
        'FLUTTER_APPLICATION_PATH': appPath,
        'FLUTTER_BUILD_DIR': flutterBuildDir,
        'TARGET_BUILD_DIR': targetBuildDir.path,
        'FRAMEWORKS_FOLDER_PATH': frameworksFolderPath,
        'EXPANDED_CODE_SIGN_IDENTITY': '12312313',
      },
      commands: <FakeCommand>[
        FakeCommand(
          command: <String>[
            'mkdir',
            '-p',
            '--',
            targetBuildDir.childDirectory(frameworksFolderPath).path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'rsync',
            '-8',
            '-av',
            '--delete',
            '--filter',
            '- .DS_Store',
            buildDir.childDirectory('App.framework').path,
            targetBuildDir.childDirectory(frameworksFolderPath).path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'rsync',
            '-8',
            '-av',
            '--delete',
            '--filter',
            '- .DS_Store',
            buildDir.childDirectory('Flutter.framework').path,
            '${targetBuildDir.childDirectory(frameworksFolderPath).path}/',
          ],
        ),
        FakeCommand(
          command: <String>[
            'rsync',
            '-8',
            '-av',
            '--delete',
            '--filter',
            '- .DS_Store',
            '--filter',
            '- native_assets.yaml',
            '--filter',
            '- native_assets.json',
            ffiPackageDir.path,
            targetBuildDir.childDirectory(frameworksFolderPath).path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'plutil',
            '-extract',
            'NSBonjourServices',
            'xml1',
            '-o',
            '-',
            infoPlist.path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'plutil',
            '-insert',
            'NSBonjourServices.0',
            '-string',
            '_dartVmService._tcp',
            infoPlist.path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'plutil',
            '-extract',
            'NSLocalNetworkUsageDescription',
            'xml1',
            '-o',
            '-',
            infoPlist.path,
          ],
        ),
      ],
      fileSystem: fileSystem,
    )..run();

    expect(testContext.processManager.hasRemainingExpectations, isFalse);
  });

  test('embed for macos copies and codesigns frameworks', () {
    final Directory buildDir = fileSystem.directory('/path/to/Build/Products/Debug')
      ..createSync(recursive: true);
    final Directory targetBuildDir = fileSystem.directory('/path/to/Build/Products/Debug')
      ..createSync(recursive: true);
    const appPath = '/path/to/my_flutter_app';
    const platformDirPath = '$appPath/macos';
    const frameworksFolderPath = 'Runner.app/Frameworks';
    const flutterBuildDir = 'build';
    final Directory nativeAssetsDir = fileSystem.directory(
      '/path/to/my_flutter_app/$flutterBuildDir/native_assets/macos/',
    );
    nativeAssetsDir.createSync(recursive: true);
    const ffiPackageName = 'package_a';
    final Directory ffiPackageDir = nativeAssetsDir.childDirectory('$ffiPackageName.framework')
      ..createSync();
    nativeAssetsDir.childFile('random.txt').createSync();
    const infoPlistPath = 'Runner.app/Info.plist';
    final File infoPlist = fileSystem.file('${buildDir.path}/$infoPlistPath');
    infoPlist.createSync(recursive: true);
    const buildMode = 'Debug';
    const codesignIdentity = '12312313';
    final testContext = TestContext(
      <String>['embed_and_thin', 'macos'],
      <String, String>{
        'BUILT_PRODUCTS_DIR': buildDir.path,
        'CONFIGURATION': buildMode,
        'INFOPLIST_PATH': infoPlistPath,
        'SOURCE_ROOT': platformDirPath,
        'FLUTTER_APPLICATION_PATH': appPath,
        'FLUTTER_BUILD_DIR': flutterBuildDir,
        'TARGET_BUILD_DIR': targetBuildDir.path,
        'FRAMEWORKS_FOLDER_PATH': frameworksFolderPath,
        'EXPANDED_CODE_SIGN_IDENTITY': codesignIdentity,
      },
      commands: <FakeCommand>[
        FakeCommand(
          command: <String>[
            'mkdir',
            '-p',
            '--',
            targetBuildDir.childDirectory(frameworksFolderPath).path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'rsync',
            '-8',
            '-av',
            '--delete',
            '--filter',
            '- .DS_Store',
            buildDir.childDirectory('App.framework').path,
            targetBuildDir.childDirectory(frameworksFolderPath).path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'rsync',
            '-8',
            '-av',
            '--delete',
            '--filter',
            '- .DS_Store',
            '--filter',
            '- Headers',
            '--filter',
            '- Modules',
            buildDir.childDirectory('FlutterMacOS.framework').path,
            '${targetBuildDir.childDirectory(frameworksFolderPath).path}/',
          ],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--verbose',
            '--sign',
            codesignIdentity,
            '--',
            targetBuildDir.childDirectory(frameworksFolderPath).childFile('App.framework/App').path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--verbose',
            '--sign',
            codesignIdentity,
            '--',
            targetBuildDir
                .childDirectory(frameworksFolderPath)
                .childFile('FlutterMacOS.framework/FlutterMacOS')
                .path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'rsync',
            '-8',
            '-av',
            '--delete',
            '--filter',
            '- .DS_Store',
            '--filter',
            '- native_assets.yaml',
            '--filter',
            '- native_assets.json',
            ffiPackageDir.path,
            targetBuildDir.childDirectory(frameworksFolderPath).path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--verbose',
            '--sign',
            codesignIdentity,
            '--',
            targetBuildDir
                .childDirectory(frameworksFolderPath)
                .childFile('$ffiPackageName.framework/$ffiPackageName')
                .path,
          ],
        ),
      ],
      fileSystem: fileSystem,
    )..run();

    expect(testContext.processManager.hasRemainingExpectations, isFalse);
  });

  group('parseFrameworkNameFromDirectory', () {
    test('Non-framework directory', () {
      expect(
        Context.parseFrameworkNameFromDirectory(fileSystem.directory('path/to/directory')),
        isNull,
      );
    });

    test('Framework directory', () {
      expect(
        Context.parseFrameworkNameFromDirectory(
          fileSystem.directory('path/to/directory.framework'),
        ),
        'directory',
      );
    });
  });
}

class TestContext extends Context {
  TestContext(
    List<String> arguments,
    Map<String, String> environment, {
    required this.fileSystem,
    required List<FakeCommand> commands,
    File? scriptOutputStreamFile,
    FakeProcessManager? fakeProcessManager,
  }) : processManager = fakeProcessManager ?? FakeProcessManager.list(commands),
       super(
         arguments: arguments,
         environment: environment,
         scriptOutputStreamFile: scriptOutputStreamFile,
       );

  final FileSystem fileSystem;
  final FakeProcessManager processManager;

  var stdout = '';
  var stderr = '';

  @override
  bool existsFile(String path) {
    return fileSystem.file(path).existsSync();
  }

  @override
  Directory directoryFromPath(String path) {
    return fileSystem.directory(path);
  }

  @override
  ProcessResult runSyncProcess(String bin, List<String> args, {String? workingDirectory}) {
    return processManager.runSync(
      <dynamic>[bin, ...args],
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  @override
  void echoError(String message) {
    stderr += '$message\n';
  }

  @override
  void echoXcodeError(String message) {
    stderr += 'error: $message';
  }

  @override
  void echoXcodeWarning(String message) {
    stderr += 'warning: $message\n';
  }

  @override
  void echo(String message) {
    stdout += message;
  }

  @override
  Never exitApp(int code) {
    // This is an exception for the benefit of unit tests.
    // The real implementation calls `exit(code)`.
    throw Exception('App exited with code $code');
  }
}
