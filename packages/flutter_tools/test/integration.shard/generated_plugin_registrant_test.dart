// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';

void main() {
  Directory tempDir;
  Directory projectDir;

  setUpAll(() async {
    Cache.disableLocking();
    await _ensureFlutterToolsSnapshot();
  });

  setUp(() {
    tempDir = globals.fs.systemTempDirectory
        .createTempSync('flutter_tools_generated_plugin_registrant_test.');
    projectDir = tempDir.childDirectory('flutter_project');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  tearDownAll(() async {
    await _restoreFlutterToolsSnapshot();
  });

  testUsingContext('generated plugin registrant passes analysis', () async {
    await _createProject(projectDir, <String>[]);
    // We need to add a dependency with web support to trigger
    // the generated_plugin_registrant generation.
    await _addDependency(projectDir, 'shared_preferences',
        version: '^0.5.12+4');
    await _analyzeProject(projectDir);

    expect(
      projectDir.childFile('lib/generated_plugin_registrant.dart'),
      exists,
    );
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
          fileSystem: globals.fs,
          logger: globals.logger,
          processManager: globals.processManager,
          usage: globals.flutterUsage,
          botDetector: globals.botDetector,
          platform: globals.platform,
        ),
  });

  testUsingContext(
      'generated plugin registrant ignores lines longer than 80 chars',
      () async {
    await _createProject(projectDir, <String>[]);
    await _addAnalysisOptions(
        projectDir, <String>['lines_longer_than_80_chars']);
    await _createProject(tempDir.childDirectory('test_plugin'), <String>[
      '--template=plugin',
      '--platforms=web',
      '--project-name',
      'test_web_plugin_with_a_purposefully_extremely_long_package_name',
    ]);
    // The line for the test web plugin (`  TestWebPluginWithAPurposefullyExtremelyLongPackageNameWeb.registerWith(registrar);`)
    // exceeds 80 chars.
    // With the above lint rule added, we want to ensure that the `generated_plugin_registrant.dart`
    // file does not fail analysis (this is a regression test - an ignore was
    // added to cover this case).
    await _addDependency(
      projectDir,
      'test_web_plugin_with_a_purposefully_extremely_long_package_name',
      path: '../test_plugin',
    );
    await _analyzeProject(projectDir);

    expect(
      projectDir.childFile('lib/generated_plugin_registrant.dart'),
      exists,
    );
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
          fileSystem: globals.fs,
          logger: globals.logger,
          processManager: globals.processManager,
          usage: globals.flutterUsage,
          botDetector: globals.botDetector,
          platform: globals.platform,
        ),
  });
}

Future<void> _ensureFlutterToolsSnapshot() async {
  final String flutterToolsPath = globals.fs.path.absolute(globals.fs.path.join(
    'bin',
    'flutter_tools.dart',
  ));
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(
    globals.fs.path.join(
      '..',
      '..',
      'bin',
      'cache',
      'flutter_tools.snapshot',
    ),
  );
  final String dotPackages = globals.fs.path.absolute(globals.fs.path.join(
    '.packages',
  ));

  final File snapshotFile = globals.fs.file(flutterToolsSnapshotPath);
  if (snapshotFile.existsSync()) {
    snapshotFile.renameSync(flutterToolsSnapshotPath + '.bak');
  }

  final List<String> snapshotArgs = <String>[
    '--snapshot=$flutterToolsSnapshotPath',
    '--packages=$dotPackages',
    flutterToolsPath,
  ];
  final ProcessResult snapshotResult = await Process.run(
    '../../bin/cache/dart-sdk/bin/dart',
    snapshotArgs,
  );
  if (snapshotResult.exitCode != 0) {
    print(snapshotResult.stdout);
    print(snapshotResult.stderr);
  }
  expect(snapshotResult.exitCode, 0);
}

Future<void> _restoreFlutterToolsSnapshot() async {
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(
    globals.fs.path.join(
      '..',
      '..',
      'bin',
      'cache',
      'flutter_tools.snapshot',
    ),
  );

  final File snapshotBackup =
      globals.fs.file(flutterToolsSnapshotPath + '.bak');
  if (!snapshotBackup.existsSync()) {
    // No backup to restore.
    return;
  }

  snapshotBackup.renameSync(flutterToolsSnapshotPath);
}

Future<void> _createProject(Directory dir, List<String> createArgs) async {
  Cache.flutterRoot = '../..';
  final CreateCommand command = CreateCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'create',
    ...createArgs,
    dir.path,
  ]);
}

Future<void> _addDependency(
  Directory projectDir,
  String package, {
  String version,
  String path,
}) async {
  assert(version != null || path != null,
      'Need to define a source for the package.');
  assert(version == null || path == null,
      'Cannot only load a package from path or from Pub, not both.');

  final File pubspecYaml = projectDir.childFile('pubspec.yaml');
  expect(pubspecYaml, exists);

  final List<String> lines = await pubspecYaml.readAsLines();
  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];
    if (line.startsWith('dependencies:')) {
      lines.insert(
          i + 1,
          '  $package: ${version ?? '\n'
              '    path: $path'}');
      break;
    }
  }
  await pubspecYaml.writeAsString(lines.join('\n'));
}

Future<void> _addAnalysisOptions(
    Directory projectDir, List<String> linterRules) async {
  assert(linterRules.isNotEmpty);

  await projectDir.childFile('analysis_options.yaml').writeAsString('''
linter:
  rules:
${linterRules.map((String rule) => '    - $rule').join('\n')}
  ''');
}

Future<void> _analyzeProject(Directory workingDir) async {
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(
    globals.fs.path.join(
      '..',
      '..',
      'bin',
      'cache',
      'flutter_tools.snapshot',
    ),
  );

  final List<String> args = <String>[
    flutterToolsSnapshotPath,
    'analyze',
  ];

  final ProcessResult exec = await Process.run(
    globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
    args,
    workingDirectory: workingDir.path,
  );
  if (exec.exitCode != 0) {
    print(exec.stdout);
    print(exec.stderr);
  }
  expect(exec.exitCode, 0);
}
