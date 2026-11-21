// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi show Abi;
import 'dart:io' as io;
import 'dart:isolate' show Isolate;

import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

/// What `bin/et` says where `gclient sync` has not run and the build is GN's.
const String _needsGclient = "You must run 'gclient sync -D' before using this tool.";

/// Writes `bazelisk` into [directory]: a stand-in that answers the entry
/// point's one query as Bazel does, a line per file, with [dart] and
/// [packageConfig], and leaves its own arguments in `<directory>/arguments`.
void _writeBazelStandIn(
  io.Directory directory, {
  required String dart,
  required String packageConfig,
  int exitCode = 0,
}) {
  directory.createSync(recursive: true);
  final script = io.File(path.join(directory.path, 'bazelisk'));
  script.writeAsStringSync('''
#!/bin/bash
echo "\$@" > "${directory.path}/arguments"
echo "$packageConfig:1:1: source file @engine_package_config//:package_config.json"
echo "$dart:1:1: source file @dart_sdk//:bin/dart"
exit $exitCode
''');
  io.Process.runSync('chmod', <String>['+x', script.path]);
}

/// The environment of a run of the entry point: this process's, without a
/// backend of its own, with [bazel] (a directory) first on PATH.
Map<String, String> _environment({io.Directory? bazel, String? backend}) {
  final environment = Map<String, String>.of(io.Platform.environment);
  environment.remove('ET_BACKEND');
  if (backend != null) {
    environment['ET_BACKEND'] = backend;
  }
  if (bazel != null) {
    environment['PATH'] = '${bazel.path}:${environment['PATH']}';
  }
  return environment;
}

void main() {
  final Engine engine;
  try {
    engine = Engine.findWithin();
  } catch (e) {
    io.stderr.writeln(e);
    io.exitCode = 1;
    return;
  }

  const Platform platform = LocalPlatform();
  final exe = platform.isWindows ? '.bat' : '';
  final String entrypointPath = path.join(engine.flutterDir.path, 'bin', 'et$exe');

  // The Dart SDK and the package configuration this test runs on: what the
  // stand-in for Bazel answers with, so that the tool starts as it would on
  // the ones Bazel fetches.
  final String sdk = path.dirname(path.dirname(io.Platform.resolvedExecutable));
  final String dart = path.join(sdk, 'bin', 'dart');
  final String packageConfig = Isolate.packageConfigSync!.toFilePath();

  // Whether `gclient sync` has run in the checkout the entry point is in: its
  // last hook leaves the tool's package a .dart_tool, which is what the
  // script looks for (from its own location, symlinks resolved).
  final String checkoutFlutter = path.dirname(
    path.dirname(io.File(entrypointPath).resolveSymbolicLinksSync()),
  );
  final bool synced = io.Directory(path.join(checkoutFlutter, 'tools', 'engine_tool', '.dart_tool'))
      .existsSync();

  test('The entry points under bin/ work', () async {
    final runner = ProcessRunner();
    final ProcessRunnerResult processResult = await runner.runProcess(<String>[
      entrypointPath,
      'help',
    ], failOk: true);
    if (processResult.exitCode != 0) {
      io.stdout.writeln(processResult.stdout);
      io.stderr.writeln(processResult.stderr);
    }
    expect(processResult.exitCode, equals(0));
  }, skip: synced ? null : 'This checkout never ran `gclient sync`; the next test is its own.');

  test(
    'Without `gclient sync` the entry point asks for it, and with the Bazel backend works',
    () async {
      final io.Directory temp = io.Directory.systemTemp.createTempSync('et_entry_point_test');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeBazelStandIn(temp, dart: dart, packageConfig: packageConfig);

      // The GN build is gclient's.
      final io.ProcessResult gn = await io.Process.run(
        entrypointPath,
        <String>['help'],
        environment: _environment(bazel: temp),
        includeParentEnvironment: false,
      );
      expect(gn.exitCode, equals(1));
      expect(gn.stdout, contains(_needsGclient));
      expect(io.File(path.join(temp.path, 'arguments')).existsSync(), isFalse);

      // The Bazel build fetches what it needs, the tool's SDK and packages
      // among it: the real tool starts, on what Bazel said.
      final io.ProcessResult bazel = await io.Process.run(
        entrypointPath,
        <String>['help'],
        environment: _environment(bazel: temp, backend: 'bazel'),
        includeParentEnvironment: false,
      );
      expect(bazel.exitCode, equals(0), reason: '${bazel.stdout}\n${bazel.stderr}');
      expect(bazel.stdout, isNot(contains(_needsGclient)));
      expect(
        io.File(path.join(temp.path, 'arguments')).readAsStringSync(),
        startsWith('query --output=location '),
      );
    },
    skip: platform.isWindows
        ? 'et.bat has no Bazel backend'
        : synced
        ? 'This checkout ran `gclient sync`; the previous test is its own.'
        : null,
  );

  // The script's own logic, in a tree made for it: a copy of bin/et, a tool
  // that prints its arguments, and a stand-in for Bazel. The same in every
  // checkout.
  group('bin/et', () {
    late io.Directory temp;
    late io.Directory bazel;
    late String script;
    late String flutter;

    setUp(() {
      temp = io.Directory.systemTemp.createTempSync('et_entry_point_test');
      flutter = path.join(temp.path, 'engine', 'src', 'flutter');
      io.Directory(path.join(flutter, 'bin')).createSync(recursive: true);
      script = path.join(flutter, 'bin', 'et');
      io.File(entrypointPath).copySync(script);
      io.Process.runSync('chmod', <String>['+x', script]);
      final toolBin = io.Directory(path.join(flutter, 'tools', 'engine_tool', 'bin'));
      toolBin.createSync(recursive: true);
      io.File(path.join(toolBin.path, 'et.dart')).writeAsStringSync(r'''
void main(List<String> arguments) {
  print('et.dart ran: ${arguments.join(' ')}');
}
''');
      // The tool above imports no package.
      final config = io.File(path.join(temp.path, 'packages', 'package_config.json'));
      config.createSync(recursive: true);
      config.writeAsStringSync('{"configVersion": 2, "packages": []}');
      bazel = io.Directory(path.join(temp.path, 'bazel'));
      _writeBazelStandIn(bazel, dart: dart, packageConfig: config.path);
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    Future<io.ProcessResult> et(List<String> arguments, {String? backend}) {
      return io.Process.run(
        script,
        arguments,
        environment: _environment(bazel: bazel, backend: backend),
        includeParentEnvironment: false,
      );
    }

    // What the stand-in for Bazel was run with, or null if it was not run.
    String? bazelArguments() {
      final file = io.File(path.join(bazel.path, 'arguments'));
      return file.existsSync() ? file.readAsStringSync().trim() : null;
    }

    void expectAsksForGclient(io.ProcessResult result) {
      expect(result.exitCode, equals(1));
      expect(result.stdout, contains(_needsGclient));
      expect(result.stdout, isNot(contains('et.dart ran')));
      expect(bazelArguments(), isNull);
    }

    void expectRunsOnWhatBazelFetched(io.ProcessResult result, String arguments) {
      expect(result.exitCode, equals(0), reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('et.dart ran: $arguments'));
      expect(result.stdout, isNot(contains(_needsGclient)));
      expect(
        bazelArguments(),
        allOf(
          startsWith('query --output=location '),
          contains('labels(srcs, //engine/src/flutter:package_config)'),
          contains('//:bin/dart'),
        ),
      );
    }

    test('asks for gclient sync when the build is GN and gclient has not run', () async {
      expectAsksForGclient(await et(<String>['help']));
      expectAsksForGclient(await et(<String>['build', '--backend', 'gn']));
      expectAsksForGclient(await et(<String>['help'], backend: 'gn'));
    });

    test('needs no gclient with --backend bazel', () async {
      expectRunsOnWhatBazelFetched(
        await et(<String>['build', '--backend', 'bazel']),
        'build --backend bazel',
      );
    });

    test('needs no gclient with --backend=bazel', () async {
      expectRunsOnWhatBazelFetched(
        await et(<String>['fetch', '--backend=bazel']),
        'fetch --backend=bazel',
      );
    });

    test('needs no gclient with ET_BACKEND=bazel', () async {
      expectRunsOnWhatBazelFetched(await et(<String>['help'], backend: 'bazel'), 'help');
    });

    test('the command line decides over ET_BACKEND, and its last --backend', () async {
      expectAsksForGclient(await et(<String>['build', '--backend', 'gn'], backend: 'bazel'));
      expectAsksForGclient(await et(<String>['build', '--backend=bazel', '--backend', 'gn']));
    });

    test("what follows -- is not the tool's", () async {
      expectAsksForGclient(await et(<String>['run', '--', '--backend', 'bazel']));
    });

    test('says so when Bazel cannot fetch', () async {
      _writeBazelStandIn(bazel, dart: dart, packageConfig: packageConfig, exitCode: 1);
      final io.ProcessResult result = await et(<String>['help'], backend: 'bazel');
      expect(result.exitCode, equals(1));
      expect(result.stdout, contains('Bazel could not fetch'));
      expect(result.stdout, isNot(contains('et.dart ran')));
    });

    test("says so when Bazel's answer names no SDK", () async {
      _writeBazelStandIn(
        bazel,
        dart: path.join(temp.path, 'nowhere', 'bin', 'dart'),
        packageConfig: packageConfig,
      );
      final io.ProcessResult result = await et(<String>['help'], backend: 'bazel');
      expect(result.exitCode, equals(1));
      expect(result.stdout, contains('Bazel did not say where'));
      expect(result.stdout, isNot(contains('et.dart ran')));
    });

    test("after gclient sync it runs on the checkout's SDK and asks Bazel nothing", () async {
      final String? prebuilts = switch (ffi.Abi.current()) {
        ffi.Abi.linuxX64 => 'linux-x64',
        ffi.Abi.linuxArm64 => 'linux-arm64',
        ffi.Abi.macosX64 => 'macos-x64',
        ffi.Abi.macosArm64 => 'macos-arm64',
        _ => null,
      };
      if (prebuilts == null) {
        markTestSkipped('No prebuilt Dart SDK for ${ffi.Abi.current()}');
        return;
      }
      // What `gclient sync` leaves: the prebuilt SDK, and a .dart_tool in
      // the tool's package.
      io.Directory(path.join(flutter, 'prebuilts', prebuilts)).createSync(recursive: true);
      io.Link(path.join(flutter, 'prebuilts', prebuilts, 'dart-sdk')).createSync(sdk);
      io.Directory(path.join(flutter, 'tools', 'engine_tool', '.dart_tool')).createSync();

      for (final backend in <String?>[null, 'bazel']) {
        final io.ProcessResult result = await et(<String>['help'], backend: backend);
        expect(result.exitCode, equals(0), reason: '${result.stdout}\n${result.stderr}');
        expect(result.stdout, contains('et.dart ran: help'));
        expect(bazelArguments(), isNull);
      }
    });
  }, skip: platform.isWindows ? 'bin/et is the entry point on Linux and macOS' : null);
}
