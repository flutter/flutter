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

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart' show ProcessResultMatcher, fileSystem, flutterBin, platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

final String hostOs = platform.operatingSystem;
const String packageName = 'data_asset_example';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }

  // Create project structure once as we can re-use this for executing the
  // various test modes.
  late final Directory tempDirectory;
  late final Directory root;
  setUpAll(() async {
    processManager.runSync(<String>[
      flutterBin,
      'config',
      '--enable-native-assets',
    ]);
    tempDirectory = fileSystem.directory(fileSystem.systemTempDirectory.createTempSync().resolveSymbolicLinksSync());
    root = await createDataAssetApp(packageName, tempDirectory);
  });
  tearDownAll(() {
    tryToDelete(tempDirectory);
  });

  group('dart data assets', () {
    // NOTE: flutter-tester doesn't support profile/release mode.
    // NOTE: flutter web doesn't allow cpaturing print()s in profile/release
    // nOTE: flutter web doens't allow adding assets on hot-restart
    final List<String> devices = <String>[hostOs, 'chrome', 'flutter-tester'];
    final List<String> modes  = <String>['debug', 'release'];

    for (final String mode in modes) {
      for (final String device in devices) {
        final bool isFlutterTester = device == 'flutter-tester';
        final bool isWeb = device == 'chrome';
        final bool isDebug = mode == 'debug';

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
          final bool performRestart = isDebug;
          final bool performReload = isDebug && !isWeb;

          final Map<String, String> assets = <String, String>{
            'id1' : 'content1',
            'id2' : 'content2'
          };
          writeHookLibrary(root, assets, available: <String>['id1']);
          writeHelperLibrary(root, 'version1', assets.keys.toList());

          final ProcessTestResult result = await runFlutter(
            <String>['run', '-v', '-d', device, '--$mode'],
            root.path,
            <Transition>[
              Barrier.contains('Launching lib/main.dart on'),
              Multiple.contains(<Pattern>[
                  // The flutter tool will print it's ready to accept keys (e.g.
                  // q=quit, ...)
                  // (This can be racy with app already running and printing)
                  if (isWeb) 'To hot restart changes while running'
                  else 'Flutter run key command',

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
                  writeHookLibrary(root, assets, available: <String>['id1', 'id2']);
                  writeHelperLibrary(root, 'version2', assets.keys.toList());
                  return 'R';
                },
              ),
              if (performRestart)
                Multiple.contains(<Pattern>[
                  // Once the app runs it will print whether it found assets.
                  // We expect it to having found the new `id2` now.
                  'VERSION: version2',
                  'FOUND "packages/data_asset_example/id1": "content1".',

                  // Flutter web doesn't support new assets on hot-restart atm
                  // -> See https://github.com/flutter/flutter/issues/159666
                  if (isWeb) 'NOT-FOUND "packages/data_asset_example/id2".'
                  else 'FOUND "packages/data_asset_example/id2": "content2".',
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
                  writeHookLibrary(root, assets, available: <String>['id1', 'id2', 'id3']);
                  writeHelperLibrary(root, 'version3', assets.keys.toList());
                  return 'r';
                }),
              if (performReload)
                Multiple.contains(<Pattern>[
                  // Once the app runs it will print whether it found assets.
                  'VERSION: version3',
                  'FOUND "packages/data_asset_example/id1": "content1".',
                  'FOUND "packages/data_asset_example/id2": "content2".',
                  'FOUND "packages/data_asset_example/id3": "content3".',
                  'NOT-FOUND "packages/data_asset_example/id4".',
                ],
                handler: (_) {
                  return 'q'; // quit
                }),
              Barrier.contains('Application finished.'),
            ],
            debug: true,
          );
          if (result.exitCode != 0) {
            throw Exception(
                'flutter run failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}');
          }
        });
      }
    }

    for (final String target in <String>[hostOs, 'web']) {
      testWithoutContext('flutter build $target', () async {
        final Map<String, String> assets = <String, String>{
          'id1' : 'content1',
          'id2' : 'content2'
        };
        final List<String> available = <String>['id1'];
        writeHookLibrary(root, assets, available: available);
        writeHelperLibrary(root, 'version1', assets.keys.toList());

        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', target ],
          root.path,
          <Transition>[
            Barrier.contains('Built build/$target'),
          ],
          debug: true,
        );
        if (result.exitCode != 0) {
          throw Exception(
              'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}');
        }
        final Directory buildTargetDir = root.childDirectory('build').childDirectory(target);

        final List<File> manifestFiles  = buildTargetDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('AssetManifest.json'))
            .toList();

        if (manifestFiles.isEmpty) {
          throw Exception('Expected a `AssetManifest.json` to be avilable in the $buildTargetDir.');
        }
        for (final File manifestFile in manifestFiles) {
          final Map<String, Object?> manifest = json.decode(manifestFile.readAsStringSync()) as Map<String, Object?>;
          for (final String id in available) {
            final String key = 'packages/$packageName/$id';
            final List<Object?> entry = manifest[key]! as List<Object?>;
            expect(entry, equals(<String>[key]));

            final File file = manifestFile.parent.childFile(key);
            expect(file.readAsStringSync(), assets[id]);
          }
        }
      });
    }
  });
}


Future<Directory> createDataAssetApp(String packageName, Directory tempDirectory) async {
  final ProcessResult result = processManager.runSync(
    <String>[flutterBin, 'create', '--no-pub', packageName],
    workingDirectory: tempDirectory.path,
  );
  expect(result, const ProcessResultMatcher());

  final Directory root = tempDirectory.childDirectory(packageName);
  final File pubspecFile = root.childFile('pubspec.yaml');
  await replaceFileSection(
    pubspecFile,
    'dependencies:\n',
    'dependencies:\n  native_assets_cli: ^0.9.0\n',
  );
  await pinDependencies(pubspecFile);

  final File mainFile = root.childDirectory('lib').childFile('main.dart');
  writeFile(
    mainFile,
    '''
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

  final ProcessResult result2 = await processManager.run(
    <String>[flutterBin, 'pub', 'get'],
    workingDirectory: root.path,
  );
  expect(result2, const ProcessResultMatcher());

  return root;
}

void writeHookLibrary(
    Directory root,
    Map<String, String> dataAssets,
    {required List<String> available}) {

  final Directory assetDir = root.childDirectory('asset');

  dataAssets.forEach((String id, String content) {
    writeFile(assetDir.childFile('$id.txt'), content);
  });

  final File hookFile = root.childDirectory('hook').childFile('build.dart');
  available = <String>[
    for (final String id in available) '"$id"',
  ];
  writeFile(hookFile, '''
      import 'package:native_assets_cli/data_assets.dart';

      void main(List<String> args) async {
        await build(args, (BuildConfig config, BuildOutputBuilder output) async {
          for (final id in $available) {
            output.dataAssets.add(
              DataAsset(
                package: '$packageName',
                name: '\$id',
                file: config.packageRoot.resolve('asset/\$id.txt'),
              ),
            );
          }

          // This is a workaround for an issue in the
          // `package:native_assets_builder` package:
          // -> See https://github.com/dart-lang/native/issues/1770
          output.addDependency(config.packageRoot.resolve('hook/build.dart'));
        });
      }
  ''');
}

void writeHelperLibrary(
    Directory root,
    String version,
    List<String> assetIds) {
  assetIds = <String>[
    for (final String id in assetIds) '"packages/$packageName/$id"',
  ];
  final File helperFile = root.childDirectory('lib').childFile('helper.dart');
  writeFile(
    helperFile,
  '''
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
          } catch (e, s) {
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

void writeFile(File file, String content) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

Future<void> replaceFileSection(File file, Pattern pattern, String replacement) async {
  final String content = await file.readAsString();
  await file.writeAsString(content.replaceFirst(pattern, replacement));
}
