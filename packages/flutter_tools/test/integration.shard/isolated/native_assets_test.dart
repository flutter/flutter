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
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:native_assets_cli/native_assets_cli_internal.dart';

import '../../src/common.dart';
import '../test_utils.dart' show ProcessResultMatcher, fileSystem, platform;
import '../transition_test_utils.dart';

final String hostOs = platform.operatingSystem;

final List<String> devices = <String>[
  'flutter-tester',
  hostOs,
];

final List<String> buildSubcommands = <String>[
  hostOs,
  if (hostOs == 'macos') 'ios',
  'apk',
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

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    // TODO(dacoharkes): Implement Fuchsia. https://github.com/flutter/flutter/issues/129757
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
      final String hotReload = buildMode == 'debug' ? ' hot reload and hot restart' : '';
      testWithoutContext('flutter run$hotReload with native assets $device $buildMode', () async {
        await inTempDir((Directory tempDirectory) async {
          final Directory packageDirectory = await createTestProject(packageName, tempDirectory);
          final Directory exampleDirectory = packageDirectory.childDirectory('example');

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
                Barrier('Performing hot restart...'.padRight(progressMessageWidth)),
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
          if (result.exitCode != 0) {
            throw Exception('flutter run failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}');
          }
          final String stdout = result.stdout.join('\n');
          // Check that we did not fail to resolve the native function in the
          // dynamic library.
          expect(stdout, isNot(contains("Invalid argument(s): Couldn't resolve native function 'sum'")));
          // And also check that we did not have any other exceptions that might
          // shadow the exception we would have gotten.
          expect(stdout, isNot(contains('EXCEPTION CAUGHT BY WIDGETS LIBRARY')));

          switch (device) {
            case 'macos':
              expectDylibIsBundledMacOS(exampleDirectory, buildMode);
            case 'linux':
              expectDylibIsBundledLinux(exampleDirectory, buildMode);
            case 'windows':
              expectDylibIsBundledWindows(exampleDirectory, buildMode);
          }
          if (device == hostOs) {
            expectCCompilerIsConfigured(exampleDirectory);
          }
        });
      });
    }
  }

  testWithoutContext('flutter test with native assets', () async {
    await inTempDir((Directory tempDirectory) async {
      final Directory packageDirectory = await createTestProject(packageName, tempDirectory);

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
      if (result.exitCode != 0) {
        throw Exception('flutter test failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}');
      }
    });
  });

  for (final String buildSubcommand in buildSubcommands) {
    for (final String buildMode in buildModes) {
      testWithoutContext('flutter build $buildSubcommand with native assets $buildMode', () async {
        await inTempDir((Directory tempDirectory) async {
          final Directory packageDirectory = await createTestProject(packageName, tempDirectory);
          final Directory exampleDirectory = packageDirectory.childDirectory('example');

          final ProcessResult result = processManager.runSync(
            <String>[
              flutterBin,
              'build',
              buildSubcommand,
              '--$buildMode',
              if (buildSubcommand == 'ios') '--no-codesign',
            ],
            workingDirectory: exampleDirectory.path,
          );
          if (result.exitCode != 0) {
            throw Exception('flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}');
          }

          switch (buildSubcommand) {
            case 'macos':
              expectDylibIsBundledMacOS(exampleDirectory, buildMode);
            case 'ios':
              expectDylibIsBundledIos(exampleDirectory, buildMode);
            case 'linux':
              expectDylibIsBundledLinux(exampleDirectory, buildMode);
            case 'windows':
              expectDylibIsBundledWindows(exampleDirectory, buildMode);
            case 'apk':
              expectDylibIsBundledAndroid(exampleDirectory, buildMode);
          }
          expectCCompilerIsConfigured(exampleDirectory);
        });
      });
    }

    // This could be an hermetic unit test if the native_assets_builder
    // could mock process runs and file system.
    // https://github.com/dart-lang/native/issues/90.
    testWithoutContext('flutter build $buildSubcommand error on static libraries', () async {
      await inTempDir((Directory tempDirectory) async {
        final Directory packageDirectory = await createTestProject(packageName, tempDirectory);
        final File buildDotDart =
            packageDirectory.childDirectory('hook').childFile('build.dart');
        final String buildDotDartContents = await buildDotDart.readAsString();
        // Overrides the build to output static libraries.
        final String buildDotDartContentsNew = buildDotDartContents.replaceFirst(
          'await build(args, (config, output) async {',
          '''
  await build([
    '-D${LinkModePreferenceImpl.configKey}=${LinkModePreferenceImpl.static}',
    ...args,
  ], (config, output) async {
''',
        );
        expect(buildDotDartContentsNew, isNot(buildDotDartContents));
        await buildDotDart.writeAsString(buildDotDartContentsNew);
        final Directory exampleDirectory = packageDirectory.childDirectory('example');

        final ProcessResult result = processManager.runSync(
          <String>[
            flutterBin,
            'build',
            buildSubcommand,
            if (buildSubcommand == 'ios') '--no-codesign',
            if (buildSubcommand == 'windows') '-v' // Requires verbose mode for error.
          ],
          workingDirectory: exampleDirectory.path,
        );
        expect(
          (result.stdout as String) + (result.stderr as String),
          contains('link mode set to static, but this is not yet supported'),
        );
        expect(result.exitCode, isNot(0));
      });
    });
  }

  for (final String add2appBuildSubcommand in add2appBuildSubcommands) {
    testWithoutContext('flutter build $add2appBuildSubcommand with native assets', () async {
      await inTempDir((Directory tempDirectory) async {
        final Directory packageDirectory = await createTestProject(packageName, tempDirectory);
        final Directory exampleDirectory = packageDirectory.childDirectory('example');

        final ProcessResult result = processManager.runSync(
          <String>[
            flutterBin,
            'build',
            add2appBuildSubcommand,
          ],
          workingDirectory: exampleDirectory.path,
        );
        if (result.exitCode != 0) {
          throw Exception('flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}');
        }

        for (final String buildMode in buildModes) {
          expectDylibIsBundledWithFrameworks(exampleDirectory, buildMode, add2appBuildSubcommand.replaceAll('-framework', ''));
        }
        expectCCompilerIsConfigured(exampleDirectory);
      });
    });
  }
}

/// For `flutter build` we can't easily test whether running the app works.
/// Check that we have the dylibs in the app.
void expectDylibIsBundledMacOS(Directory appDirectory, String buildMode) {
  final Directory appBundle = appDirectory.childDirectory('build/$hostOs/Build/Products/${buildMode.upperCaseFirst()}/$exampleAppName.app');
  expect(appBundle, exists);
  final Directory frameworksFolder =
      appBundle.childDirectory('Contents/Frameworks');
  expect(frameworksFolder, exists);

  // MyFramework.framework/
  //   MyFramework  -> Versions/Current/MyFramework
  //   Resources    -> Versions/Current/Resources
  //   Versions/
  //     A/
  //       MyFramework
  //       Resources/
  //         Info.plist
  //     Current  -> A
  const String frameworkName = packageName;
  final Directory frameworkDir =
      frameworksFolder.childDirectory('$frameworkName.framework');
  final Directory versionsDir = frameworkDir.childDirectory('Versions');
  final Directory versionADir = versionsDir.childDirectory('A');
  final Directory resourcesDir = versionADir.childDirectory('Resources');
  expect(resourcesDir, exists);
  final File dylibFile = versionADir.childFile(frameworkName);
  expect(dylibFile, exists);
  final Link currentLink = versionsDir.childLink('Current');
  expect(currentLink, exists);
  expect(currentLink.resolveSymbolicLinksSync(), versionADir.path);
  final Link resourcesLink = frameworkDir.childLink('Resources');
  expect(resourcesLink, exists);
  expect(resourcesLink.resolveSymbolicLinksSync(), resourcesDir.path);
  final Link dylibLink = frameworkDir.childLink(frameworkName);
  expect(dylibLink, exists);
  expect(dylibLink.resolveSymbolicLinksSync(), dylibFile.path);
}

void expectDylibIsBundledIos(Directory appDirectory, String buildMode) {
  final Directory appBundle = appDirectory.childDirectory('build/ios/${buildMode.upperCaseFirst()}-iphoneos/Runner.app');
  expect(appBundle, exists);
  final Directory frameworksFolder = appBundle.childDirectory('Frameworks');
  expect(frameworksFolder, exists);
  const String frameworkName = packageName;
  final File dylib = frameworksFolder
      .childDirectory('$frameworkName.framework')
      .childFile(frameworkName);
  expect(dylib, exists);
}

/// Checks that dylibs are bundled.
///
/// Sample path: build/linux/x64/release/bundle/lib/libmy_package.so
void expectDylibIsBundledLinux(Directory appDirectory, String buildMode) {
  // Linux does not support cross compilation, so always only check current architecture.
  final String architecture = ArchitectureImpl.current.dartPlatform;
  final Directory appBundle = appDirectory
      .childDirectory('build')
      .childDirectory(hostOs)
      .childDirectory(architecture)
      .childDirectory(buildMode)
      .childDirectory('bundle');
  expect(appBundle, exists);
  final Directory dylibsFolder = appBundle.childDirectory('lib');
  expect(dylibsFolder, exists);
  final File dylib =
      dylibsFolder.childFile(OSImpl.linux.dylibFileName(packageName));
  expect(dylib, exists);
}

/// Checks that dylibs are bundled.
///
/// Sample path: build\windows\x64\runner\Debug\my_package_example.exe
void expectDylibIsBundledWindows(Directory appDirectory, String buildMode) {
  // Linux does not support cross compilation, so always only check current architecture.
  final String architecture = ArchitectureImpl.current.dartPlatform;
  final Directory appBundle = appDirectory
      .childDirectory('build')
      .childDirectory(hostOs)
      .childDirectory(architecture)
      .childDirectory('runner')
      .childDirectory(buildMode.upperCaseFirst());
  expect(appBundle, exists);
  final File dylib =
      appBundle.childFile(OSImpl.windows.dylibFileName(packageName));
  expect(dylib, exists);
}

void expectDylibIsBundledAndroid(Directory appDirectory, String buildMode) {
  final File apk = appDirectory
      .childDirectory('build')
      .childDirectory('app')
      .childDirectory('outputs')
      .childDirectory('flutter-apk')
      .childFile('app-$buildMode.apk');
  expect(apk, exists);
  final OperatingSystemUtils osUtils = OperatingSystemUtils(
    fileSystem: fileSystem,
    logger: BufferLogger.test(),
    platform: platform,
    processManager: processManager,
  );
  final Directory apkUnzipped = appDirectory.childDirectory('apk-unzipped');
  apkUnzipped.createSync();
  osUtils.unzip(apk, apkUnzipped);
  final Directory lib = apkUnzipped.childDirectory('lib');
  for (final String arch in <String>['arm64-v8a', 'armeabi-v7a', 'x86_64']) {
    final Directory archDir = lib.childDirectory(arch);
    expect(archDir, exists);
    // The dylibs should be next to the flutter and app so.
    expect(archDir.childFile('libflutter.so'), exists);
    if (buildMode != 'debug') {
      expect(archDir.childFile('libapp.so'), exists);
    }
    final File dylib =
        archDir.childFile(OSImpl.android.dylibFileName(packageName));
    expect(dylib, exists);
  }
}

/// For `flutter build` we can't easily test whether running the app works.
/// Check that we have the dylibs in the app.
void expectDylibIsBundledWithFrameworks(Directory appDirectory, String buildMode, String os) {
  final Directory frameworksFolder = appDirectory.childDirectory('build/$os/framework/${buildMode.upperCaseFirst()}');
  expect(frameworksFolder, exists);
  const String frameworkName = packageName;
  final File dylib = frameworksFolder
      .childDirectory('$frameworkName.framework')
      .childFile(frameworkName);
  expect(dylib, exists);
}

/// Check that the native assets are built with the C Compiler that Flutter uses.
///
/// This inspects the build configuration to see if the C compiler was configured.
void expectCCompilerIsConfigured(Directory appDirectory) {
  final Directory nativeAssetsBuilderDir = appDirectory.childDirectory('.dart_tool/native_assets_builder/');
  for (final Directory subDir in nativeAssetsBuilderDir.listSync().whereType<Directory>()) {
    final File config = subDir.childFile('config.json');
    expect(config, exists);
    final String contents = config.readAsStringSync();
    // Dry run does not pass compiler info.
    if (contents.contains('"dry_run": true')) {
      continue;
    }
    expect(contents, contains('"cc": '));
  }
}

extension on String {
  String upperCaseFirst() {
    return replaceFirst(this[0], this[0].toUpperCase());
  }
}

Future<Directory> createTestProject(String packageName, Directory tempDirectory) async {
  final ProcessResult result = processManager.runSync(
    <String>[
      flutterBin,
      'create',
      '--no-pub',
      '--template=package_ffi',
      packageName,
    ],
    workingDirectory: tempDirectory.path,
  );
  if (result.exitCode != 0) {
    throw Exception(
      'flutter create failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
    );
  }

  final Directory packageDirectory = tempDirectory.childDirectory(packageName);

  // No platform-specific boilerplate files.
  expect(packageDirectory.childDirectory('android/'), isNot(exists));
  expect(packageDirectory.childDirectory('ios/'), isNot(exists));
  expect(packageDirectory.childDirectory('linux/'), isNot(exists));
  expect(packageDirectory.childDirectory('macos/'), isNot(exists));
  expect(packageDirectory.childDirectory('windows/'), isNot(exists));

  await pinDependencies(packageDirectory.childFile('pubspec.yaml'));
  await pinDependencies(
      packageDirectory.childDirectory('example').childFile('pubspec.yaml'));

  final ProcessResult result2 = await processManager.run(
    <String>[
      flutterBin,
      'pub',
      'get',
    ],
    workingDirectory: packageDirectory.path,
  );
  expect(result2, const ProcessResultMatcher());

  return packageDirectory;
}

Future<void> pinDependencies(File pubspecFile) async {
  expect(pubspecFile, exists);
  final String oldPubspec = await pubspecFile.readAsString();
  final String newPubspec = oldPubspec.replaceAll(RegExp(r':\s*\^'), ': ');
  expect(newPubspec, isNot(oldPubspec));
  await pubspecFile.writeAsString(newPubspec);
}

Future<void> inTempDir(Future<void> Function(Directory tempDirectory) fun) async {
  final Directory tempDirectory = fileSystem.directory(fileSystem.systemTempDirectory.createTempSync().resolveSymbolicLinksSync());
  try {
    await fun(tempDirectory);
  } finally {
    tryToDelete(tempDirectory);
  }
}
