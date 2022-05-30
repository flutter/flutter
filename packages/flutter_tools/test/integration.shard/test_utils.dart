// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:process/process.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import 'test_driver.dart';

/// The [FileSystem] for the integration test environment.
const FileSystem fileSystem = LocalFileSystem();

/// The [Platform] for the integration test environment.
const Platform platform = LocalPlatform();

/// The [ProcessManager] for the integration test environment.
const ProcessManager processManager = LocalProcessManager();

/// Creates a temporary directory but resolves any symlinks to return the real
/// underlying path to avoid issues with breakpoints/hot reload.
/// https://github.com/flutter/flutter/pull/21741
Directory createResolvedTempDirectorySync(String prefix) {
  assert(prefix.endsWith('.'));
  final Directory tempDirectory = fileSystem.systemTempDirectory.createTempSync('flutter_$prefix');
  return fileSystem.directory(tempDirectory.resolveSymbolicLinksSync());
}

void writeFile(String path, String content, {bool writeFutureModifiedDate = false}) {
  final File file = fileSystem.file(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content, flush: true);
    // Some integration tests on Windows to not see this file as being modified
    // recently enough for the hot reload to pick this change up unless the
    // modified time is written in the future.
    if (writeFutureModifiedDate) {
      file.setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));
    }
}

void writeBytesFile(String path, List<int> content) {
  fileSystem.file(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(content);
}

void writePackages(String folder) {
  writeFile(fileSystem.path.join(folder, '.packages'), '''
test:${fileSystem.path.join(fileSystem.currentDirectory.path, 'lib')}/
''');
}

void writePubspec(String folder) {
  writeFile(fileSystem.path.join(folder, 'pubspec.yaml'), '''
name: test
dependencies:
  flutter:
    sdk: flutter
''');
}

Future<void> getPackages(String folder) async {
  final List<String> command = <String>[
    fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter'),
    'pub',
    'get',
  ];
  final ProcessResult result = await processManager.run(command, workingDirectory: folder);
  if (result.exitCode != 0) {
    throw Exception('flutter pub get failed: ${result.stderr}\n${result.stdout}');
  }
}

const String kLocalEngineEnvironment = 'FLUTTER_LOCAL_ENGINE';
const String kLocalEngineLocation = 'FLUTTER_LOCAL_ENGINE_SRC_PATH';

List<String> getLocalEngineArguments() {
  return <String>[
    if (platform.environment.containsKey(kLocalEngineEnvironment))
      '--local-engine=${platform.environment[kLocalEngineEnvironment]}',
    if (platform.environment.containsKey(kLocalEngineLocation))
      '--local-engine-src-path=${platform.environment[kLocalEngineLocation]}',
  ];
}

Future<void> pollForServiceExtensionValue<T>({
  required FlutterTestDriver testDriver,
  required String extension,
  required T continuePollingValue,
  required Matcher matches,
  String valueKey = 'value',
}) async {
  for (int i = 0; i < 10; i++) {
    final Response response = await testDriver.callServiceExtension(extension);
    if (response.json?[valueKey] as T == continuePollingValue) {
      await Future<void>.delayed(const Duration(seconds: 1));
    } else {
      expect(response.json?[valueKey] as T, matches);
      return;
    }
  }
  fail(
    "Did not find expected value for service extension '$extension'. All call"
    " attempts responded with '$continuePollingValue'.",
  );
}
