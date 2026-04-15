// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:hooks/hooks.dart';
import 'package:yaml/yaml.dart';

import '../../src/common.dart';
import '../test_utils.dart' show ProcessResultMatcher, fileSystem, flutterBin, platform;
import '../transition_test_utils.dart';

Future<Directory> createTestProject(String packageName, Directory tempDirectory) async {
  final ProcessResult result = processManager.runSync(<String>[
    flutterBin,
    'create',
    '--no-pub',
    '--template=package_ffi',
    packageName,
  ], workingDirectory: tempDirectory.path);
  if (result.exitCode != 0) {
    throw Exception(
      'flutter create failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
    );
  }

  final Directory packageDirectory = tempDirectory.childDirectory(packageName);

  // No platform-specific boilerplate files.
  expect(packageDirectory.childDirectory('android'), isNot(exists));
  expect(packageDirectory.childDirectory('ios'), isNot(exists));
  expect(packageDirectory.childDirectory('linux'), isNot(exists));
  expect(packageDirectory.childDirectory('macos'), isNot(exists));
  expect(packageDirectory.childDirectory('windows'), isNot(exists));

  await pinDependencies(packageDirectory.childFile('pubspec.yaml'));
  await pinDependencies(packageDirectory.childDirectory('example').childFile('pubspec.yaml'));

  await addTestProjectAsDependency(packageName, packageDirectory, 'link_hook');
  await addLinkHookUse(packageName, packageDirectory);

  await addTestProjectAsDependency(packageName, packageDirectory, 'hook_user_defines');
  await addUserDefine(packageName, packageDirectory);

  await addDynamicallyLinkedNativeLibrary(packageName, packageDirectory);

  final ProcessResult result2 = await processManager.run(<String>[
    flutterBin,
    'pub',
    'get',
  ], workingDirectory: packageDirectory.path);
  expect(result2, const ProcessResultMatcher());

  return packageDirectory;
}

Future<void> addTestProjectAsDependency(
  String packageName,
  Directory packageDirectory,
  String testProject,
) async {
  final Directory flutterDirectory = fileSystem.currentDirectory.parent.parent;
  final Directory linkHookDirectory = flutterDirectory
      .childDirectory('dev')
      .childDirectory('integration_tests')
      .childDirectory(testProject);
  expect(linkHookDirectory, exists);

  final File linkHookPubspecFile = linkHookDirectory.childFile('pubspec.yaml');
  final File thisPubspecFile = packageDirectory.childFile('pubspec.yaml');

  final Map<String, Object?> linkHookPubspec = _pubspecAsMutableJson(
    linkHookPubspecFile.readAsStringSync(),
  );
  final linkHooksDependencies = linkHookPubspec['dependencies']! as Map<String, Object?>;
  final linkHooksDevDependencies = linkHookPubspec['dev_dependencies']! as Map<String, Object?>;

  final Map<String, Object?> thisPubspec = _pubspecAsMutableJson(
    thisPubspecFile.readAsStringSync(),
  );

  final thisDependencies = thisPubspec['dependencies']! as Map<String, Object?>;
  final thisDevDependencies = thisPubspec['dev_dependencies']! as Map<String, Object?>;

  // Flutter CI uses pinned dependencies for all packages (including
  // dev/integration_tests/link_hook) for deterministic testing on CI.
  //
  // The ffi template that was generated with `flutter create` does not use
  // pinned dependencies.
  //
  // We ensure that the test package we generate here will have versions
  // compatible with the one from flutter CIs pinned dependencies.
  _updateDependencies(thisDependencies, linkHooksDependencies);
  _updateDependencies(thisDevDependencies, linkHooksDependencies);
  // Resolving dependencies for this package wouldn't normally use
  // the dev dependencies of the `link_hook` package. But there may be some
  // non-dev `link_hook` dependencies that affect resolution of dev
  // dependencies. So by making this compatible to `link_hook`s dev dependencies
  // we implicitly also make it compatible to `link_hook`s non-dev dependencies.
  //
  // Example: `link_hook` has `test_core` as dependency and `test` as dev
  // dependency. By using the same version of `test` in this package as
  // `link_hook` we implicitly are guaranteed to also get a version of
  // `test_core` that is compatible (and `test_core` is pinned in `link_hook`)
  _updateDependencies(thisDependencies, linkHooksDevDependencies);
  _updateDependencies(thisDevDependencies, linkHooksDevDependencies);
  thisDependencies[testProject] = <String, Object?>{'path': linkHookDirectory.path};

  await thisPubspecFile.writeAsString(json.encode(thisPubspec));
}

Future<void> addLinkHookUse(String packageName, Directory packageDirectory) async {
  final File dartFile = packageDirectory.childDirectory('lib').childFile('$packageName.dart');
  final String dartFileOld = (await dartFile.readAsString()).replaceAll('\r\n', '\n');
  // Replace with something that results in the same resulting int, so that the
  // tests don't have to be updated.
  final String dartFileNew = dartFileOld.replaceFirst(
    '''
import '${packageName}_bindings_generated.dart' as bindings;
''',
    '''
import 'package:link_hook/link_hook.dart' as l;

import '${packageName}_bindings_generated.dart' as bindings;
''',
  );
  expect(dartFileNew, isNot(dartFileOld));
  final String dartFileNew2 = dartFileNew.replaceFirst(
    'int sum(int a, int b) => bindings.sum(a, b);',
    'int sum(int a, int b) => bindings.sum(a, b) + l.difference(2, 1) - 1;',
  );
  expect(dartFileNew2, isNot(dartFileNew));
  await dartFile.writeAsString(dartFileNew2);
}

/// Adds a user-define to the pubspec of the package and the example project.
///
/// The build hook will fail if the user-define is not set. So, we don't have to
/// actually invoke the native code from the test project. If it succeeds to
/// build, then the user-define is properly wired through.
Future<void> addUserDefine(String packageName, Directory packageDirectory) async {
  for (final pubspecFile in <File>[
    packageDirectory.childFile('pubspec.yaml'),
    packageDirectory.childDirectory('example').childFile('pubspec.yaml'),
  ]) {
    final Map<String, Object?> thisPubspec = _pubspecAsMutableJson(pubspecFile.readAsStringSync());
    thisPubspec['hooks'] = <String, Map<String, Map<String, int>>>{
      'user_defines': <String, Map<String, int>>{
        'hook_user_defines': <String, int>{'magic_value': 1000},
      },
    };

    await pubspecFile.writeAsString(json.encode(thisPubspec));
  }
}

Map<String, Object?> _pubspecAsMutableJson(String pubspecContent) {
  return json.decode(json.encode(loadYaml(pubspecContent))) as Map<String, Object?>;
}

void _updateDependencies(Map<String, Object?> to, Map<String, Object?> from) {
  for (final String packageName in to.keys) {
    to[packageName] = from[packageName] ?? to[packageName];
  }
}

/// Adds a native library to be built by the builder and dynamically link it to
/// the  main library.
Future<void> addDynamicallyLinkedNativeLibrary(
  String packageName,
  Directory packageDirectory,
) async {
  // Add linked library source files.
  final Directory srcDirectory = packageDirectory.childDirectory('src');
  final File linkedLibraryHeaderFile = srcDirectory.childFile('add.h');
  await linkedLibraryHeaderFile.writeAsString('''
#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT intptr_t add(intptr_t a, intptr_t b);
''');
  final File linkedLibrarySourceFile = srcDirectory.childFile('add.c');
  await linkedLibrarySourceFile.writeAsString('''
#include "add.h"

FFI_PLUGIN_EXPORT intptr_t add(intptr_t a, intptr_t b) {
  return a + b;
}
''');

  // Update main library to include call to linked library.
  final File mainLibrarySourceFile = srcDirectory.childFile('$packageName.c');
  String mainLibrarySource = await mainLibrarySourceFile.readAsString();
  mainLibrarySource = mainLibrarySource.replaceFirst('#include "$packageName.h"', '''
#include "$packageName.h"
#include "add.h"
''');
  mainLibrarySource = mainLibrarySource.replaceAll('a + b', 'add(a, b)');
  await mainLibrarySourceFile.writeAsString(mainLibrarySource);

  // Update builder to build the native library and link it into the main library.
  const builderSource = r'''

import 'package:logging/logging.dart';
import 'package:hooks/hooks.dart';
import 'package:code_assets/code_assets.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;

    if (!input.config.buildCodeAssets) {
      return;
    }
    final builders = [
      CBuilder.library(
        name: 'add',
        assetName: 'add',
        sources: ['src/add.c'],
      ),
      CBuilder.library(
        name: packageName,
        assetName: '${packageName}_bindings_generated.dart',
        sources: ['src/$packageName.c'],
        flags: input.dynamicLinkingFlags('add'),
      ),
    ];

    final logger = Logger('')
        ..level = Level.ALL
        ..onRecord.listen((record) => print(record.message));

    for (final builder in builders) {
      await builder.run(
        input: input,
        output: output,
        logger: logger,
      );
    }
  });
}

extension on BuildInput {
  List<String> dynamicLinkingFlags(String libraryName) => switch (config.code.targetOS) {
        OS.macOS || OS.iOS => [
            '-L${outputDirectory.toFilePath()}',
            '-l$libraryName',
          ],
        OS.linux || OS.android => [
            '-Wl,-rpath=\$ORIGIN/.',
            '-L${outputDirectory.toFilePath()}',
            '-l$libraryName',
          ],
        OS.windows => [
            outputDirectory.resolve('$libraryName.lib').toFilePath()
          ],
        _ => throw UnimplementedError('Unsupported OS: ${config.code.targetOS}'),
      };
}
''';

  final Directory hookDirectory = packageDirectory.childDirectory('hook');
  final File builderFile = hookDirectory.childFile('build.dart');
  await builderFile.writeAsString(builderSource);
}

Future<void> pinDependencies(File pubspecFile) async {
  expect(pubspecFile, exists);
  final String oldPubspec = await pubspecFile.readAsString();
  final String newPubspec = oldPubspec.replaceAll(RegExp(r':\s*\^'), ': ');
  expect(newPubspec, isNot(oldPubspec));
  await pubspecFile.writeAsString(newPubspec);
}

Future<void> inTempDir(Future<void> Function(Directory tempDirectory) fun) async {
  final Directory tempDirectory = fileSystem.directory(
    fileSystem.systemTempDirectory.createTempSync().resolveSymbolicLinksSync(),
  );
  try {
    await fun(tempDirectory);
  } finally {
    tryToDelete(tempDirectory);
  }
}

final String hostOs = platform.operatingSystem;

const packageName = 'package_with_native_assets';

const exampleAppName = '${packageName}_example';

/// For `flutter build` we can't easily test whether running the app works.
/// Check that we have the dylibs in the app.
void expectDylibIsBundledWithFrameworks(Directory appDirectory, String buildMode, String os) {
  final Directory frameworksFolder = appDirectory.childDirectory(
    'build/$os/framework/${buildMode.upperCaseFirst()}',
  );
  expect(frameworksFolder, exists);
  final Directory xcFrameworkDirectory = frameworksFolder.childDirectory(
    '$packageName.xcframework',
  );
  if (os == 'macos') {
    final File dylib = xcFrameworkDirectory
        .childDirectory('macos-arm64_x86_64')
        .childDirectory('$packageName.framework')
        .childFile(packageName);
    expect(dylib, exists);
    _expectBinaryContainsArchitectures(dylib, ['x86_64', 'arm64']);
  } else {
    assert(os == 'ios');
    final File deviceDylib = xcFrameworkDirectory
        .childDirectory('ios-arm64')
        .childDirectory('$packageName.framework')
        .childFile(packageName);
    expect(deviceDylib, exists);
    _expectBinaryContainsArchitectures(deviceDylib, ['arm64']);

    final File simulatorDylib = xcFrameworkDirectory
        .childDirectory('ios-arm64_x86_64-simulator')
        .childDirectory('$packageName.framework')
        .childFile(packageName);
    expect(simulatorDylib, exists);
    _expectBinaryContainsArchitectures(simulatorDylib, ['x86_64', 'arm64']);
  }

  _expectXCFrameworkCodesigned(xcFrameworkDirectory);
}

extension StringUpperCaseFirst on String {
  String upperCaseFirst() {
    return replaceFirst(this[0], this[0].toUpperCase());
  }
}

/// Runs 'lipo -info' on a binary and asserts that it contains the expected architectures.
void _expectBinaryContainsArchitectures(File binary, List<String> expectedArchs) {
  expect(binary, exists);
  final ProcessResult lipoResult = processManager.runSync(<String>['lipo', '-info', binary.path]);
  expect(
    lipoResult.exitCode,
    0,
    reason: 'lipo -info failed for ${binary.path}:\n${lipoResult.stderr}',
  );
  final lipoOutput = lipoResult.stdout.toString();
  for (final arch in expectedArchs) {
    expect(
      lipoOutput,
      contains(arch),
      reason:
          'Binary ${binary.path} does not contain expected architecture $arch.\nLipo output: $lipoOutput',
    );
  }
}

void _expectXCFrameworkCodesigned(Directory xcFramework) {
  expect(xcFramework, exists);
  final ProcessResult result = processManager.runSync(<String>[
    'codesign',
    '-dv',
    xcFramework.path,
  ]);
  if (!result.stderr.toString().contains('Signature=adhoc')) {
    throw Exception('XCFramework ${xcFramework.path} is not codesigned:\n${result.stderr}');
  }
}

/// Check that the native assets are built with the C Compiler that Flutter uses.
///
/// This inspects the build configuration to see if the C compiler was configured.
void expectCCompilerIsConfigured(Directory appDirectory) {
  final Directory nativeAssetsBuilderDir = appDirectory.childDirectory(
    '.dart_tool/hooks_runner/$packageName/',
  );
  for (final Directory subDir in nativeAssetsBuilderDir.listSync().whereType<Directory>()) {
    // We only want to look at build/link hook invocation directories. The
    // `/shared/*` directory allows the individual hooks to store data that is
    // reusable across different build/link configurations.
    if (subDir.path.endsWith('shared')) {
      continue;
    }

    final File inputFile = subDir.childFile('input.json');
    expect(inputFile, exists);
    final inputContents = json.decode(inputFile.readAsStringSync()) as Map<String, Object?>;
    final input = BuildInput(inputContents);
    final BuildConfig config = input.config;
    if (!config.buildCodeAssets) {
      continue;
    }
    expect(config.code.cCompiler?.compiler, isNot(isNull));
  }
}

/// For `flutter build` we can't easily test whether running the app works.
/// Check that we have the dylibs in the app.
void expectDylibIsBundledMacOS(Directory appDirectory, String buildMode) {
  final Directory productsDirectory = appDirectory.childDirectory(
    'build/$hostOs/Build/Products/${buildMode.upperCaseFirst()}/',
  );
  final Directory appBundle = productsDirectory.childDirectory('$exampleAppName.app');
  expect(appBundle, exists);
  final Directory frameworksFolder = appBundle.childDirectory('Contents/Frameworks');
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
  final Directory frameworkDir = frameworksFolder.childDirectory('$frameworkName.framework');
  final Directory versionsDir = frameworkDir.childDirectory('Versions');
  final Directory versionADir = versionsDir.childDirectory('A');
  final Directory resourcesDir = versionADir.childDirectory('Resources');
  expect(resourcesDir, exists);
  final File dylibFile = versionADir.childFile(frameworkName);
  expect(dylibFile, exists);
  final stripped = buildMode != 'debug';
  expectDylibIsStripped(dylibFile, stripped: stripped);
  if (stripped) {
    final Directory dsymDir = productsDirectory.childDirectory('$frameworkName.framework.dsym');
    expect(dsymDir, exists);
  }
  final Link currentLink = versionsDir.childLink('Current');
  expect(currentLink, exists);
  expect(currentLink.resolveSymbolicLinksSync(), versionADir.path);
  final Link resourcesLink = frameworkDir.childLink('Resources');
  expect(resourcesLink, exists);
  expect(resourcesLink.resolveSymbolicLinksSync(), resourcesDir.path);
  final Link dylibLink = frameworkDir.childLink(frameworkName);
  expect(dylibLink, exists);
  expect(dylibLink.resolveSymbolicLinksSync(), dylibFile.path);
  final String infoPlist = resourcesDir.childFile('Info.plist').readAsStringSync();
  expect(infoPlist, '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>package_with_native_assets</string>
	<key>CFBundleIdentifier</key>
	<string>io.flutter.flutter.native-assets.package-with-native-assets</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>package_with_native_assets</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>1.0</string>
</dict>
</plist>''');
}

/// Check whether a dylib is stripped with `otool`.
///
/// ```text
///       cmd LC_DYSYMTAB
///   cmdsize 80
/// ilocalsym 0
/// nlocalsym 0              0 or 1 means stripped
/// iextdefsym 0
/// nextdefsym 2
/// iundefsym 2
/// nundefsym 1
/// ```
///
/// ```text
///       cmd LC_DYSYMTAB
///   cmdsize 80
/// ilocalsym 0
/// nlocalsym 8              >0 means unstripped, note: unstripped can be 0!
/// iextdefsym 8
/// nextdefsym 2
/// ```
void expectDylibIsStripped(File dylib, {required bool stripped}) {
  final ProcessResult result = processManager.runSync(<String>['otool', '-l', dylib.path]);
  expect(result.exitCode, 0);
  final stdout = result.stdout.toString();

  // Find LC_DYSYMTAB section and check nlocalsym.
  final List<String> lines = stdout.split('\n');
  int? nlocalsym;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('LC_DYSYMTAB')) {
      const kMaxDsymtabSearchLines = 20;
      for (int j = i + 1; j < i + kMaxDsymtabSearchLines && j < lines.length; j++) {
        if (lines[j].contains('nlocalsym')) {
          final RegExpMatch? match = RegExp(r'nlocalsym\s+(\d+)').firstMatch(lines[j]);
          if (match != null) {
            nlocalsym = int.parse(match.group(1)!);
          }
          break;
        }
      }
      break;
    }
  }

  if (nlocalsym == null) {
    throw Exception('nlocalsym not found in LC_DYSYMTAB section of ${dylib.path}\n$stdout');
  }

  if (stripped) {
    expect(
      nlocalsym,
      lessThanOrEqualTo(1),
      reason: 'Expected stripped binary to have nlocalsym 0 in ${dylib.path}',
    );
  } else {
    // Unstripped can be 0 if compiled with a modern XCode, so nothing to check
    // here.
  }
}

/// Checks that dylibs are bundled.
///
/// Sample path: build/linux/x64/release/bundle/lib/libmy_package.so
void expectDylibIsBundledLinux(Directory appDirectory, String buildMode) {
  // Linux does not support cross compilation, so always only check current architecture.
  final String architecture = Architecture.current.name;
  final Directory appBundle = appDirectory
      .childDirectory('build')
      .childDirectory(hostOs)
      .childDirectory(architecture)
      .childDirectory(buildMode)
      .childDirectory('bundle');
  expect(appBundle, exists);
  final Directory dylibsFolder = appBundle.childDirectory('lib');
  expect(dylibsFolder, exists);
  final File dylib = dylibsFolder.childFile(OS.linux.dylibFileName(packageName));
  expect(dylib, exists);
}

/// Checks that dylibs are bundled.
///
/// Sample path: build\windows\x64\runner\Debug\my_package_example.exe
void expectDylibIsBundledWindows(Directory appDirectory, String buildMode) {
  // Linux does not support cross compilation, so always only check current architecture.
  final String architecture = Architecture.current.name;
  final Directory appBundle = appDirectory
      .childDirectory('build')
      .childDirectory(hostOs)
      .childDirectory(architecture)
      .childDirectory('runner')
      .childDirectory(buildMode.upperCaseFirst());
  expect(appBundle, exists);
  final File dylib = appBundle.childFile(OS.windows.dylibFileName(packageName));
  expect(dylib, exists);
}
