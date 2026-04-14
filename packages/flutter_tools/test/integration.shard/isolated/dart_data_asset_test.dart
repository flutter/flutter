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

import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:standard_message_codec/standard_message_codec.dart' show StandardMessageCodec;
import 'package:yaml_edit/yaml_edit.dart' show YamlEditor;

import '../../src/common.dart';
import '../test_utils.dart' show ProcessResultMatcher, fileSystem, flutterBin, platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

final String hostOs = platform.operatingSystem;
const packageName = 'data_asset_app';
const packageNameDependency = 'data_asset_package';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(() async {
    processManager.runSync(<String>[flutterBin, 'config', '--enable-native-assets']);
    processManager.runSync(<String>[flutterBin, 'config', '--enable-dart-data-assets']);
  });

  late Directory tempDirectory;
  late Directory appRoot;
  late Directory dependencyRoot;

  setUp(() async {
    // Do not reuse project structure to be able to make local changes
    tempDirectory = fileSystem.directory(
      fileSystem.systemTempDirectory.createTempSync().resolveSymbolicLinksSync(),
    );
    final Directory integrationTestsDir = tempDirectory
        .childDirectory('dev')
        .childDirectory('integration_tests');

    appRoot = integrationTestsDir.childDirectory(packageName);
    appRoot.createSync(recursive: true);
    copyTestProject(packageName, appRoot);
    await pinDependencies(appRoot.childFile('pubspec.yaml'));

    dependencyRoot = integrationTestsDir.childDirectory(packageNameDependency);
    dependencyRoot.createSync(recursive: true);
    copyTestProject(packageNameDependency, dependencyRoot);
    await pinDependencies(dependencyRoot.childFile('pubspec.yaml'));

    expect(
      await processManager.run(<String>[
        flutterBin,
        'pub',
        'get',
      ], workingDirectory: dependencyRoot.path),
      const ProcessResultMatcher(),
    );
    expect(
      await processManager.run(<String>[flutterBin, 'pub', 'get'], workingDirectory: appRoot.path),
      const ProcessResultMatcher(),
    );
  });

  tearDown(() {
    tryToDelete(tempDirectory);
  });

  group('dart data assets', () {
    // NOTE: flutter-tester doesn't support profile/release mode.
    // NOTE: flutter web doesn't allow cpaturing print()s in profile/release
    // NOTE: flutter web doesn't allow adding assets on hot-restart
    final devices = <String>[hostOs, 'chrome', 'flutter-tester'];
    final modes = <String>['debug', 'release'];

    // NOTE: devFS doesn't see the Dart file updates on Windows in the temp
    // directory in some cases. https://github.com/flutter/flutter/issues/184505
    final bool checkDartCodeUpdates = !platform.isWindows;

    for (final mode in modes) {
      for (final device in devices) {
        final isFlutterTester = device == 'flutter-tester';
        final isWeb = device == 'chrome';
        final isDebug = mode == 'debug';

        // This test relies on running the flutter app and capturing `print()`s
        // the app prints to determine if the test succeeded.
        // `flutter run --profile/release` on the web doesn't support capturing
        // prints
        // -> See https://github.com/flutter/flutter/issues/159668
        if (isWeb && !isDebug) {
          continue;
        }

        // Flutter tester only supports debug mode.
        if (isFlutterTester && !isDebug) {
          continue;
        }

        testWithoutContext('flutter run on $device --$mode', () async {
          final performRestart = isDebug;
          final performReload = isDebug;

          final assets = <String, String>{'id1.txt': 'content1', 'id2.txt': 'content2'};
          final available = <String>['id1.txt'];
          writeAssets(assets, appRoot);
          writeHookLibrary(appRoot, assets, available: available);
          writeHelperLibrary(appRoot, 'version1', assets.keys.toList());

          final ProcessTestResult result = await runFlutter(
            <String>[
              'run',
              '-v',
              '-d',
              device,
              '--$mode',
              if (device == 'chrome') ...[
                '--no-web-resources-cdn',
                '--web-browser-flag=--no-sandbox',
              ],
            ],
            appRoot.path,
            <Transition>[
              Barrier.contains('Launching lib${Platform.pathSeparator}main.dart on'),
              Multiple.contains(
                <Pattern>[
                  // The flutter tool will print it's ready to accept keys (e.g.
                  // q=quit, ...)
                  // (This can be racy with app already running and printing)
                  'Flutter run key command',

                  // Once the app runs it will print whether it found assets.
                  'VERSION: version1',
                  'FOUND "packages/data_asset_app/data/id1.txt": "content1".',
                  'NOT_FOUND "packages/data_asset_app/data/id2.txt".',
                  'DEPENDENCY_ASSET: package_content1',
                ],
                handler: (_) {
                  if (!performRestart) {
                    return 'q';
                  }
                  // Now we trigger a hot-restart with new assets & new
                  // application code, we make the build hook now emit also the
                  // `id2.txt` data asset.
                  writeAssets(assets, appRoot);
                  writeHookLibrary(appRoot, assets, available: <String>['id1.txt', 'id2.txt']);
                  writeHelperLibrary(appRoot, 'afterRestart', assets.keys.toList());
                  return 'R';
                },
              ),
              if (performRestart)
                Multiple.contains(
                  <Pattern>[
                    // Once the app runs it will print whether it found assets.
                    // We expect it to having found the new `id2.txt` now.
                    if (checkDartCodeUpdates) ...['VERSION: afterRestart'],
                    'FOUND "packages/data_asset_app/data/id1.txt": "content1".',

                    // Flutter web doesn't support new assets on hot-restart atm
                    // -> See https://github.com/flutter/flutter/issues/137265
                    if (isWeb)
                      'NOT_FOUND "packages/data_asset_app/data/id2.txt".'
                    else
                      'FOUND "packages/data_asset_app/data/id2.txt": "content2".',
                    'DEPENDENCY_ASSET: package_content1',
                    if (isWeb) 'Successful hot restart' else 'Hot restart performed',
                  ],
                  handler: (_) {
                    if (!performReload) {
                      return 'q';
                    }
                    // Now we trigger a hot-reload with new assets & new
                    // application code, we make the build hook now emit also the
                    // `id3.txt` data asset (but not `id4.txt`).
                    assets['id3.txt'] = 'content3';
                    assets['id4.txt'] = 'content4';
                    writeAssets(assets, appRoot);
                    writeHookLibrary(
                      appRoot,
                      assets,
                      available: <String>['id1.txt', 'id2.txt', 'id3.txt'],
                    );
                    writeHelperLibrary(appRoot, 'afterReload', assets.keys.toList());
                    return 'r';
                  },
                ),
              if (performReload)
                Multiple.contains(
                  <Pattern>[
                    // Once the app runs it will print whether it found assets.
                    if (checkDartCodeUpdates) ...['VERSION: afterReload'],
                    'FOUND "packages/data_asset_app/data/id1.txt": "content1".',
                    // Flutter web doesn't support new assets on hot-reload atm
                    // -> See https://github.com/flutter/flutter/issues/137265
                    if (isWeb) ...<Pattern>[
                      'NOT_FOUND "packages/data_asset_app/data/id2.txt".',
                      'NOT_FOUND "packages/data_asset_app/data/id3.txt".',
                    ] else ...<Pattern>[
                      'FOUND "packages/data_asset_app/data/id2.txt": "content2".',
                      'FOUND "packages/data_asset_app/data/id3.txt": "content3".',
                    ],
                    'NOT_FOUND "packages/data_asset_app/data/id4.txt".',
                    'DEPENDENCY_ASSET: package_content1',
                    if (isWeb) 'Successful hot reload' else 'Hot reload performed',
                  ],
                  handler: (_) {
                    return 'q'; // quit
                  },
                ),
              Barrier.contains('Application finished.'),
            ],
          );
          if (result.exitCode != 0) {
            throw Exception(
              'flutter run failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
            );
          }
        });
      }
    }

    for (final target in <String>[hostOs, 'web']) {
      testWithoutContext('flutter build $target', () async {
        final assets = <String, String>{'id1.txt': 'content1', 'id2.txt': 'content2'};
        final available = <String>['id1.txt'];
        writeAssets(assets, appRoot);
        writeHookLibrary(appRoot, assets, available: <String>['id1.txt']);
        writeHelperLibrary(appRoot, 'version1', assets.keys.toList());

        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', target],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}$target')],
        );
        if (result.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }
        final Directory buildTargetDir = appRoot.childDirectory('build').childDirectory(target);

        final List<File> manifestFiles = buildTargetDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('AssetManifest.bin'))
            .toList();

        if (manifestFiles.isEmpty) {
          throw Exception('Expected a `AssetManifest.bin` to be avilable in the $buildTargetDir.');
        }
        for (final manifestFile in manifestFiles) {
          final Uint8List manifestData = manifestFile.readAsBytesSync();
          final manifest =
              const StandardMessageCodec().decodeMessage(ByteData.sublistView(manifestData))
                  as Map<Object?, Object?>;
          for (final id in available) {
            final key = 'packages/$packageName/data/$id';
            final entry = manifest[key]! as List<Object?>;
            expect(
              entry,
              equals([
                {'asset': key},
              ]),
            );

            final File file = manifestFile.parent.childFile(key);
            expect(file.readAsStringSync(), assets[id]);
          }
        }
      });
    }

    for (final target in <String>[hostOs, 'web']) {
      testWithoutContext('flutter build $target with conflicting assets', () async {
        final assets = <String, String>{'id1.txt': 'content1', 'id2.txt': 'content2'};
        final available = <String>['id1.txt'];
        writeAssets(assets, appRoot, subdir: '');
        writeAssets(assets, dependencyRoot, subdir: '');
        writeHookLibrary(appRoot, assets, available: available, namePrefix: '', filePrefix: '');
        writeHookLibrary(
          dependencyRoot,
          assets,
          available: available,
          namePrefix: '',
          filePrefix: '',
        );
        writeHelperLibrary(appRoot, 'version1', assets.keys.toList());

        await modifyPubspec(appRoot, (YamlEditor editor) {
          editor.update(
            <String>['dependencies', packageNameDependency],
            <String, String>{'path': '../$packageNameDependency'},
          );
        });

        await modifyPubspec(dependencyRoot, (YamlEditor editor) {
          editor
            ..update(<String>['flutter', 'assets'], <String>[assets.keys.first])
            ..update(
              <String>['dependencies'],
              <String, String>{'hooks': '^1.0.2', 'data_assets': '^0.19.6'},
            );
        });

        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', target],
          appRoot.path,
          <Transition>[
            Barrier.contains(
              'Conflicting assets: The asset "asset: packages/data_asset_package/id1.txt" was declared in the pubspec and the hook',
            ),
          ],
        );
        expect(result.exitCode, isNonZero);
      });
    }
  });
}

Future<void> modifyPubspec(Directory dir, void Function(YamlEditor editor) modify) async {
  final File pubspecFile = dir.childFile('pubspec.yaml');
  final String content = await pubspecFile.readAsString();
  final yamlEditor = YamlEditor(content);
  modify(yamlEditor);
  pubspecFile.writeAsStringSync(yamlEditor.toString());
}

void copyTestProject(String sourceName, Directory targetDirectory) {
  final Directory flutterRoot = fileSystem.directory(getFlutterRoot());
  final Directory sourceDirectory = flutterRoot
      .childDirectory('dev')
      .childDirectory('integration_tests')
      .childDirectory(sourceName);

  if (!sourceDirectory.existsSync()) {
    throw Exception('Source directory ${sourceDirectory.path} does not exist.');
  }

  for (final FileSystemEntity entity in sourceDirectory.listSync(recursive: true)) {
    final String relativePath = fileSystem.path.relative(entity.path, from: sourceDirectory.path);
    if (entity is Directory) {
      targetDirectory.childDirectory(relativePath).createSync(recursive: true);
    } else if (entity is File) {
      final File targetFile = targetDirectory.childFile(relativePath);
      targetFile.parent.createSync(recursive: true);
      entity.copySync(targetFile.path);
      if (relativePath == 'pubspec.yaml') {
        String content = targetFile.readAsStringSync();
        content = content.replaceFirst('resolution: workspace', '');
        targetFile.writeAsStringSync(content);
      }
    }
  }
}

void writeHookLibrary(
  Directory root,
  Map<String, String> dataAssets, {
  required List<String> available,
  String namePrefix = 'data/',
  String filePrefix = 'data/',
}) {
  final File hookFile = root.childDirectory('hook').childFile('build.dart');
  final String content = hookFile.readAsStringSync();
  final assetList = "<String>[${available.map((String id) => "'$id'").join(', ')}]";
  String newContent = content.replaceFirst(
    RegExp(r'final assets = <String>\[[^\]]*\]; // @assets'),
    'final assets = $assetList; // @assets',
  );
  newContent = newContent.replaceFirst(RegExp(r"name: '.*\$id'"), "name: '$namePrefix\$id'");
  newContent = newContent.replaceFirst(
    RegExp(r"file: input.packageRoot.resolve\('.*\$id'\)"),
    "file: input.packageRoot.resolve('$filePrefix\$id')",
  );
  writeFile(hookFile, newContent);

  for (final MapEntry(:key, :value) in dataAssets.entries) {
    writeFile(root.childDirectory('data').childFile(key), value);
  }
}

void writeAssets(Map<String, String> dataAssets, Directory root, {String subdir = 'data'}) {
  final Directory targetDir = subdir.isEmpty ? root : root.childDirectory(subdir);
  if (targetDir.existsSync() && subdir.isNotEmpty) {
    targetDir.deleteSync(recursive: true);
  }
  targetDir.createSync(recursive: true);
  dataAssets.forEach((String id, String content) {
    writeFile(targetDir.childFile(id), content);
  });
}

void writeHelperLibrary(Directory root, String version, List<String> assetIds) {
  final File helperFile = root.childDirectory('lib').childFile('helper.dart');
  final String content = helperFile.readAsStringSync();
  final assetList =
      "<String>[${assetIds.map((String id) => "'packages/$packageName/data/$id'").join(', ')}]";
  String newContent = content.replaceFirst(
    RegExp(r"const version = '\w+'; // @version"),
    "const version = '$version'; // @version",
  );
  newContent = newContent.replaceFirst(
    RegExp(r'final assets = <String>\[[^\]]*\]; // @assets'),
    'final assets = $assetList; // @assets',
  );
  helperFile.writeAsStringSync(newContent);
}

void writeFile(File file, String content) => file
  ..createSync(recursive: true)
  ..writeAsStringSync(content);
