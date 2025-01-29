// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late FakeAnalytics fakeAnalytics;
  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fileSystem,
      fakeFlutterVersion: FakeFlutterVersion(),
    );
  });

  group('Finds single apk in standalone project', () {
    // Can't use all values of BuildMode because jitrelease is not supported when building
    // with command-line.
    for (final BuildMode buildMode in <BuildMode>[
      BuildMode.release,
      BuildMode.debug,
      BuildMode.profile,
    ]) {
      testWithoutContext('when flavor contains multiple dimensions ($buildMode)', () {
        final FlutterProject project = generateFakeApks(<String>[
          'app-fooBar-$buildMode.apk',
        ], fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              'fooBar',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/app/outputs/flutter-apk/app-fooBar-$buildMode.apk');
      });

      testWithoutContext('when flavor contains underscore ($buildMode)', () {
        final FlutterProject project = generateFakeApks(<String>[
          'app-foo_bar-$buildMode.apk',
        ], fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              'foo_bar',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/app/outputs/flutter-apk/app-foo_bar-$buildMode.apk');
      });

      testWithoutContext('when flavor contains underscores and uppercase letters ($buildMode)', () {
        final FlutterProject project = generateFakeApks(<String>[
          'app-foo_Bar-$buildMode.apk',
        ], fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              'foo_Bar',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/app/outputs/flutter-apk/app-foo_Bar-$buildMode.apk');
      });

      testWithoutContext('when flavor does not contains underscores ($buildMode)', () {
        final FlutterProject project = generateFakeApks(<String>[
          'app-foo-$buildMode.apk',
        ], fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              'foo',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/app/outputs/flutter-apk/app-foo-$buildMode.apk');
      });

      testWithoutContext(
        'when flavor does not contains underscores but contains uppercase letters ($buildMode)',
        () {
          final FlutterProject project = generateFakeApks(<String>[
            'app-foo-$buildMode.apk',
          ], fileSystem);
          final Iterable<File> apks = findApkFiles(
            project,
            AndroidBuildInfo(
              BuildInfo(
                buildMode,
                'Foo',
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
            BufferLogger.test(),
            fakeAnalytics,
          );

          expect(apks, hasLength(1));
          expect(apks.first.path, '/build/app/outputs/flutter-apk/app-foo-$buildMode.apk');
        },
      );

      testWithoutContext('when no flavor used ($buildMode)', () {
        final FlutterProject project = generateFakeApks(<String>['app-$buildMode.apk'], fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              null,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/app/outputs/flutter-apk/app-$buildMode.apk');
      });

      testWithoutContext(
        'when archiveName / archiveBaseName from gradle is not standart "app" ($buildMode)',
        () {
          final FlutterProject project = generateFakeApks(<String>[
            'foo-$buildMode.apk',
          ], fileSystem);
          final Iterable<File> apks = findApkFiles(
            project,
            AndroidBuildInfo(
              BuildInfo(
                buildMode,
                null,
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
            BufferLogger.test(),
            fakeAnalytics,
          );

          expect(apks, hasLength(1));
          expect(apks.first.path, '/build/app/outputs/flutter-apk/foo-$buildMode.apk');
        },
      );
    }

    testWithoutContext("when there're apks from another builds with different parameters", () {
      final FlutterProject project = generateFakeApks(<String>[
        'app-release.apk',
        'app-debug.apk',
        'app-flavor-debug.apk',
        'app-x86-flavor-release.apk',
      ], fileSystem);
      final Iterable<File> apks = findApkFiles(
        project,
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
        BufferLogger.test(),
        fakeAnalytics,
      );

      expect(apks, hasLength(1));
      expect(apks.first.path, '/build/app/outputs/flutter-apk/app-release.apk');
    });
  });

  group('Finds single apk in module project', () {
    // Can't use all values of BuildMode because jitrelease is not supported when building
    // with command-line.
    for (final BuildMode buildMode in <BuildMode>[
      BuildMode.release,
      BuildMode.debug,
      BuildMode.profile,
    ]) {
      testWithoutContext('when flavor contains multiple dimensions ($buildMode)', () {
        final FlutterProject project = generateFakeApks(
          <String>['app-fooBar-$buildMode.apk'],
          fileSystem,
          directoryName: 'fooBar/$buildMode',
          isModule: true,
        );
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              'fooBar',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(
          apks.first.path,
          '/build/host/outputs/apk/fooBar/$buildMode/app-fooBar-$buildMode.apk',
        );
      });

      testWithoutContext('when flavor contains underscore ($buildMode)', () {
        final FlutterProject project = generateFakeApks(
          <String>['app-foo_bar-$buildMode.apk'],
          fileSystem,
          directoryName: 'foo_bar',
          isModule: true,
        );
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              'foo_bar',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/host/outputs/apk/foo_bar/app-foo_bar-$buildMode.apk');
      });

      testWithoutContext('when flavor contains underscores and uppercase letters ($buildMode)', () {
        final FlutterProject project = generateFakeApks(
          <String>['app-foo_Bar-$buildMode.apk'],
          fileSystem,
          directoryName: 'foo_Bar',
          isModule: true,
        );
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              'foo_Bar',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/host/outputs/apk/foo_Bar/app-foo_Bar-$buildMode.apk');
      });

      testWithoutContext('when flavor does not contains underscores ($buildMode)', () {
        final FlutterProject project = generateFakeApks(
          <String>['app-foo-$buildMode.apk'],
          fileSystem,
          directoryName: 'foo',
          isModule: true,
        );
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              'foo',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/host/outputs/apk/foo/app-foo-$buildMode.apk');
      });

      testWithoutContext(
        'when flavor does not contains underscores but contains uppercase letters ($buildMode)',
        () {
          final FlutterProject project = generateFakeApks(
            <String>['app-foo-$buildMode.apk'],
            fileSystem,
            directoryName: 'foo',
            isModule: true,
          );
          final Iterable<File> apks = findApkFiles(
            project,
            AndroidBuildInfo(
              BuildInfo(
                buildMode,
                'Foo',
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
            BufferLogger.test(),
            fakeAnalytics,
          );

          expect(apks, hasLength(1));
          expect(apks.first.path, '/build/host/outputs/apk/foo/app-foo-$buildMode.apk');
        },
      );

      testWithoutContext('when no flavor used ($buildMode)', () {
        final FlutterProject project = generateFakeApks(
          <String>['app-$buildMode.apk'],
          fileSystem,
          directoryName: '$buildMode',
          isModule: true,
        );
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              null,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(apks.first.path, '/build/host/outputs/apk/$buildMode/app-$buildMode.apk');
      });

      testWithoutContext('when multidimensional flavor used ($buildMode)', () {
        // in multidimensional flavors, flavor name passed to flutter as "flutterName" will be
        // converted to kebab-case in apk name.
        // Works only for module projects because standalone projects copies apk to flutter-apk directory
        // and creates new name where flavor is always same as passed from command-line.
        const String flavorName = 'fooBar';
        final FlutterProject project = generateFakeApks(
          <String>['app-foo-bar-$buildMode.apk'],
          fileSystem,
          isModule: true,
          directoryName: '$flavorName/$buildMode',
        );
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              flavorName,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(1));
        expect(
          apks.first.path,
          '/build/host/outputs/apk/$flavorName/$buildMode/app-foo-bar-$buildMode.apk',
        );
      });

      testWithoutContext(
        'when archiveName / archiveBaseName from gradle is not standart "app" ($buildMode)',
        () {
          final FlutterProject project = generateFakeApks(
            <String>['foo-$buildMode.apk'],
            fileSystem,
            isModule: true,
            directoryName: '$buildMode',
          );
          final Iterable<File> apks = findApkFiles(
            project,
            AndroidBuildInfo(
              BuildInfo(
                buildMode,
                null,
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
            BufferLogger.test(),
            fakeAnalytics,
          );

          expect(apks, hasLength(1));
          expect(apks.first.path, '/build/host/outputs/apk/$buildMode/foo-$buildMode.apk');
        },
      );
    }
  });

  group('Finds split apk in standalone project', () {
    for (final BuildMode buildMode in <BuildMode>[
      BuildMode.release,
      BuildMode.debug,
      BuildMode.profile,
    ]) {
      testWithoutContext('when flavor contains multiple dimensions ($buildMode)', () {
        const String flavorName = 'fooBar';
        final List<String> appNames = <String>[
          'app-armeabi-v7a-$flavorName-$buildMode.apk',
          'app-arm64-v8a-$flavorName-$buildMode.apk',
          'app-x86_64-$flavorName-$buildMode.apk',
        ];
        final List<AndroidArch> targetArches = <AndroidArch>[
          AndroidArch.arm64_v8a,
          AndroidArch.armeabi_v7a,
          AndroidArch.x86_64,
        ];
        if (!buildMode.isJit) {
          appNames.add('app-x86-$flavorName-$buildMode.apk');
          targetArches.add(AndroidArch.x86);
        }
        final FlutterProject project = generateFakeApks(appNames, fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              flavorName,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
            splitPerAbi: true,
            targetArchs: targetArches,
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(buildMode.isJit ? 3 : 4));
        for (final String name in appNames) {
          apks.singleWhere((File file) => file.path == '/build/app/outputs/flutter-apk/$name');
        }
      });

      testWithoutContext('when flavor contains underscore ($buildMode)', () {
        const String flavorName = 'foo_bar';
        final List<String> appNames = <String>[
          'app-armeabi-v7a-$flavorName-$buildMode.apk',
          'app-arm64-v8a-$flavorName-$buildMode.apk',
          'app-x86_64-$flavorName-$buildMode.apk',
        ];
        final List<AndroidArch> targetArches = <AndroidArch>[
          AndroidArch.arm64_v8a,
          AndroidArch.armeabi_v7a,
          AndroidArch.x86_64,
        ];
        if (!buildMode.isJit) {
          appNames.add('app-x86-$flavorName-$buildMode.apk');
          targetArches.add(AndroidArch.x86);
        }
        final FlutterProject project = generateFakeApks(appNames, fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              flavorName,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
            splitPerAbi: true,
            targetArchs: targetArches,
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(buildMode.isJit ? 3 : 4));
        for (final String name in appNames) {
          apks.singleWhere((File file) => file.path == '/build/app/outputs/flutter-apk/$name');
        }
      });

      testWithoutContext('when flavor contains underscores and uppercase letters ($buildMode)', () {
        const String flavorName = 'foo_Bar';
        final List<String> appNames = <String>[
          'app-armeabi-v7a-$flavorName-$buildMode.apk',
          'app-arm64-v8a-$flavorName-$buildMode.apk',
          'app-x86_64-$flavorName-$buildMode.apk',
        ];
        final List<AndroidArch> targetArches = <AndroidArch>[
          AndroidArch.arm64_v8a,
          AndroidArch.armeabi_v7a,
          AndroidArch.x86_64,
        ];
        if (!buildMode.isJit) {
          appNames.add('app-x86-$flavorName-$buildMode.apk');
          targetArches.add(AndroidArch.x86);
        }
        final FlutterProject project = generateFakeApks(appNames, fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              flavorName,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
            splitPerAbi: true,
            targetArchs: targetArches,
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(buildMode.isJit ? 3 : 4));
        for (final String name in appNames) {
          apks.singleWhere((File file) => file.path == '/build/app/outputs/flutter-apk/$name');
        }
      });

      testWithoutContext('when flavor does not contains underscores ($buildMode)', () {
        const String flavorName = 'foo';
        final List<String> appNames = <String>[
          'app-armeabi-v7a-$flavorName-$buildMode.apk',
          'app-arm64-v8a-$flavorName-$buildMode.apk',
          'app-x86_64-$flavorName-$buildMode.apk',
        ];
        final List<AndroidArch> targetArches = <AndroidArch>[
          AndroidArch.arm64_v8a,
          AndroidArch.armeabi_v7a,
          AndroidArch.x86_64,
        ];
        if (!buildMode.isJit) {
          appNames.add('app-x86-$flavorName-$buildMode.apk');
          targetArches.add(AndroidArch.x86);
        }
        final FlutterProject project = generateFakeApks(appNames, fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              flavorName,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
            splitPerAbi: true,
            targetArchs: targetArches,
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(buildMode.isJit ? 3 : 4));
        for (final String name in appNames) {
          apks.singleWhere((File file) => file.path == '/build/app/outputs/flutter-apk/$name');
        }
      });

      testWithoutContext(
        'when flavor does not contains underscores but contains uppercase letters ($buildMode)',
        () {
          const String flavorName = 'foo';
          final List<String> appNames = <String>[
            'app-armeabi-v7a-$flavorName-$buildMode.apk',
            'app-arm64-v8a-$flavorName-$buildMode.apk',
            'app-x86_64-$flavorName-$buildMode.apk',
          ];
          final List<AndroidArch> targetArches = <AndroidArch>[
            AndroidArch.arm64_v8a,
            AndroidArch.armeabi_v7a,
            AndroidArch.x86_64,
          ];
          if (!buildMode.isJit) {
            appNames.add('app-x86-$flavorName-$buildMode.apk');
            targetArches.add(AndroidArch.x86);
          }
          final FlutterProject project = generateFakeApks(appNames, fileSystem);
          final Iterable<File> apks = findApkFiles(
            project,
            AndroidBuildInfo(
              BuildInfo(
                buildMode,
                'Foo', // using capitalized flavor name
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
              splitPerAbi: true,
              targetArchs: targetArches,
            ),
            BufferLogger.test(),
            fakeAnalytics,
          );

          expect(apks, hasLength(buildMode.isJit ? 3 : 4));
          for (final String name in appNames) {
            apks.singleWhere((File file) => file.path == '/build/app/outputs/flutter-apk/$name');
          }
        },
      );

      testWithoutContext('when no flavor used ($buildMode)', () {
        final List<String> appNames = <String>[
          'app-armeabi-v7a-$buildMode.apk',
          'app-arm64-v8a-$buildMode.apk',
          'app-x86_64-$buildMode.apk',
        ];
        final List<AndroidArch> targetArches = <AndroidArch>[
          AndroidArch.arm64_v8a,
          AndroidArch.armeabi_v7a,
          AndroidArch.x86_64,
        ];
        if (!buildMode.isJit) {
          appNames.add('app-x86-$buildMode.apk');
          targetArches.add(AndroidArch.x86);
        }
        final FlutterProject project = generateFakeApks(appNames, fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              null,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
            splitPerAbi: true,
            targetArchs: targetArches,
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(buildMode.isJit ? 3 : 4));
        for (final String name in appNames) {
          apks.singleWhere((File file) => file.path == '/build/app/outputs/flutter-apk/$name');
        }
      });

      testWithoutContext('when archiveName from gradle is not standart "app" ($buildMode)', () {
        final List<String> appNames = <String>[
          'foo-armeabi-v7a-$buildMode.apk',
          'foo-arm64-v8a-$buildMode.apk',
          'foo-x86_64-$buildMode.apk',
        ];
        final List<AndroidArch> targetArches = <AndroidArch>[
          AndroidArch.arm64_v8a,
          AndroidArch.armeabi_v7a,
          AndroidArch.x86_64,
        ];
        if (!buildMode.isJit) {
          appNames.add('foo-x86-$buildMode.apk');
          targetArches.add(AndroidArch.x86);
        }
        final FlutterProject project = generateFakeApks(appNames, fileSystem);
        final Iterable<File> apks = findApkFiles(
          project,
          AndroidBuildInfo(
            BuildInfo(
              buildMode,
              null,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
            splitPerAbi: true,
            targetArchs: targetArches,
          ),
          BufferLogger.test(),
          fakeAnalytics,
        );

        expect(apks, hasLength(buildMode.isJit ? 3 : 4));
        for (final String name in appNames) {
          apks.singleWhere((File file) => file.path == '/build/app/outputs/flutter-apk/$name');
        }
      });
    }
  });
}

FlutterProject generateFakeApks(
  Iterable<String> fileName,
  FileSystem fileSystem, {
  String? directoryName,
  bool isModule = false,
}) {
  if (isModule) {
    final File pubspec = fileSystem.currentDirectory.childFile('pubspec.yaml');
    pubspec.createSync();
    pubspec.writeAsStringSync('''
name: foo_bar

flutter:
  module:
    foo: bar
''');
  }
  final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

  final Directory apkBaseDirectory =
      directoryName != null
          ? getApkDirectory(project).childDirectory(directoryName)
          : getApkDirectory(project);
  apkBaseDirectory.createSync(recursive: true);

  for (final String name in fileName) {
    apkBaseDirectory.childFile(name).createSync();
  }
  return project;
}
