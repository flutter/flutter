// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test exercises the embedding of the native assets mapping in dill files.
// An initial dill file is created by `flutter assemble` and used for running
// the application. This dill must contain the mapping.
// When doing hot reload, this mapping must stay in place.
// When doing a hot restart, a new dill file is pushed. This dill file must also
// contain the native assets mapping.
// When doing a hot reload, this mapping must stay in place.

@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';

import '../src/common.dart';
import 'test_utils.dart' show fileSystem, platform;
import 'transition_test_utils.dart';

final String hostOs = platform.operatingSystem;

final List<String> devices = <String>[
  'flutter-tester',
  hostOs,
];

final List<String> buildSubcommands = <String>[
  hostOs,
  if (hostOs == 'macos') 'ios',
];

final List<String> add2appBuildSubcommands = <String>[
  if (hostOs == 'macos') ...<String>[
    'macos-framework',
    'ios-framework',
  ],
];

/// The build modes to target for each flutter command that supports passing
/// a build mode.
///
/// The flow of compiling kernel as well as bundling dylibs can differ based on
/// build mode, so we should cover this.
const List<String> buildModes = <String>[
  'debug',
  'profile',
  'release',
];

const String packageName = 'package_with_native_assets';

const String exampleAppName = '${packageName}_example';

const String dylibName = 'lib$packageName.dylib';

void main() {
  if (platform.isWindows || platform.isLinux) {
    // TODO(https://github.com/flutter/flutter/issues/129757): Implement.
    return;
  }

  setUpAll(() {
    processManager.runSync(<String>[
      flutterBin,
      'config',
      '--enable-native-assets',
    ]);
  });

  for (final String device in devices) {
    for (final String buildMode in buildModes) {
      if (device == 'flutter-tester' && buildMode != 'debug') {
        continue;
      }
      final String hotReload =
          buildMode == 'debug' ? ' hot reload and hot restart' : '';
      testWithoutContext(
          'flutter run$hotReload with native assets $device $buildMode',
          () async {
        await inTempDir((Directory tempDirectory) async {
          final Directory packageDirectory =
              await createTestProject(packageName, tempDirectory);
          final Directory exampleDirectory =
              packageDirectory.childDirectory('example');

          final ProcessTestResult result = await runFlutter(
            <String>[
              'run',
              '-d$device',
              '--$buildMode',
            ],
            exampleDirectory.path,
            <Transition>[
              Multiple(<Pattern>[
                'Flutter run key commands.',
              ], handler: (String line) {
                if (buildMode == 'debug') {
                  // Do a hot reload diff on the initial dill file.
                  return 'r';
                } else {
                  // No hot reload and hot restart in release mode.
                  return 'q';
                }
              }),
              if (buildMode == 'debug') ...<Transition>[
                Barrier(
                  'Performing hot reload...'.padRight(progressMessageWidth),
                  logging: true,
                ),
                Multiple(<Pattern>[
                  RegExp('Reloaded .*'),
                ], handler: (String line) {
                  // Do a hot restart, pushing a new complete dill file.
                  return 'R';
                }),
                Barrier(
                    'Performing hot restart...'.padRight(progressMessageWidth)),
                Multiple(<Pattern>[
                  RegExp('Restarted application .*'),
                ], handler: (String line) {
                  // Do another hot reload, pushing a diff to the second dill file.
                  return 'r';
                }),
                Barrier(
                  'Performing hot reload...'.padRight(progressMessageWidth),
                  logging: true,
                ),
                Multiple(<Pattern>[
                  RegExp('Reloaded .*'),
                ], handler: (String line) {
                  return 'q';
                }),
              ],
              const Barrier('Application finished.'),
            ],
            logging: false,
          );
          expect(result.exitCode, 0);
          final String stdout = result.stdout.join('\n');
          // Check that we did not fail to resolve the native function in the
          // dynamic library.
          expect(
              stdout,
              isNot(contains(
                  "Invalid argument(s): Couldn't resolve native function 'sum'")));
          // And also check that we did not have any other exceptions that might
          // shadow the exception we would have gotten.
          expect(
              stdout, isNot(contains('EXCEPTION CAUGHT BY WIDGETS LIBRARY')));

          if (device == 'macos') {
            expectDylibIsBundledMacos(exampleDirectory, buildMode);
          }
          if (device == hostOs) {
            expectCCIsPassed(exampleDirectory);
          }
        });
      });
    }
  }

  testWithoutContext('flutter test with native assets', () async {
    await inTempDir((Directory tempDirectory) async {
      final Directory packageDirectory =
          await createTestProject(packageName, tempDirectory);

      final ProcessTestResult result = await runFlutter(
        <String>[
          'test',
        ],
        packageDirectory.path,
        <Transition>[
          Barrier(RegExp('.* All tests passed!')),
        ],
        logging: false,
      );
      expect(result.exitCode, 0);
    });
  });

  for (final String buildSubcommand in buildSubcommands) {
    for (final String buildMode in buildModes) {
      testWithoutContext(
          'flutter build $buildSubcommand with native assets $buildMode',
          () async {
        await inTempDir((Directory tempDirectory) async {
          final Directory packageDirectory =
              await createTestProject(packageName, tempDirectory);
          final Directory exampleDirectory =
              packageDirectory.childDirectory('example');

          final ProcessResult result = processManager.runSync(
            <String>[
              flutterBin,
              'build',
              buildSubcommand,
              '--$buildMode',
            ],
            workingDirectory: exampleDirectory.path,
          );
          expect(result.exitCode, 0);

          if (buildSubcommand == 'macos') {
            expectDylibIsBundledMacos(exampleDirectory, buildMode);
          } else if (buildSubcommand == 'ios') {
            expectDylibIsBundledIos(exampleDirectory, buildMode);
          }
          expectCCIsPassed(exampleDirectory);
        });
      });
    }


    // This could be an hermetic unit test if the native_assets_builder
    // could mock process runs and file system.
    // https://github.com/dart-lang/native/issues/90.
    testWithoutContext(
        'flutter build $buildSubcommand error on static libraries', () async {
      await inTempDir((Directory tempDirectory) async {
        final Directory packageDirectory =
            await createTestProject(packageName, tempDirectory);
        final File buildDotDart = packageDirectory.childFile('build.dart');
        final String buildDotDartContents = await buildDotDart.readAsString();
        // Overrides the build to output static libraries.
        final String buildDotDartContentsNew =
            buildDotDartContents.replaceFirst(
          'final buildConfig = await BuildConfig.fromArgs(args);',
          r'''
  final buildConfig = await BuildConfig.fromArgs([
    '-D${LinkModePreference.configKey}=${LinkModePreference.static}',
    ...args,
  ]);
''',
        );
        expect(buildDotDartContentsNew, isNot(buildDotDartContents));
        await buildDotDart.writeAsString(buildDotDartContentsNew);
        final Directory exampleDirectory =
            packageDirectory.childDirectory('example');

        final ProcessResult result = processManager.runSync(
          <String>[
            flutterBin,
            'build',
            buildSubcommand,
          ],
          workingDirectory: exampleDirectory.path,
        );
        expect(result.exitCode, 1);
        expect(result.stderr,
            contains('link mode set to static, but this is not yet supported'));
      });
    });
  }

  for (final String add2appBuildSubcommand in add2appBuildSubcommands) {
    testWithoutContext(
        'flutter build $add2appBuildSubcommand with native assets', () async {
      await inTempDir((Directory tempDirectory) async {
        final Directory packageDirectory =
            await createTestProject(packageName, tempDirectory);
        final Directory exampleDirectory =
            packageDirectory.childDirectory('example');

        final ProcessResult result = processManager.runSync(
          <String>[
            flutterBin,
            'build',
            add2appBuildSubcommand,
          ],
          workingDirectory: exampleDirectory.path,
        );
        expect(result.exitCode, 0);

        for (final String buildMode in buildModes) {
          expectDylibIsBundledWithFrameworks(exampleDirectory, buildMode,
              add2appBuildSubcommand.replaceAll('-framework', ''));
        }
        expectCCIsPassed(exampleDirectory);
      });
    });
  }
}

/// For `flutter build` we can't easily test whether running the app works.
/// Check that we have the dylibs in the app.
void expectDylibIsBundledMacos(Directory appDirectory, String buildMode) {
  final Directory appBundle = appDirectory.childDirectory(
      'build/$hostOs/Build/Products/${buildMode.upperCaseFirst()}/$exampleAppName.app');
  expect(appBundle, exists);
  final Directory dylibsFolder =
      appBundle.childDirectory('Contents/Frameworks');
  expect(dylibsFolder, exists);
  final File dylib = dylibsFolder.childFile(dylibName);
  expect(dylib, exists);
}

void expectDylibIsBundledIos(Directory appDirectory, String buildMode) {
  final Directory appBundle = appDirectory.childDirectory(
      'build/ios/${buildMode.upperCaseFirst()}-iphoneos/Runner.app');
  expect(appBundle, exists);
  final Directory dylibsFolder = appBundle.childDirectory('Frameworks');
  expect(dylibsFolder, exists);
  final File dylib = dylibsFolder.childFile(dylibName);
  expect(dylib, exists);
}

/// For `flutter build` we can't easily test whether running the app works.
/// Check that we have the dylibs in the app.
void expectDylibIsBundledWithFrameworks(
    Directory appDirectory, String buildMode, String os) {
  final Directory frameworksFolder = appDirectory
      .childDirectory('build/$os/framework/${buildMode.upperCaseFirst()}');
  expect(frameworksFolder, exists);
  final File dylib = frameworksFolder.childFile(dylibName);
  expect(dylib, exists);
}

/// We want to pass the compiler that Flutter uses to the native assets builds.
/// This way we minimize build discrepancies.
void expectCCIsPassed(Directory appDirectory) {
  final Directory nativeAssetsBuilderDir =
      appDirectory.childDirectory('.dart_tool/native_assets_builder/');
  for (final Directory subDir
      in nativeAssetsBuilderDir.listSync().whereType<Directory>()) {
    final File config = subDir.childFile('config.yaml');
    expect(config, exists);
    final String contents = config.readAsStringSync();
    // Dry run does not pass compiler info.
    if (contents.contains('dry_run: true')) {
      continue;
    }
    expect(contents, contains('cc: '));
  }
}

extension on String {
  String upperCaseFirst() {
    return replaceFirst(this[0], this[0].toUpperCase());
  }
}

Future<Directory> createTestProject(
    String packageName, Directory tempDirectory) async {
  final ProcessResult createResult = processManager.runSync(
    <String>[
      flutterBin,
      'create',
      '--template=package_ffi',
      '--platform=macos,ios,linux,windows,android',
      packageName,
    ],
    workingDirectory: tempDirectory.path,
  );

  expect(createResult.exitCode, 0);

  final Directory packageDirectory = tempDirectory.childDirectory(packageName);
  return packageDirectory;
}

Future<void> inTempDir(
    Future<void> Function(Directory tempDirectory) fun) async {
  final Directory tempDirectory = fileSystem.directory(fileSystem
      .systemTempDirectory
      .createTempSync()
      .resolveSymbolicLinksSync());
  try {
    await fun(tempDirectory);
  } finally {
    tryToDelete(tempDirectory);
  }
}
