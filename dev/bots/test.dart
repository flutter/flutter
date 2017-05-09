import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'dart.exe' : 'dart');
final String pub = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
final String flutterTestArgs = Platform.environment['FLUTTER_TEST_ARGS'];
final bool hasColor = stdout.supportsAnsiEscapes;

final String bold = hasColor ? '\x1B[1m' : '';
final String red = hasColor ? '\x1B[31m' : '';
final String green = hasColor ? '\x1B[32m' : '';
final String yellow = hasColor ? '\x1B[33m' : '';
final String cyan = hasColor ? '\x1B[36m' : '';
final String reset = hasColor ? '\x1B[0m' : '';

/// When you call this, you can set FLUTTER_TEST_ARGS to pass custom
/// arguments to flutter test. For example, you might want to call this
/// script using FLUTTER_TEST_ARGS=--local-engine=host_debug_unopt to
/// use your own build of the engine.
///
/// To run the analysis part, run it with SHARD=analyze
///
/// For example:
/// SHARD=analyze bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// FLUTTER_TEST_ARGS=--local-engine=host_debug_unopt bin/cache/dart-sdk/bin/dart dev/bots/test.dart
Future<Null> main() async {
  if (Platform.environment['SHARD'] == 'docs') {
    print('${bold}DONE: test.dart does nothing in the docs shard.$reset');
  } else if (Platform.environment['SHARD'] == 'analyze') {
    // Analyze all the Dart code in the repo.
    await _runFlutterAnalyze(flutterRoot,
      options: <String>['--flutter-repo'],
    );

    // Try with the --watch analyzer, to make sure it returns success also.
    // The --benchmark argument exits after one run.
    await _runFlutterAnalyze(flutterRoot,
      options: <String>['--flutter-repo', '--watch', '--benchmark'],
    );

    // Try an analysis against a big version of the gallery.
    await _runCommand(dart, <String>[path.join(flutterRoot, 'dev', 'tools', 'mega_gallery.dart')],
      workingDirectory: flutterRoot,
    );
    await _runFlutterAnalyze(path.join(flutterRoot, 'dev', 'benchmarks', 'mega_gallery'),
      options: <String>['--watch', '--benchmark'],
    );

    print('${bold}DONE: Analysis successful.$reset');
  } else {
    // Verify that the tests actually return failure on failure and success on success.
    final String automatedTests = path.join(flutterRoot, 'dev', 'automated_tests');
    await _runFlutterTest(automatedTests,
      script: path.join('test_smoke_test', 'fail_test.dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: path.join('test_smoke_test', 'pass_test.dart'),
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: path.join('test_smoke_test', 'crash1_test.dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: path.join('test_smoke_test', 'crash2_test.dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: path.join('test_smoke_test', 'syntax_error_test.broken_dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: path.join('test_smoke_test', 'missing_import_test.broken_dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runCommand(flutter, <String>['drive', '--use-existing-app', '-t', path.join('test_driver', 'failure.dart')],
      workingDirectory: path.join(flutterRoot, 'packages', 'flutter_driver'),
      expectFailure: true,
      printOutput: false,
    );

    final List<String> coverageFlags = <String>[];
    if (Platform.environment['TRAVIS'] != null && Platform.environment['TRAVIS_PULL_REQUEST'] == 'false')
      coverageFlags.add('--coverage');

    // Run tests.
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter'),
      options: coverageFlags,
    );
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'));
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'));
    await _pubRunTest(path.join(flutterRoot, 'packages', 'flutter_tools'));

    await _runAllDartTests(path.join(flutterRoot, 'dev', 'devicelab'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'));
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'hello_world'));
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'layers'));
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'stocks'));
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'));

    print('${bold}DONE: All tests successful.$reset');
  }
}

Future<Null> _pubRunTest(
  String workingDirectory, {
  String testPath,
}) {
  final List<String> args = <String>['run', 'test', '-rexpanded'];
  if (testPath != null)
    args.add(testPath);
  return _runCommand(pub, args, workingDirectory: workingDirectory);
}

Future<Null> _runCommand(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectFailure: false,
  bool printOutput: true,
  bool skip: false,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);
  if (skip) {
    _printProgress('SKIPPING', relativeWorkingDir, commandDescription);
    return null;
  }
  _printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  Future<List<List<int>>> savedStdout, savedStderr;
  if (printOutput) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
  } else {
    savedStdout = process.stdout.toList();
    savedStderr = process.stderr.toList();
  }

  final int exitCode = await process.exitCode;
  if ((exitCode == 0) == expectFailure) {
    if (!printOutput) {
      print(UTF8.decode((await savedStdout).expand((List<int> ints) => ints).toList()));
      print(UTF8.decode((await savedStderr).expand((List<int> ints) => ints).toList()));
    }
    print(
      '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset\n'
      '${bold}ERROR:$red Last command exited with $exitCode (expected: ${expectFailure ? 'non-zero' : 'zero'}).$reset\n'
      '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset'
    );
    exit(1);
  }
}

Future<Null> _runFlutterTest(String workingDirectory, {
    String script,
    bool expectFailure: false,
    bool printOutput: true,
    List<String> options: const <String>[],
    bool skip: false,
}) {
  final List<String> args = <String>['test']..addAll(options);
  if (flutterTestArgs != null && flutterTestArgs.isNotEmpty)
    args.add(flutterTestArgs);
  if (script != null)
    args.add(script);
  return _runCommand(flutter, args,
    workingDirectory: workingDirectory,
    expectFailure: expectFailure,
    printOutput: printOutput,
    skip: skip || Platform.isWindows, // TODO(goderbauer): run on Windows when sky_shell is available
  );
}

Future<Null> _runAllDartTests(String workingDirectory, {
  Map<String, String> environment,
}) {
  final List<String> args = <String>['--checked', path.join('test', 'all.dart')];
  return _runCommand(dart, args,
    workingDirectory: workingDirectory,
    environment: environment,
  );
}

Future<Null> _runFlutterAnalyze(String workingDirectory, {
  List<String> options: const <String>[]
}) {
  return _runCommand(flutter, <String>['analyze']..addAll(options),
    workingDirectory: workingDirectory,
  );
}

void _printProgress(String action, String workingDir, String command) {
  const String arrow = '⏩';
  print('$arrow $action: cd $cyan$workingDir$reset; $yellow$command$reset');
}
