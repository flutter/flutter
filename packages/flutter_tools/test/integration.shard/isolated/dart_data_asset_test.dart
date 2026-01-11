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
const packageName = 'data_asset_example';
const packageNameDependency = 'data_asset_dependency';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(() async {
    processManager.runSync(<String>[flutterBin, 'config', '--enable-native-assets']);
    processManager.runSync(<String>[flutterBin, 'config', '--enable-dart-data-assets']);
  });

  late Directory tempDirectory;
  late Directory root;
  late Directory rootDependency;

  setUp(() async {
    // Do not reuse project structure to be able to make local changes
    tempDirectory = fileSystem.directory(
      fileSystem.systemTempDirectory.createTempSync().resolveSymbolicLinksSync(),
    );
    root = createAppWithName(packageName, tempDirectory);
    await createDataAssetApp(packageName, root);

    rootDependency = createAppWithName(packageNameDependency, tempDirectory);
  });

  tearDown(() {
    tryToDelete(tempDirectory);
  });

  group('dart data assets', () {
    // NOTE: flutter-tester doesn't support profile/release mode.
    // NOTE: flutter web doesn't allow cpaturing print()s in profile/release
    // nOTE: flutter web doens't allow adding assets on hot-restart
    final devices = <String>[hostOs, 'chrome', 'flutter-tester'];
    final modes = <String>['debug', 'release'];

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

          final assets = <String, String>{'id1': 'content1', 'id2': 'content2'};
          writeAssets(assets, root);
          writeHookLibrary(root, assets, available: <String>['id1']);
          writeHelperLibrary(root, 'version1', assets.keys.toList());

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
            root.path,
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
                  'FOUND "packages/data_asset_example/id1": "content1".',
                  'NOT-FOUND "packages/data_asset_example/id2".',
                ],
                handler: (_) {
                  if (!performRestart) {
                    return 'q';
                  }
                  // Now we trigger a hot-restart with new assets & new
                  // application code, we make the build hook now emit also the
                  // `id2` data asset.
                  writeAssets(assets, root);
                  writeHookLibrary(root, assets, available: <String>['id1', 'id2']);
                  writeHelperLibrary(root, 'afterRestart', assets.keys.toList());
                  return 'R';
                },
              ),
              if (performRestart)
                Multiple.contains(
                  <Pattern>[
                    // Once the app runs it will print whether it found assets.
                    // We expect it to having found the new `id2` now.
                    'VERSION: afterRestart',
                    'FOUND "packages/data_asset_example/id1": "content1".',

                    // Flutter web doesn't support new assets on hot-restart atm
                    // -> See https://github.com/flutter/flutter/issues/137265
                    if (isWeb)
                      'NOT-FOUND "packages/data_asset_example/id2".'
                    else
                      'FOUND "packages/data_asset_example/id2": "content2".',
                    if (isWeb) 'Successful hot restart' else 'Hot restart performed',
                  ],
                  handler: (_) {
                    if (!performReload) {
                      return 'q';
                    }
                    // Now we trigger a hot-reload with new assets & new
                    // application code, we make the build hook now emit also the
                    // `id3` data asset (but not `id4`).
                    assets['id3'] = 'content3';
                    assets['id4'] = 'content4';
                    writeAssets(assets, root);
                    writeHookLibrary(root, assets, available: <String>['id1', 'id2', 'id3']);
                    writeHelperLibrary(root, 'afterReload', assets.keys.toList());
                    return 'r';
                  },
                ),
              if (performReload)
                Multiple.contains(
                  <Pattern>[
                    // Once the app runs it will print whether it found assets.
                    'VERSION: afterReload',
                    'FOUND "packages/data_asset_example/id1": "content1".',
                    // Flutter web doesn't support new assets on hot-reload atm
                    // -> See https://github.com/flutter/flutter/issues/137265
                    if (isWeb) ...<Pattern>[
                      'NOT-FOUND "packages/data_asset_example/id2".',
                      'NOT-FOUND "packages/data_asset_example/id3".',
                    ] else ...<Pattern>[
                      'FOUND "packages/data_asset_example/id2": "content2".',
                      'FOUND "packages/data_asset_example/id3": "content3".',
                    ],
                    'NOT-FOUND "packages/data_asset_example/id4".',
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
        final assets = <String, String>{'id1': 'content1', 'id2': 'content2'};
        final available = <String>['id1'];
        writeAssets(assets, root);
        writeHookLibrary(root, assets, available: available);
        writeHelperLibrary(root, 'version1', assets.keys.toList());

        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', target],
          root.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}$target')],
        );
        if (result.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }
        final Directory buildTargetDir = root.childDirectory('build').childDirectory(target);

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
            final key = 'packages/$packageName/$id';
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
        writeAssets(assets, root);
        writeAssets(assets, rootDependency);
        writeHookLibrary(root, assets, available: available);
        writeHookLibrary(rootDependency, assets, available: available);
        writeHelperLibrary(root, 'version1', assets.keys.toList());

        await modifyPubspec(root, (YamlEditor editor) {
          editor.update(
            <String>['dependencies', packageNameDependency],
            <String, String>{'path': '../$packageNameDependency'},
          );
        });

        await modifyPubspec(rootDependency, (YamlEditor editor) {
          editor
            ..update(<String>['flutter', 'assets'], <String>[assets.keys.first])
            ..update(<String>['dependencies'], <String, String>{'native_assets_cli': '^0.17.0'});
        });

        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', target],
          root.path,
          <Transition>[
            Barrier.contains(
              'Conflicting assets: The asset "asset: packages/data_asset_dependency/id1.txt" was declared in the pubspec and the hook',
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

Future<void> createDataAssetApp(String packageName, Directory root) async {
  await modifyPubspec(
    root,
    (YamlEditor editor) =>
        editor.update(<String>['dependencies'], <String, String>{'native_assets_cli': '^0.17.0'}),
  );

  final File pubspecFile = root.childFile('pubspec.yaml');
  await pinDependencies(pubspecFile);

  final File mainFile = root.childDirectory('lib').childFile('main.dart');
  writeFile(mainFile, '''
import 'dart:async';

import 'package:flutter/material.dart';

import 'helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool first = true;
    Timer.periodic(const Duration(seconds: 1), (_) async {
      // Delay to give the `flutter run` command time to connect and
      // setup `print()` capturing logic (especially on web it won't be
      // able to intercept prints until it has connected to DevTools).
      if (first) {
        await Future.delayed(const Duration(seconds: 5));
      }
      dumpAssets();
    });

    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: Text('Hello world'),
      ),
    );
  }
}
    ''');

  expect(
    await processManager.run(<String>[flutterBin, 'pub', 'get'], workingDirectory: root.path),
    const ProcessResultMatcher(),
  );
}

Directory createAppWithName(String packageName, Directory tempDirectory) {
  final ProcessResult result = processManager.runSync(<String>[
    flutterBin,
    'create',
    '--no-pub',
    packageName,
  ], workingDirectory: tempDirectory.path);
  expect(result, const ProcessResultMatcher());
  final Directory packageDirectory = tempDirectory.childDirectory(packageName);

  expect(
    processManager.runSync(<String>[
      flutterBin,
      'pub',
      'get',
    ], workingDirectory: packageDirectory.path),
    const ProcessResultMatcher(),
  );
  return packageDirectory;
}

void writeHookLibrary(
  Directory root,
  Map<String, String> dataAssets, {
  required List<String> available,
}) {
  final File hookFile = root.childDirectory('hook').childFile('build.dart');
  available = <String>[for (final String id in available) '"$id"'];
  writeFile(hookFile, '''
import 'package:native_assets_cli/data_assets.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    if (input.config.buildAssetTypes.contains('data_assets/data')) {
      for (final id in $available) {
        output.assets.data.add(
          DataAsset(
            package: input.packageName,
            name: id,
            file: input.packageRoot.resolve(id),
          ),
        );
      }
    }
  });
}
''');
}

void writeAssets(Map<String, String> dataAssets, Directory root) {
  dataAssets.forEach((String id, String content) {
    writeFile(root.childFile(id), content);
  });
}

void writeHelperLibrary(Directory root, String version, List<String> assetIds) {
  assetIds = <String>[for (final String id in assetIds) '"packages/$packageName/$id"'];
  final File helperFile = root.childDirectory('lib').childFile('helper.dart');
  writeFile(helperFile, '''
import 'package:flutter/services.dart' show rootBundle;

// Only run the code once, but after hot-restart & hot-reload we want to
// run it again.
bool $version = false;
void dumpAssets() async {
  if ($version) return;
  $version = true;

  final found = <String, String>{};
  final notFound = <String>[];
  for (final String assetId in $assetIds) {
    try {
      found[assetId] = await rootBundle.loadString(assetId);
    } catch (e) {
      print('EXCEPTION \$e');
      notFound.add(assetId);
    }
  }
  print('VERSION: $version');
  for (final MapEntry(:key, :value) in found.entries) {
    print('FOUND "\$key": "\$value".');
  }
  for (final id in notFound) {
    print('NOT-FOUND "\$id".');
  }
}
''');
}

void writeFile(File file, String content) => file
  ..createSync(recursive: true)
  ..writeAsStringSync(content);
