// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'package:yaml/yaml.dart';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/add_platform.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

const String frameworkRevision = '12345678';
const String frameworkChannel = 'omega';
// TODO(fujino): replace FakePlatform.fromPlatform() with FakePlatform()
final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};
const String samplesIndexJson = '''
[
  { "id": "sample1" },
  { "id": "sample2" }
]''';

void main() {
  Directory tempDir;
  Directory projectDir;

  setUpAll(() async {
    Cache.disableLocking();
    await _ensureFlutterToolsSnapshot();
  });

  setUp(() {
    tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_add_platform_test.');
    projectDir = tempDir.childDirectory('flutter_project');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  tearDownAll(() async {
    await _restoreFlutterToolsSnapshot();
  });

  testUsingContext('can create a default plugin, add macos platform', () async {
    await _createProject(projectDir, <String>['-t', 'plugin'], const <String>[]);
    await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'macos'],
      <String>[
        'macos/Classes/FlutterProjectPlugin.swift',
        'macos/flutter_project.podspec',
        'example/macos/Runner/AppDelegate.swift',
        'example/macos/Runner/MainFlutterWindow.swift',
      ],
    );
    _validatePubspecForPlugin(projectDir.absolute.path, 'macos', 'FlutterProjectPlugin', null);
    return _runFlutterTest(projectDir);
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

  testUsingContext('can add linux platform', () async {
    await _createProject(projectDir, <String>['-t', 'plugin'], const <String>[]);
    await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'linux'],
      <String>[
        'linux/flutter_project_plugin.cc',
        'linux/include/flutter_project_plugin.h',
        'example/linux/main.cc',
      ],
    );
    _validatePubspecForPlugin(projectDir.absolute.path, 'linux', 'FlutterProjectPlugin', null);
    return _runFlutterTest(projectDir);
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

  testUsingContext('can add windows platform', () async {
    await _createProject(projectDir, <String>['-t', 'plugin'], const <String>[]);
    await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'windows'],
      <String>[
        'windows/flutter_project_plugin.cpp',
        'windows/flutter_project_plugin.h',
        'example/windows/Runner/main.cpp',
      ],
    );
    _validatePubspecForPlugin(projectDir.absolute.path, 'windows', 'FlutterProjectPlugin', null);
    return _runFlutterTest(projectDir);
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

  testUsingContext('can add multiple platforms, windows + linux', () async {
    await _createProject(projectDir, <String>['-t', 'plugin'], const <String>[]);
    await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'linux,windows'],
      <String>[
        'windows/flutter_project_plugin.cpp',
        'windows/flutter_project_plugin.h',
        'example/windows/Runner/main.cpp',
        'linux/flutter_project_plugin.cc',
        'linux/include/flutter_project_plugin.h',
        'example/linux/main.cc',
      ],
    );
    _validatePubspecForPlugin(projectDir.absolute.path, 'windows', 'FlutterProjectPlugin', null);
    _validatePubspecForPlugin(projectDir.absolute.path, 'linux', 'FlutterProjectPlugin', null);
    return _runFlutterTest(projectDir);
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

  testUsingContext('execute add-platform in an empty directory throws error', () async {
    expect(() async => await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'linux,windows'],
      <String>[],
        unexpectedPaths: <String>[
          'linux/',
          'windows/',
      ]),
    throwsToolExit(exitCode:2, message: 'The target directory is not a flutter plugin directory'));
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

  testUsingContext('execute add-platform in an module directory throws error', () async {
    await _createProject(projectDir, <String>['-t', 'module'], const <String>[]);
    expect(() async => await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'linux,windows'],
      <String>[],
        unexpectedPaths: <String>[
          'linux/',
          'windows/',
      ]),
    throwsToolExit(exitCode:2, message: 'The target directory is not a flutter plugin directory'));
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

  testUsingContext('execute add-platform in an app directory throws error', () async {
    await _createProject(projectDir, <String>['-t', 'app'], const <String>[]);
    expect(() async => await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'linux,windows'],
      <String>[],
        unexpectedPaths: <String>[
          'linux/',
          'windows/',
      ]),
    throwsToolExit(exitCode:2, message: 'The target directory is not a flutter plugin directory'));
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

  testUsingContext('execute add-platform in a package directory throws error', () async {
    await _createProject(projectDir, <String>['-t', 'package'], const <String>[]);
    expect(() async => await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'linux,windows'],
      <String>[],
        unexpectedPaths: <String>[
          'linux/',
          'windows/',
      ]),
    throwsToolExit(exitCode:2, message: 'The target directory is not a flutter plugin directory'));
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

  testUsingContext('execute add-platform without --platform flag throws an error', () async {
    await _createProject(projectDir, <String>['-t', 'plugin'], const <String>[]);
    expect(() async => await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>[],
      <String>[]),
    throwsToolExit(exitCode:2, message: 'Must specify at least one platform using --platforms'));
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

  testUsingContext('fails to add platforms without specified org when org is ambiguous', () async {
    await _createProject(projectDir, <String>['-t', 'plugin', '--org', 'foo.bar'], const <String>[]);
    globals.fs.directory(globals.fs.path.join(projectDir.path, 'example/ios')).deleteSync(recursive: true);
    await _createProject(projectDir, <String>['-t', 'plugin', '--org', 'foo.bar.zz'], const <String>[]);
    expect(() async => await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'macos'],
      <String>[]),
    throwsToolExit(message: 'Ambiguous organization'));
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

  testUsingContext('Ok to add platforms without customize org when the plugin was created with a specified org', () async {
    await _createProject(projectDir, <String>['-t', 'plugin','--org', 'foo.bar'], const <String>[]);
    await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'macos'],
      <String>[]);
    return _runFlutterTest(projectDir);
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

  testUsingContext('add platform does not override pubspec.yaml', () async {
    await _createProject(projectDir, <String>['-t', 'plugin'], const <String>[]);
    final String pubspecPath = globals.fs.path.join(projectDir.absolute.path, 'pubspec.yaml');
    final YamlMap pubspec = loadYaml(globals.fs.file(pubspecPath).readAsStringSync()) as YamlMap;
    final String description = pubspec['description'] as String;
    final String name = pubspec['name'] as String;
    await _addPlatformAndAnalyzeProject(
      projectDir,
      <String>['--platform', 'macos'],
      <String>[],
    );
    final YamlMap newPubspec = loadYaml(globals.fs.file(pubspecPath).readAsStringSync()) as YamlMap;
    final String newDescription = newPubspec['description'] as String;
    final String newName = newPubspec['name'] as String;

    expect(name, newName);
    expect(description, newDescription);

    return _runFlutterTest(projectDir);
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

Future<void> _createProject(
  Directory dir,
  List<String> createArgs,
  List<String> expectedPaths, {
  List<String> unexpectedPaths = const <String>[],
}) async {
  Cache.flutterRoot = '../../..';
  final CreateCommand command = CreateCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'create',
    ...createArgs,
    dir.path,
  ]);

  bool pathExists(String path) {
    final String fullPath = globals.fs.path.join(dir.path, path);
    return globals.fs.typeSync(fullPath) != FileSystemEntityType.notFound;
  }

  final List<String> failures = <String>[
    for (final String path in expectedPaths)
      if (!pathExists(path))
        'Path "$path" does not exist.',
    for (final String path in unexpectedPaths)
      if (pathExists(path))
        'Path "$path" exists when it shouldn\'t.',
  ];
  expect(failures, isEmpty, reason: failures.join('\n'));
}

Future<void> _addPlatform(
  Directory dir,
  List<String> createArgs,
  List<String> expectedPaths, {
  List<String> unexpectedPaths = const <String>[],
}) async {
  Cache.flutterRoot = '../../..';
  final AddPlatformCommand command = AddPlatformCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'add-platform',
    ...createArgs,
    dir.path,
  ]);

  bool pathExists(String path) {
    final String fullPath = globals.fs.path.join(dir.path, path);
    return globals.fs.typeSync(fullPath) != FileSystemEntityType.notFound;
  }

  final List<String> failures = <String>[
    for (final String path in expectedPaths)
      if (!pathExists(path))
        'Path "$path" does not exist.',
    for (final String path in unexpectedPaths)
      if (pathExists(path))
        'Path "$path" exists when it shouldn\'t.',
  ];
  expect(failures, isEmpty, reason: failures.join('\n'));
}

Future<void> _addPlatformAndAnalyzeProject(
  Directory dir,
  List<String> createArgs,
  List<String> expectedPaths, {
  List<String> unexpectedPaths = const <String>[],
}) async {
  await _addPlatform(dir, createArgs, expectedPaths, unexpectedPaths: unexpectedPaths);
  await _analyzeProject(dir.path);
}

YamlMap _getPlatformsInPubspec(String projectDir) {
  final String pubspecPath = globals.fs.path.join(projectDir, 'pubspec.yaml');
  final YamlMap pubspec = loadYaml(globals.fs.file(pubspecPath).readAsStringSync()) as YamlMap;
  if (pubspec == null) {
      return null;
  }
  final YamlMap flutterConfig = pubspec['flutter'] as YamlMap;
  if (flutterConfig == null) {
    return null;
  }
  final YamlMap pluginConfig = flutterConfig['plugin'] as YamlMap;
  if (pluginConfig == null) {
    return null;
  }
  return pluginConfig['platforms'] as YamlMap;
}

void _validatePubspecForPlugin(String projectDir, String platform, String pluginClass, String androidPackage) {
    final YamlMap platformsMap = _getPlatformsInPubspec(projectDir);
    expect(platformsMap[platform], isNotNull);
    expect(platformsMap[platform]['pluginClass'], pluginClass);
    if (platform == 'android') {
      expect(platformsMap[platform]['package'], androidPackage);
    }
}

Future<void> _ensureFlutterToolsSnapshot() async {
  final String flutterToolsPath = globals.fs.path.absolute(globals.fs.path.join(
    'bin',
    'flutter_tools.dart',
  ));
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(globals.fs.path.join(
    '..',
    '..',
    'bin',
    'cache',
    'flutter_tools.snapshot',
  ));
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
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(globals.fs.path.join(
    '..',
    '..',
    'bin',
    'cache',
    'flutter_tools.snapshot',
  ));

  final File snapshotBackup = globals.fs.file(flutterToolsSnapshotPath + '.bak');
  if (!snapshotBackup.existsSync()) {
    // No backup to restore.
    return;
  }

  snapshotBackup.renameSync(flutterToolsSnapshotPath);
}

Future<void> _analyzeProject(String workingDir) async {
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(globals.fs.path.join(
    '..',
    '..',
    'bin',
    'cache',
    'flutter_tools.snapshot',
  ));

  final List<String> args = <String>[
    flutterToolsSnapshotPath,
    'analyze',
  ];

  final ProcessResult exec = await Process.run(
    globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
    args,
    workingDirectory: workingDir,
  );
  if (exec.exitCode != 0) {
    print(exec.stdout);
    print(exec.stderr);
  }
  expect(exec.exitCode, 0);
}

Future<void> _runFlutterTest(Directory workingDir, { String target }) async {
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(globals.fs.path.join(
    '..',
    '..',
    'bin',
    'cache',
    'flutter_tools.snapshot',
  ));

  // While flutter test does get packages, it doesn't write version
  // files anymore.
  await Process.run(
    globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
    <String>[
      flutterToolsSnapshotPath,
      'packages',
      'get',
    ],
    workingDirectory: workingDir.path,
  );

  final List<String> args = <String>[
    flutterToolsSnapshotPath,
    'test',
    '--no-color',
    if (target != null) target,
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

class MockFlutterVersion extends Mock implements FlutterVersion {}

/// A ProcessManager that invokes a real process manager, but keeps
/// track of all commands sent to it.
class LoggingProcessManager extends LocalProcessManager {
  List<List<String>> commands = <List<String>>[];

  @override
  Future<Process> start(
    List<String> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    commands.add(command);
    return super.start(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
  }
}

class MockHttpClient implements HttpClient {
  MockHttpClient(this.statusCode, {this.result});

  final int statusCode;
  final String result;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(statusCode, result: result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClient - $invocation';
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  MockHttpClientRequest(this.statusCode, {this.result});

  final int statusCode;
  final String result;

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(statusCode, result: result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientRequest - $invocation';
  }
}

class MockHttpClientResponse implements HttpClientResponse {
  MockHttpClientResponse(this.statusCode, {this.result});

  @override
  final int statusCode;

  final String result;

  @override
  String get reasonPhrase => '<reason phrase>';

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.decompressed;
  }

  @override
  StreamSubscription<Uint8List> listen(
    void onData(Uint8List event), {
    Function onError,
    void onDone(),
    bool cancelOnError,
  }) {
    return Stream<Uint8List>.fromIterable(<Uint8List>[Uint8List.fromList(result.codeUnits)])
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future<dynamic> forEach(void Function(Uint8List element) action) {
    action(Uint8List.fromList(result.codeUnits));
    return Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientResponse - $invocation';
  }
}
