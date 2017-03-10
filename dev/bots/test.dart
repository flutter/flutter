import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

String flutterRoot = p.dirname(p.dirname(p.dirname(p.fromUri(Platform.script))));
String flutter = p.join(flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
String dart = p.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'dart.exe' : 'dart');
String pub = p.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
String flutterTestArgs = Platform.environment['FLUTTER_TEST_ARGS'];

/// When you call this, you can set FLUTTER_TEST_ARGS to pass custom
/// arguments to flutter test. For example, you might want to call this
/// script using FLUTTER_TEST_ARGS=--local-engine=host_debug_unopt to
/// use your own build of the engine.
Future<Null> main() async {
  if (Platform.environment['SHARD'] == 'docs') {
    print('\x1B[32mDONE: test.dart does nothing in the docs shard.\x1B[0m');
  } else if (Platform.environment['SHARD'] == 'analyze') {
    // Analyze all the Dart code in the repo.
    await _runFlutterAnalyze(flutterRoot,
      options: <String>['--flutter-repo'],
    );

    await _runCmd(dart, <String>[p.join(flutterRoot, 'dev', 'tools', 'mega_gallery.dart')],
      workingDirectory: flutterRoot,
    );
    await _runFlutterAnalyze(p.join(flutterRoot, 'dev', 'benchmarks', 'mega_gallery'),
      options: <String>['--watch', '--benchmark'],
    );

    print('\x1B[32mDONE: Analysis successful.\x1B[0m');
  } else {
    // Verify that the tests actually return failure on failure and success on success.
    final String automatedTests = p.join(flutterRoot, 'dev', 'automated_tests');
    await _runFlutterTest(automatedTests,
      script: p.join('test_smoke_test', 'fail_test.dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: p.join('test_smoke_test', 'pass_test.dart'),
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: p.join('test_smoke_test', 'crash1_test.dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: p.join('test_smoke_test', 'crash2_test.dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: p.join('test_smoke_test', 'syntax_error_test.broken_dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runFlutterTest(automatedTests,
      script: p.join('test_smoke_test', 'missing_import_test.broken_dart'),
      expectFailure: true,
      printOutput: false,
    );
    await _runCmd(flutter, <String>['drive', '--use-existing-app', '-t', p.join('test_driver', 'failure.dart')],
      workingDirectory: p.join(flutterRoot, 'packages', 'flutter_driver'),
      expectFailure: true,
      printOutput: false,
    );

    final List<String> coverageFlags = <String>[];
    if (Platform.environment['TRAVIS'] != null && Platform.environment['TRAVIS_PULL_REQUEST'] == 'false')
      coverageFlags.add('--coverage');

    // Run tests.
    await _runFlutterTest(p.join(flutterRoot, 'packages', 'flutter'),
      options: coverageFlags,
    );
    await _runFlutterTest(p.join(flutterRoot, 'packages', 'flutter_driver'));
    await _runFlutterTest(p.join(flutterRoot, 'packages', 'flutter_test'));
    await _runFlutterTest(p.join(flutterRoot, 'packages', 'flutter_markdown'));
    await _pubRunTest(p.join(flutterRoot, 'packages', 'flutter_tools'));

    await _runAllDartTests(p.join(flutterRoot, 'dev', 'devicelab'));
    await _runFlutterTest(p.join(flutterRoot, 'dev', 'manual_tests'));
    await _runFlutterTest(p.join(flutterRoot, 'examples', 'hello_world'));
    await _runFlutterTest(p.join(flutterRoot, 'examples', 'layers'));
    await _runFlutterTest(p.join(flutterRoot, 'examples', 'stocks'));
    await _runFlutterTest(p.join(flutterRoot, 'examples', 'flutter_gallery'));

    print('\x1B[32mDONE: All tests successful.\x1B[0m');
  }
}

Future<Null> _pubRunTest(
  String workingDirectory, {
  String testPath,
}) {
  final List<String> args = <String>['run', 'test'];
  if (testPath != null)
    args.add(testPath);
  return _runCmd(pub, args, workingDirectory: workingDirectory);
}

Future<Null> _runCmd(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectFailure: false,
  bool printOutput: true,
  bool skip: false,
}) async {
  final String cmd = '${p.relative(executable)} ${arguments.join(' ')}';
  final String relativeWorkingDir = p.relative(workingDirectory);
  if (skip) {
    _printProgress('SKIPPING', relativeWorkingDir, cmd);
    return null;
  }
  _printProgress('RUNNING', relativeWorkingDir, cmd);

  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  if (printOutput) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
  }

  final int exitCode = await process.exitCode;
  if ((exitCode == 0) == expectFailure) {
    print(
      '\x1B[31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1B[0m\n'
      '\x1B[1mERROR:\x1B[31m Last command exited with $exitCode (expected: ${expectFailure ? 'non-zero' : 'zero'}).\x1B[0m\n'
      '\x1B[31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1B[0m'
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
  if (flutterTestArgs != null)
    args.add(flutterTestArgs);
  if (script != null)
    args.add(script);
  return _runCmd(flutter, args,
    workingDirectory: workingDirectory,
    expectFailure: expectFailure,
    printOutput: printOutput,
    skip: skip || Platform.isWindows, // TODO(goderbauer): run on Windows when sky_shell is available
  );
}

Future<Null> _runAllDartTests(String workingDirectory, {
  Map<String, String> environment,
}) {
  final List<String> args = <String>['--checked', p.join('test', 'all.dart')];
  return _runCmd(dart, args,
    workingDirectory: workingDirectory,
    environment: environment,
  );
}

Future<Null> _runFlutterAnalyze(String workingDirectory, {
  List<String> options: const <String>[]
}) {
  return _runCmd(flutter, <String>['analyze']..addAll(options),
    workingDirectory: workingDirectory,
  );
}

void _printProgress(String action, String workingDir, String cmd) {
  print('>>> $action in \x1B[36m$workingDir\x1B[0m: \x1B[33m$cmd\x1B[0m');
}
