// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/convert.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  for (final String buildMode in <String>['Debug', 'Release']) {
    final String buildModeLower = buildMode.toLowerCase();
    test('flutter build macos --$buildModeLower builds a valid app', () async {
      final String workingDirectory = fileSystem.path.join(
        getFlutterRoot(),
        'dev',
        'integration_tests',
        'flutter_gallery',
      );
      final String flutterBin = fileSystem.path.join(
        getFlutterRoot(),
        'bin',
        'flutter',
      );

      await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'clean',
      ], workingDirectory: workingDirectory);

      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'macos',
        '--$buildModeLower',
      ], workingDirectory: workingDirectory);

      print(result.stdout);
      print(result.stderr);

      expect(result.exitCode, 0);

      final Directory outputApp = fileSystem.directory(fileSystem.path.join(
        workingDirectory,
        'build',
        'macos',
        'Build',
        'Products',
        buildMode,
        'flutter_gallery.app',
      ));

      final Directory outputAppFramework =
          fileSystem.directory(fileSystem.path.join(
        outputApp.path,
        'Contents',
        'Frameworks',
        'App.framework',
      ));

      expect(outputAppFramework.childFile('App'), exists);
      expect(outputAppFramework.childLink('Resources'), exists);

      final File vmSnapshot = fileSystem.file(fileSystem.path.join(
        outputApp.path,
        'Contents',
        'Frameworks',
        'App.framework',
        'Resources',
        'flutter_assets',
        'vm_snapshot_data',
      ));

      expect(vmSnapshot.existsSync(), buildMode == 'Debug');

      final File outputFlutterFrameworkBinary =
          fileSystem.file(fileSystem.path.join(
        outputApp.path,
        'Contents',
        'Frameworks',
        'FlutterMacOS.framework',
        'FlutterMacOS',
      ));
      expect(outputFlutterFrameworkBinary, exists);

      // Archiving should contain a bitcode blob, but not building.
      // This mimics Xcode behavior and present a developer from having to install a
      // 300+MB app.
      expect(
        await containsBitcode(outputFlutterFrameworkBinary.path),
        isFalse,
      );

      await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'clean',
      ], workingDirectory: workingDirectory);
    }, skip: !platform.isMacOS,
       timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}

Future<bool> containsBitcode(String pathToBinary) async {
  // See: https://stackoverflow.com/questions/32755775/how-to-check-a-static-library-is-built-contain-bitcode
  final ProcessResult result = await processManager.run(<String>[
    'otool',
    '-l',
    '-arch',
    'arm64',
    pathToBinary,
  ]);
  final String loadCommands = result.stdout as String;
  if (!loadCommands.contains('__LLVM')) {
    return false;
  }
  // Presence of the section may mean a bitcode marker was embedded (size=1), but there is no content.
  if (!loadCommands.contains('size 0x0000000000000001')) {
    return true;
  }
  // Check the false positives: size=1 wasn't referencing the __LLVM section.

  bool emptyBitcodeMarkerFound = false;
  //  Section
  //  sectname __bundle
  //  segname __LLVM
  //  addr 0x003c4000
  //  size 0x0042b633
  //  offset 3932160
  //  ...
  final List<String> lines = LineSplitter.split(loadCommands).toList();
  lines.asMap().forEach((int index, String line) {
    if (line.contains('segname __LLVM') && lines.length - index - 1 > 3) {
      final String emptyBitcodeMarker =
          lines.skip(index - 1).take(3).firstWhere(
                (String line) => line.contains(' size 0x0000000000000001'),
                orElse: () => null,
              );
      if (emptyBitcodeMarker != null) {
        emptyBitcodeMarkerFound = true;
        return;
      }
    }
  });
  return !emptyBitcodeMarkerFound;
}
