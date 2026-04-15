// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../../src/common.dart';
import '../test_utils.dart' show platform;
import '../transition_test_utils.dart';
import 'dart_data_asset_utils.dart';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(setUpAllDataAssets);
  setUp(setUpDataAssets);
  tearDown(tearDownDataAssets);

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
  });
}
