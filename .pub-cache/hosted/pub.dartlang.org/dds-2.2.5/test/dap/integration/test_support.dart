// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dds/src/dap/logging.dart';
import 'package:dds/src/dap/protocol_generated.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_server.dart';

/// A [RegExp] that matches the "Connecting to VM Service" banner that is sent
/// by the DAP adapter as the first output event for a debug session.
final dapVmServiceBannerPattern =
    RegExp(r'Connecting to VM Service at ([^\s]+)\s');

/// Whether to run the DAP server in-process with the tests, or externally in
/// another process.
///
/// By default tests will run the DAP server out-of-process to match the real
/// use from editors, but this complicates debugging the adapter. Set this env
/// variables to run the server in-process for easier debugging (this can be
/// simplified in VS Code by using a launch config with custom CodeLens links).
final useInProcessDap = Platform.environment['DAP_TEST_INTERNAL'] == 'true';

/// Whether to print all protocol traffic to stdout while running tests.
///
/// This is useful for debugging locally or on the bots and will include both
/// DAP traffic (between the test DAP client and the DAP server) and the VM
/// Service traffic (wrapped in a custom 'dart.log' event).
///
/// Verbose logging is temporarily enabled for all test runs to try and
/// understand failures noted at https://github.com/dart-lang/sdk/issues/48274.
/// Once resolved, this variable can be set back to the result of:
///     Platform.environment['DAP_TEST_VERBOSE'] == 'true'
final verboseLogging = true;

/// A [RegExp] that matches the `path` part of a VM Service URI that contains
/// an authentication token.
final vmServiceAuthCodePathPattern = RegExp(r'^/[\w_\-=]{5,15}/ws$');

/// A [RegExp] that matches the "The Dart VM service is listening on" banner that is sent
/// by the VM when not using --write-service-info.
final vmServiceBannerPattern =
    RegExp(r'The Dart VM service is listening on ([^\s]+)\s');

/// The root of the SDK containing the current running VM.
final sdkRoot = path.dirname(path.dirname(Platform.resolvedExecutable));

/// Expects the lines in [actual] to match the relevant matcher in [expected],
/// ignoring differences in line endings and trailing whitespace.
void expectLines(String actual, List<Object> expected) {
  expect(
    actual.replaceAll('\r\n', '\n').trim().split('\n'),
    equals(expected),
  );
}

/// Expects [actual] starts with [expected], ignoring differences in line
/// endings and trailing whitespace.
void expectLinesStartWith(String actual, List<String> expected) {
  expect(
    actual.replaceAll('\r\n', '\n').trim(),
    startsWith(expected.join('\n').trim()),
  );
}

/// Expects [response] to fail with a `message` matching [messageMatcher].
expectResponseError<T>(Future<T> response, Matcher messageMatcher) {
  expect(
    response,
    throwsA(
      const TypeMatcher<Response>()
          .having((r) => r.success, 'success', isFalse)
          .having((r) => r.message, 'message', messageMatcher),
    ),
  );
}

/// Returns the 1-base line in [file] that contains [searchText].
int lineWith(File file, String searchText) =>
    file.readAsLinesSync().indexWhere((line) => line.contains(searchText)) + 1;

Future<Process> startDartProcessPaused(
  String script,
  List<String> args, {
  required String cwd,
  List<String>? vmArgs,
}) async {
  final vmPath = Platform.resolvedExecutable;
  vmArgs ??= [];
  vmArgs.addAll([
    '--enable-vm-service=0',
    '--pause_isolates_on_start',
  ]);
  final processArgs = [
    ...vmArgs,
    script,
    ...args,
  ];

  return Process.start(
    vmPath,
    processArgs,
    workingDirectory: cwd,
  );
}

/// Monitors [process] for the Observatory/VM Service banner and extracts the
/// VM Service URI.
Future<Uri> waitForStdoutVmServiceBanner(Process process) {
  final _vmServiceUriCompleter = Completer<Uri>();

  late StreamSubscription<String> vmServiceBannerSub;
  vmServiceBannerSub = process.stdout.transform(utf8.decoder).listen(
    (line) {
      final match = vmServiceBannerPattern.firstMatch(line);
      if (match != null) {
        _vmServiceUriCompleter.complete(Uri.parse(match.group(1)!));
        vmServiceBannerSub.cancel();
      }
    },
    onDone: () {
      if (!_vmServiceUriCompleter.isCompleted) {
        _vmServiceUriCompleter.completeError('Stream ended');
      }
    },
  );

  return _vmServiceUriCompleter.future;
}

/// A helper class containing the DAP server/client for DAP integration tests.
class DapTestSession {
  DapTestServer server;
  DapTestClient client;
  final Directory testDir =
      Directory.systemTemp.createTempSync('dart-sdk-dap-test');
  late final Directory testAppDir;
  late final Directory testPackagesDir;

  DapTestSession._(this.server, this.client) {
    testAppDir = testDir.createTempSync('app');
    createPubspec(testAppDir, 'my_test_project');
    testPackagesDir = testDir.createTempSync('packages');
  }

  /// Adds package with [name] (optionally at [packageFolderUri]) to the
  /// project in [dir].
  ///
  /// If [packageFolderUri] is not supplied, will use [Isolate.resolvePackageUri]
  /// assuming the package is available to the tests.
  Future<void> addPackageDependency(
    Directory dir,
    String name, [
    Uri? packageFolderUri,
  ]) async {
    final proc = await Process.run(
      Platform.resolvedExecutable,
      [
        'pub',
        'add',
        name,
        if (packageFolderUri != null) ...[
          '--path',
          packageFolderUri.toFilePath(),
        ],
      ],
      workingDirectory: dir.path,
    );
    expect(
      proc.exitCode,
      isZero,
      reason: '${proc.stdout}\n${proc.stderr}'.trim(),
    );
  }

  /// Create a simple package named `foo` that has an empty `foo` function.
  Future<Uri> createFooPackage() {
    return createSimplePackage(
      'foo',
      '''
foo() {
  // Does nothing.
}
      ''',
    );
  }

  void createPubspec(Directory dir, String projectName) {
    final pubspecFile = File(path.join(dir.path, 'pubspec.yaml'));
    pubspecFile
      ..createSync()
      ..writeAsStringSync('''
name: $projectName
version: 1.0.0

environment:
  sdk: '>=2.13.0 <3.0.0'
''');
  }

  /// Creates a simple package script and adds the package to
  /// .dart_tool/package_config.json
  Future<Uri> createSimplePackage(
    String name,
    String content,
  ) async {
    final packageDir = Directory(path.join(testPackagesDir.path, name))
      ..createSync(recursive: true);
    final packageLibDir = Directory(path.join(packageDir.path, 'lib'))
      ..createSync(recursive: true);

    // Create a pubspec and a implementation file in the lib folder.
    createPubspec(packageDir, name);
    final testFile = File(path.join(packageLibDir.path, '$name.dart'));
    testFile.writeAsStringSync(content);

    // Add this new package as a dependency for the app.
    final fileUri = Uri.file('${packageDir.path}/');
    await addPackageDependency(testAppDir, name, fileUri);

    return Uri.parse('package:$name/$name.dart');
  }

  /// Creates a file in a temporary folder to be used as an application for testing.
  ///
  /// The file will be deleted at the end of the test run.
  File createTestFile(String content) {
    final testFile = File(path.join(testAppDir.path, 'test_file.dart'));
    testFile.writeAsStringSync(content);
    return testFile;
  }

  Future<void> tearDown() async {
    await client.stop();
    await server.stop();

    // Clean up any temp folders created during the test runs.
    await tryDelete(testDir);
  }

  /// Tries to delete [dir] multiple times before printing a warning and giving up.
  ///
  /// This avoids "The process cannot access the file because it is being
  /// used by another process" errors on Windows trying to delete folders that
  /// have only very recently been unlocked.
  Future<void> tryDelete(Directory dir) async {
    const maxAttempts = 10;
    const delay = Duration(milliseconds: 100);
    var attempt = 0;
    while (++attempt <= maxAttempts) {
      try {
        testDir.deleteSync(recursive: true);
        break;
      } catch (e) {
        if (attempt == maxAttempts) {
          print('Failed to delete $testDir after $maxAttempts attempts.\n$e');
          break;
        }
        await Future.delayed(delay);
      }
    }
  }

  static Future<DapTestSession> setUp({List<String>? additionalArgs}) async {
    final server = await startServer(additionalArgs: additionalArgs);
    final client = await DapTestClient.connect(
      server,
      captureVmServiceTraffic: verboseLogging,
      logger: verboseLogging ? print : null,
    );
    return DapTestSession._(server, client);
  }

  /// Starts a DAP server that can be shared across tests.
  static Future<DapTestServer> startServer({
    Logger? logger,
    Function? onError,
    List<String>? additionalArgs,
  }) async {
    return useInProcessDap
        ? await InProcessDapTestServer.create(
            logger: logger,
            onError: onError,
            additionalArgs: additionalArgs,
          )
        : await OutOfProcessDapTestServer.create(
            logger: logger,
            onError: onError,
            additionalArgs: additionalArgs,
          );
  }
}
