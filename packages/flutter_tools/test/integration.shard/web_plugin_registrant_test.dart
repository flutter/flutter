// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
import '../src/test_flutter_command_runner.dart';

void main() {
  late Directory tempDir;
  late Directory projectDir;

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
    // We need a dependency so the plugin registrant is not completely empty.
    await _editPubspecFile(projectDir, _addDependencyEditor('shared_preferences',
        version: '^2.0.0'));
    // The plugin registrant is created on build...
    await _buildWebProject(projectDir);

    // Find the web_plugin_registrant, now that it lives outside "lib":
    final Directory buildDir = projectDir
        .childDirectory('.dart_tool/flutter_build')
        .listSync()
        .firstWhere((FileSystemEntity entity) => entity is Directory) as Directory;

    // Ensure the file exists, and passes analysis.
    final File registrant = buildDir.childFile('web_plugin_registrant.dart');
    expect(registrant, exists);
    await _analyzeEntity(registrant);

    // Ensure the contents match what we expect for a non-empty plugin registrant.
    final String contents = registrant.readAsStringSync();
    expect(contents, contains('// @dart = 2.13'));
    expect(contents, contains("import 'package:shared_preferences_web/shared_preferences_web.dart';"));
    expect(contents, contains('void registerPlugins([final Registrar? pluginRegistrar]) {'));
    expect(contents, contains('SharedPreferencesPlugin.registerWith(registrar);'));
    expect(contents, contains('registrar.registerMessageHandler();'));
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
          fileSystem: globals.fs,
          logger: globals.logger,
          processManager: globals.processManager,
          usage: globals.flutterUsage,
          botDetector: globals.botDetector,
          platform: globals.platform,
          stdio: globals.stdio,
        ),
  });

  testUsingContext('generated plugin registrant passes analysis without null safety', () async {
    await _createProject(projectDir, <String>[]);
    // We need a dependency so the plugin registrant is not completely empty.
    await _editPubspecFile(projectDir,
      _composeEditors(<PubspecEditor>[
        _addDependencyEditor('shared_preferences', version: '^2.0.0'),

        // This turns null safety off
        _setDartSDKVersionEditor('>=2.11.0 <3.0.0'),
      ]));

    // The generated main.dart file has a bunch of stuff that is invalid without null safety, so
    // replace it with a no-op dummy main file. We aren't testing it in this scenario anyway.
    await _replaceMainFile(projectDir, 'void main() {}');

    // The plugin registrant is created on build...
    await _buildWebProject(projectDir);

    // Find the web_plugin_registrant, now that it lives outside "lib":
    final Directory buildDir = projectDir
        .childDirectory('.dart_tool/flutter_build')
        .listSync()
        .firstWhere((FileSystemEntity entity) => entity is Directory) as Directory;

    // Ensure the file exists, and passes analysis.
    final File registrant = buildDir.childFile('web_plugin_registrant.dart');
    expect(registrant, exists);
    await _analyzeEntity(registrant);

    // Ensure the contents match what we expect for a non-empty plugin registrant.
    final String contents = registrant.readAsStringSync();
    expect(contents, contains('// @dart = 2.13'));
    expect(contents, contains("import 'package:shared_preferences_web/shared_preferences_web.dart';"));
    expect(contents, contains('void registerPlugins([final Registrar? pluginRegistrar]) {'));
    expect(contents, contains('SharedPreferencesPlugin.registerWith(registrar);'));
    expect(contents, contains('registrar.registerMessageHandler();'));
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
          fileSystem: globals.fs,
          logger: globals.logger,
          processManager: globals.processManager,
          usage: globals.flutterUsage,
          botDetector: globals.botDetector,
          platform: globals.platform,
          stdio: globals.stdio,
        ),
  });


  testUsingContext('(no-op) generated plugin registrant passes analysis', () async {
    await _createProject(projectDir, <String>[]);
    // No dependencies on web plugins this time!
    await _buildWebProject(projectDir);

    // Find the web_plugin_registrant, now that it lives outside "lib":
    final Directory buildDir = projectDir
        .childDirectory('.dart_tool/flutter_build')
        .listSync()
        .firstWhere((FileSystemEntity entity) => entity is Directory) as Directory;

    // Ensure the file exists, and passes analysis.
    final File registrant = buildDir.childFile('web_plugin_registrant.dart');
    expect(registrant, exists);
    await _analyzeEntity(registrant);

    // Ensure the contents match what we expect for an empty (noop) plugin registrant.
    final String contents = registrant.readAsStringSync();
    expect(contents, contains('void registerPlugins() {}'));
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
          fileSystem: globals.fs,
          logger: globals.logger,
          processManager: globals.processManager,
          usage: globals.flutterUsage,
          botDetector: globals.botDetector,
          platform: globals.platform,
          stdio: globals.stdio,
        ),
  });

  // See: https://github.com/dart-lang/dart-services/pull/874
  testUsingContext('generated plugin registrant for dartpad is created on pub get', () async {
    await _createProject(projectDir, <String>[]);
    await _editPubspecFile(projectDir,
      _addDependencyEditor('shared_preferences', version: '^2.0.0'));
    // The plugin registrant for dartpad is created on flutter pub get.
    await _doFlutterPubGet(projectDir);

    final File registrant = projectDir
        .childDirectory('.dart_tool/dartpad')
        .childFile('web_plugin_registrant.dart');

    // Ensure the file exists, and passes analysis.
    expect(registrant, exists);
    await _analyzeEntity(registrant);

    // Assert the full build hasn't happened!
    final Directory buildDir = projectDir.childDirectory('.dart_tool/flutter_build');
    expect(buildDir, isNot(exists));
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
          fileSystem: globals.fs,
          logger: globals.logger,
          processManager: globals.processManager,
          usage: globals.flutterUsage,
          botDetector: globals.botDetector,
          platform: globals.platform,
          stdio: globals.stdio,
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
    await _editPubspecFile(
      projectDir,
      _addDependencyEditor(
        'test_web_plugin_with_a_purposefully_extremely_long_package_name',
        path: '../test_plugin',
      )
    );
    // The plugin registrant is only created after a build...
    await _buildWebProject(projectDir);

    // Find the web_plugin_registrant, now that it lives outside "lib":
    final Directory buildDir = projectDir
        .childDirectory('.dart_tool/flutter_build')
        .listSync()
        .firstWhere((FileSystemEntity entity) => entity is Directory) as Directory;

    expect(
      buildDir.childFile('web_plugin_registrant.dart'),
      exists,
    );
    await _analyzeEntity(buildDir.childFile('web_plugin_registrant.dart'));
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
          fileSystem: globals.fs,
          logger: globals.logger,
          processManager: globals.processManager,
          usage: globals.flutterUsage,
          botDetector: globals.botDetector,
          platform: globals.platform,
          stdio: globals.stdio,
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
    '.dart_tool/package_config.json',
  ));

  final File snapshotFile = globals.fs.file(flutterToolsSnapshotPath);
  if (snapshotFile.existsSync()) {
    snapshotFile.renameSync('$flutterToolsSnapshotPath.bak');
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
  printOnFailure('Output of dart ${snapshotArgs.join(" ")}:');
  printOnFailure(snapshotResult.stdout.toString());
  printOnFailure(snapshotResult.stderr.toString());
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
      globals.fs.file('$flutterToolsSnapshotPath.bak');
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

typedef PubspecEditor = void Function(List<String> pubSpecContents);

Future<void> _editPubspecFile(
  Directory projectDir,
  PubspecEditor editor,
) async {
  final File pubspecYaml = projectDir.childFile('pubspec.yaml');
  expect(pubspecYaml, exists);

  final List<String> lines = await pubspecYaml.readAsLines();
  editor(lines);
  await pubspecYaml.writeAsString(lines.join('\n'));
}

Future<void> _replaceMainFile(Directory projectDir, String fileContents) async {
  final File mainFile = projectDir.childDirectory('lib').childFile('main.dart');
  await mainFile.writeAsString(fileContents);
}

PubspecEditor _addDependencyEditor(String packageToAdd, {String? version, String? path}) {
  assert(version != null || path != null,
      'Need to define a source for the package.');
  assert(version == null || path == null,
      'Cannot only load a package from path or from Pub, not both.');
  void editor(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (line.startsWith('dependencies:')) {
        lines.insert(
            i + 1,
            '  $packageToAdd: ${version ?? '\n'
                '   path: $path'}');
        break;
      }
    }
  }
  return editor;
}

PubspecEditor _setDartSDKVersionEditor(String version) {
  void editor(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (line.startsWith('environment:')) {
        for (i++; i < lines.length; i++) {
          final String innerLine = lines[i];
          final String sdkLine = "  sdk: '$version'";
          if(innerLine.isNotEmpty && !innerLine.startsWith('  ')) {
            lines.insert(i, sdkLine);
            break;
          }
          if(innerLine.startsWith('  sdk:')) {
            lines[i] = sdkLine;
            break;
          }
        }
        break;
      }
    }
  }
  return editor;
}

PubspecEditor _composeEditors(Iterable<PubspecEditor> editors) {
  void composedEditor(List<String> lines) {
    for (final PubspecEditor editor in editors) {
      editor(lines);
    }
  }
  return composedEditor;
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

Future<void> _analyzeEntity(FileSystemEntity target) async {
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
    target.path,
  ];

  final ProcessResult exec = await Process.run(
    globals.artifacts!.getHostArtifact(HostArtifact.engineDartBinary).path,
    args,
    workingDirectory: target is Directory ? target.path : target.dirname,
  );
  printOnFailure('Output of flutter analyze:');
  printOnFailure(exec.stdout.toString());
  printOnFailure(exec.stderr.toString());
  expect(exec.exitCode, 0);
}

Future<void> _buildWebProject(Directory workingDir) async {
  return _runFlutterSnapshot(<String>['build', 'web'], workingDir);
}

Future<void> _doFlutterPubGet(Directory workingDir) async {
  return _runFlutterSnapshot(<String>['pub', 'get'], workingDir);
}

// Runs a flutter command from a snapshot build.
// `flutterCommandArgs` are the arguments passed to flutter, like: ['build', 'web']
// to run `flutter build web`.
// `workingDir` is the directory on which the flutter command will be run.
Future<void> _runFlutterSnapshot(List<String> flutterCommandArgs, Directory workingDir) async {
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
    ...flutterCommandArgs
  ];

  final ProcessResult exec = await Process.run(
    globals.artifacts!.getHostArtifact(HostArtifact.engineDartBinary).path,
    args,
    workingDirectory: workingDir.path,
  );
  printOnFailure('Output of flutter ${flutterCommandArgs.join(" ")}:');
  printOnFailure(exec.stdout.toString());
  printOnFailure(exec.stderr.toString());
  expect(exec.exitCode, 0);
}
