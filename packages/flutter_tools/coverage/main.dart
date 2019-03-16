import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:pedantic/pedantic.dart';

const Set<String> skipTests = <String>{
  'test/coverage_test.dart',
  'test/stop_test.dart',
};

/// Generates a coverage test file, executes it, and then deletes it.
///
/// Must be run from the flutter_tools directory.
///
/// Requires lcov and genhtml to be on PATH.
/// https://github.com/linux-test-project/lcov.git.
Future<void> main() async {
  // Gather all test files that need to be imported.
  final List<String> testFilePaths = <String>[];
  for (FileSystemEntity fileSystemEntity in Directory('test').listSync(recursive: true)) {
    if (fileSystemEntity.path.endsWith('_test.dart') && !skipTests.any((String test) => fileSystemEntity.path.contains(test))) {
      testFilePaths.add(fileSystemEntity.path);
    }
  }

  // Generate a single test file that imports all test mains.
  final StringBuffer buffer = StringBuffer();
  buffer.write('''
import 'package:test/test.dart';
''');
  for (int i = 0; i < testFilePaths.length; i++) {
    final String testFilePath = testFilePaths[i];
    buffer.writeln('import "${testFilePath.substring(5)}" as i$i;');
  }
  buffer.writeln('void main() {');
  // test group make this runnable without pub.
  for (int i = 0; i < testFilePaths.length; i++) {
    buffer.writeln('  group("coverage-$i", () {');
    buffer.writeln('    i$i.main();');
    buffer.writeln('  });');
  }
  buffer.writeln('}');

  // Create a hiddent directory to run the test in.
  final Directory tempDirectory = Directory(path.join(Directory.current.path, '.coverage_report'));
  tempDirectory.createSync();
  final File testFile = File(path.join(Directory.current.path, 'test', 'coverage_test.dart'));
  testFile.createSync();
  testFile.writeAsStringSync(buffer.toString());


  final String flutterRoot = Directory.current.parent.parent.path;
  final String pubPath = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'pub');
  final String dartPath = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');

  // Run the test with coverage. This will pause and not exit.
  final Process testProcess = await Process.start(dartPath, <String>[
    '--pause-isolates-on-exit',
    '--enable-vm-service=12345',
    testFile.path,
  ], runInShell: true);
  testProcess.stdout
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(print);
  testProcess.stderr
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(print);
  unawaited(testProcess.exitCode.then((int code) {
    print('test process exited with $code');
  }));

  // Run the coverage collector.
  print('collecting coverage');
  try {
    final ProcessResult result = await Process.run(pubPath, <String>[
      'global',
      'run',
      'coverage:collect_coverage',
      '--resume-isolates',
      '--wait-paused',
      '--uri=http://127.0.0.1:12345',
      '-o',
      '.coverage_report/coverage.json',
    ], runInShell: true);
    print(result.stdout);
    print(result.stderr);
  } catch (err) {
    print(err);
    testProcess.kill();
    exit(1);
  }
  print('formatting coverage');
  try {
    final ProcessResult result = await Process.run(pubPath, <String>[
      'global',
      'run',
      'coverage:format_coverage',
      '--lcov',
      '--packages=.packages',
      '-i',
      '.coverage_report/coverage.json',
      '-o',
      '.coverage_report/coverage.lcov',
    ], runInShell: true);
    print(result.stdout);
    print(result.stderr);
  } catch (err) {
    print(err);
    testProcess.kill();
    exit(1);
  }

  print('generating html report');
  try {
    await Process.run('genhtml', <String>[
      '.coverage_report/coverage.lcov',
      '-o',
      '.coverage_report/report.html',
    ], runInShell: true);
  } catch (err) {
    print(err);
    testProcess.kill();
    exit(1);
  }

  testProcess.kill();
}