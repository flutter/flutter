// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';

import '../src/common.dart';
import '../src/darwin_common.dart';
import 'test_utils.dart';

void main() {
  for (final BuildMode buildMode in <BuildMode>[BuildMode.debug, BuildMode.release]) {
    group(buildMode.name, () {
      String flutterRoot;
      String projectRoot;
      String flutterBin;
      Directory tempDir;

      Directory buildPath;
      Directory outputApp;
      Directory outputFlutterFramework;
      File outputFlutterFrameworkBinary;
      Directory outputAppFramework;
      File outputAppFrameworkBinary;

      setUpAll(() {
        flutterRoot = getFlutterRoot();
        tempDir = createResolvedTempDirectorySync('ios_content_validation.');
        flutterBin = fileSystem.path.join(
          flutterRoot,
          'bin',
          'flutter',
        );

        processManager.runSync(<String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'create',
          '--platforms=ios',
          '-i',
          'objc',
          'hello',
        ], workingDirectory: tempDir.path);

        projectRoot = tempDir.childDirectory('hello').path;

        processManager.runSync(<String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--verbose',
          '--no-codesign',
          '--${buildMode.name}',
          '--obfuscate',
          '--split-debug-info=foo/',
        ], workingDirectory: projectRoot);

        buildPath = fileSystem.directory(fileSystem.path.join(
          projectRoot,
          'build',
          'ios',
          'iphoneos',
        ));

        outputApp = buildPath.childDirectory('Runner.app');

        outputFlutterFramework = fileSystem.directory(
          fileSystem.path.join(
            outputApp.path,
            'Frameworks',
            'Flutter.framework',
          ),
        );

        outputFlutterFrameworkBinary = outputFlutterFramework.childFile('Flutter');

        outputAppFramework = fileSystem.directory(fileSystem.path.join(
          outputApp.path,
          'Frameworks',
          'App.framework',
        ));

        outputAppFrameworkBinary = outputAppFramework.childFile('App');
      });

      tearDownAll(() {
        tryToDelete(tempDir);
      });

      testWithoutContext('flutter build ios builds a valid app', () {
        expect(outputAppFramework.childFile('App'), exists);

        final File vmSnapshot = fileSystem.file(fileSystem.path.join(
          outputAppFramework.path,
          'flutter_assets',
          'vm_snapshot_data',
        ));

        expect(vmSnapshot.existsSync(), buildMode == BuildMode.debug);

        expect(outputFlutterFramework.childDirectory('Headers'), isNot(exists));
        expect(outputFlutterFramework.childDirectory('Modules'), isNot(exists));

        // Archiving should contain a bitcode blob, but not building.
        // This mimics Xcode behavior and prevents a developer from having to install a
        // 300+MB app.
        expect(containsBitcode(outputFlutterFrameworkBinary.path, processManager), isFalse);
      });

      testWithoutContext('Info.plist dart observatory Bonjour service', () {
        final String infoPlistPath = fileSystem.path.join(
          outputApp.path,
          'Info.plist',
        );
        final ProcessResult bonjourServices = processManager.runSync(
          <String>[
            'plutil',
            '-extract',
            'NSBonjourServices',
            'xml1',
            '-o',
            '-',
            infoPlistPath,
          ],
        );
        final bool bonjourServicesFound = (bonjourServices.stdout as String).contains('_dartobservatory._tcp');
        expect(bonjourServicesFound, buildMode == BuildMode.debug);

        final ProcessResult localNetworkUsage = processManager.runSync(
          <String>[
            'plutil',
            '-extract',
            'NSLocalNetworkUsageDescription',
            'xml1',
            '-o',
            '-',
            infoPlistPath,
          ],
        );
        final bool localNetworkUsageFound = localNetworkUsage.exitCode == 0;
        expect(localNetworkUsageFound, buildMode == BuildMode.debug);
      });

      testWithoutContext('check symbols', () {
        final ProcessResult symbols = processManager.runSync(
          <String>[
            'nm',
            '-g',
            outputAppFrameworkBinary.path,
            '-arch',
            'arm64',
          ],
        );
        final bool aotSymbolsFound = (symbols.stdout as String).contains('_kDartVmSnapshot');
        expect(aotSymbolsFound, buildMode != BuildMode.debug);
      });

      testWithoutContext('xcode_backend embed_and_thin', () {
        outputFlutterFramework.deleteSync(recursive: true);
        outputAppFramework.deleteSync(recursive: true);
        expect(outputFlutterFrameworkBinary.existsSync(), isFalse);
        expect(outputAppFrameworkBinary.existsSync(), isFalse);

        final String xcodeBackendPath = fileSystem.path.join(
          flutterRoot,
          'packages',
          'flutter_tools',
          'bin',
          'xcode_backend.sh',
        );

        // Simulate a common Xcode build setting misconfiguration
        // where FLUTTER_APPLICATION_PATH is missing
        final ProcessResult xcodeBackendResult = processManager.runSync(
          <String>[
            xcodeBackendPath,
            'embed_and_thin',
          ],
          environment: <String, String>{
            'SOURCE_ROOT': fileSystem.path.join(projectRoot, 'ios'),
            'BUILT_PRODUCTS_DIR': fileSystem.path.join(
              projectRoot,
              'build',
              'ios',
              'Release-iphoneos',
            ),
            'TARGET_BUILD_DIR': buildPath.path,
            'FRAMEWORKS_FOLDER_PATH': 'Runner.app/Frameworks',
            'VERBOSE_SCRIPT_LOGGING': '1',
            'FLUTTER_BUILD_MODE': 'release',
            'ACTION': 'install',
            // Skip bitcode stripping since we just checked that above.
          },
        );

        expect(xcodeBackendResult.exitCode, 0);
        expect(outputFlutterFrameworkBinary.existsSync(), isTrue);
        expect(outputAppFrameworkBinary.existsSync(), isTrue);
      }, skip: !platform.isMacOS || buildMode != BuildMode.release);

      testWithoutContext('validate obfuscation', () {
        final ProcessResult grepResult = processManager.runSync(<String>[
          'grep',
          '-i',
          'hello',
          outputAppFrameworkBinary.path,
        ]);
        expect(grepResult.stdout, isNot(contains('matches')));
      });
    },
      skip: !platform.isMacOS,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
