// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/src/arg_results.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze_base.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../../src/common.dart';

const String _kFlutterRoot = '/data/flutter';

void main() {
  testWithoutContext('analyze generate correct DartDoc message', () async {
    final MockAnalyze mockAnalyze = MockAnalyze.mock();

    expect(mockAnalyze.generateDartDocMessage(0), 'all public member have documentation');
    expect(mockAnalyze.generateDartDocMessage(1), 'one public member lacks documentation');
    expect(mockAnalyze.generateDartDocMessage(2), '2 public members lack documentation');
    expect(mockAnalyze.generateDartDocMessage(-1), 'unknown public member documentation');
  });

  testWithoutContext('analyze inRepo', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.directory(_kFlutterRoot).createSync(recursive: true);
    final Directory tempDir = fileSystem.systemTempDirectory
      .createTempSync('flutter_analysis_test.');
    Cache.flutterRoot = _kFlutterRoot;

    // Absolute paths
    expect(inRepo(<String>[tempDir.path], fileSystem), isFalse);
    expect(inRepo(<String>[fileSystem.path.join(tempDir.path, 'foo')], fileSystem), isFalse);
    expect(inRepo(<String>[Cache.flutterRoot], fileSystem), isTrue);
    expect(inRepo(<String>[fileSystem.path.join(Cache.flutterRoot, 'foo')], fileSystem), isTrue);

    // Relative paths
    fileSystem.currentDirectory = Cache.flutterRoot;
    expect(inRepo(<String>['.'], fileSystem), isTrue);
    expect(inRepo(<String>['foo'], fileSystem), isTrue);
    fileSystem.currentDirectory = tempDir.path;
    expect(inRepo(<String>['.'], fileSystem), isFalse);
    expect(inRepo(<String>['foo'], fileSystem), isFalse);

    // Ensure no exceptions
    inRepo(null, fileSystem);
    inRepo(<String>[], fileSystem);
  });
}

bool inRepo(List<String> fileList, FileSystem fileSystem) {
  if (fileList == null || fileList.isEmpty) {
    fileList = <String>[fileSystem.path.current];
  }
  final String root = fileSystem.path.normalize(fileSystem.path.absolute(Cache.flutterRoot));
  final String prefix = root + fileSystem.path.separator;
  for (String file in fileList) {
    file = fileSystem.path.normalize(fileSystem.path.absolute(file));
    if (file == root || file.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

class MockAnalyze extends AnalyzeBase {
  MockAnalyze(
    ArgResults argResults,
    List<String> repoRoots,
    List<Directory> repoPackages, {
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
    @required ProcessManager processManager,
    @required Terminal terminal,
    @required List<String> experiments,
    @required Artifacts artifacts,
  }) : super(
          argResults,
          repoRoots: repoRoots,
          repoPackages: repoPackages,
          fileSystem: fileSystem,
          logger: logger,
          platform: platform,
          processManager: processManager,
          terminal: terminal,
          experiments: experiments,
          artifacts: artifacts,
        );

  static MockAnalyze mock() {
    return MockAnalyze(
      null,
      null,
      null,
      fileSystem: null,
      logger: null,
      platform: null,
      processManager: null,
      terminal: null,
      experiments: null,
      artifacts: null,
    );
  }

  @override
  Future<void> analyze() async {}
}
