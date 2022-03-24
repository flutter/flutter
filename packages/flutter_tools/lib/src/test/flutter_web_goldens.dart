// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../convert.dart';
import '../web/compile.dart';
import 'test_compiler.dart';
import 'test_config.dart';

/// Helper class to start golden file comparison in a separate process.
///
/// The golden file comparator is configured using flutter_test_config.dart and that
/// file can contain arbitrary Dart code that depends on dart:ui. Thus it has to
/// be executed in a `flutter_tester` environment. This helper class generates a
/// Dart file configured with flutter_test_config.dart to perform the comparison
/// of golden files.
class TestGoldenComparator {
  /// Creates a [TestGoldenComparator] instance.
  TestGoldenComparator(this.shellPath, this.compilerFactory, {
    @required Logger logger,
    @required FileSystem fileSystem,
    @required ProcessManager processManager,
    @required this.webRenderer,
  }) : tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_web_platform.'),
       _logger = logger,
       _fileSystem = fileSystem,
       _processManager = processManager;

  final String shellPath;
  final Directory tempDir;
  final TestCompiler Function() compilerFactory;
  final Logger _logger;
  final FileSystem _fileSystem;
  final ProcessManager _processManager;
  final WebRendererMode webRenderer;

  TestCompiler _compiler;
  TestGoldenComparatorProcess _previousComparator;
  Uri _previousTestUri;

  Future<void> close() async {
    tempDir.deleteSync(recursive: true);
    await _compiler?.dispose();
    await _previousComparator?.close();
  }

  /// Start golden comparator in a separate process. Start one file per test file
  /// to reduce the overhead of starting `flutter_tester`.
  Future<TestGoldenComparatorProcess> _processForTestFile(Uri testUri) async {
    if (testUri == _previousTestUri) {
      return _previousComparator;
    }

    final String bootstrap = TestGoldenComparatorProcess.generateBootstrap(_fileSystem.file(testUri), testUri, logger: _logger);
    final Process process = await _startProcess(bootstrap);
    unawaited(_previousComparator?.close());
    _previousComparator = TestGoldenComparatorProcess(process, logger: _logger);
    _previousTestUri = testUri;

    return _previousComparator;
  }

  Future<Process> _startProcess(String testBootstrap) async {
    // Prepare the Dart file that will talk to us and start the test.
    final File listenerFile = (await tempDir.createTemp('listener')).childFile('listener.dart');
    await listenerFile.writeAsString(testBootstrap);

    // Lazily create the compiler
    _compiler = _compiler ?? compilerFactory();
    final String output = await _compiler.compile(listenerFile.uri);
    final List<String> command = <String>[
      shellPath,
      '--disable-observatory',
      '--non-interactive',
      '--packages=${_fileSystem.path.join('.dart_tool', 'package_config.json')}',
      output,
    ];

    final Map<String, String> environment = <String, String>{
      // Chrome is the only supported browser currently.
      'FLUTTER_TEST_BROWSER': 'chrome',
      'FLUTTER_WEB_RENDERER': webRenderer == WebRendererMode.html ? 'html' : 'canvaskit',
    };
    return _processManager.start(command, environment: environment);
  }

  Future<String> compareGoldens(Uri testUri, Uint8List bytes, Uri goldenKey, bool updateGoldens) async {
    final File imageFile = await (await tempDir.createTemp('image')).childFile('image').writeAsBytes(bytes);
    final TestGoldenComparatorProcess process = await _processForTestFile(testUri);
    process.sendCommand(imageFile, goldenKey, updateGoldens);

    final Map<String, dynamic> result = await process.getResponse();

    if (result == null) {
      return 'unknown error';
    } else {
      return (result['success'] as bool) ? null : ((result['message'] as String) ?? 'does not match');
    }
  }
}

/// Represents a `flutter_tester` process started for golden comparison. Also
/// handles communication with the child process.
class TestGoldenComparatorProcess {
  /// Creates a [TestGoldenComparatorProcess] backed by [process].
  TestGoldenComparatorProcess(this.process, {@required Logger logger}) : _logger = logger {
    // Pipe stdout and stderr to printTrace and printError.
    // Also parse stdout as a stream of JSON objects.
    streamIterator = StreamIterator<Map<String, dynamic>>(
      process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .where((String line) {
          logger.printTrace('<<< $line');
          return line.isNotEmpty && line[0] == '{';
        })
        .map<dynamic>(jsonDecode)
        .cast<Map<String, dynamic>>());

    process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .forEach((String line) {
          logger.printError('<<< $line');
        });
  }

  final Logger _logger;
  final Process process;
  StreamIterator<Map<String, dynamic>> streamIterator;

  Future<void> close() async {
    process.kill();
    await process.exitCode;
  }

  void sendCommand(File imageFile, Uri goldenKey, bool updateGoldens) {
    final Object command = jsonEncode(<String, dynamic>{
      'imageFile': imageFile.path,
      'key': goldenKey.toString(),
      'update': updateGoldens,
    });
    _logger.printTrace('Preparing to send command: $command');
    process.stdin.writeln(command);
  }

  Future<Map<String, dynamic>> getResponse() async {
    final bool available = await streamIterator.moveNext();
    assert(available);
    return streamIterator.current;
  }

  static String generateBootstrap(File testFile, Uri testUri, {@required Logger logger}) {
    final File testConfigFile = findTestConfigFile(testFile, logger);
    // Generate comparator process for the file.
    return '''
import 'dart:convert'; // flutter_ignore: dart_convert_import
import 'dart:io'; // flutter_ignore: dart_io_import

import 'package:flutter_test/flutter_test.dart';

${testConfigFile != null ? "import '${Uri.file(testConfigFile.path)}' as test_config;" : ""}

void main() async {
  LocalFileComparator comparator = LocalFileComparator(Uri.parse('$testUri'));
  goldenFileComparator = comparator;

  ${testConfigFile != null ? 'test_config.testExecutable(() async {' : ''}
  final commands = stdin
    .transform<String>(utf8.decoder)
    .transform<String>(const LineSplitter())
    .map<dynamic>(jsonDecode);
  await for (final dynamic command in commands) {
    if (command is Map<String, dynamic>) {
      File imageFile = File(command['imageFile'] as String);
      Uri goldenKey = Uri.parse(command['key'] as String);
      bool update = command['update'] as bool;

      final bytes = await File(imageFile.path).readAsBytes();
      if (update) {
        await goldenFileComparator.update(goldenKey, bytes);
        print(jsonEncode({'success': true}));
      } else {
        try {
          bool success = await goldenFileComparator.compare(bytes, goldenKey);
          print(jsonEncode({'success': success}));
        } on Exception catch (ex) {
          print(jsonEncode({'success': false, 'message': '\$ex'}));
        }
      }
    } else {
      print('object type is not right');
    }
  }
  ${testConfigFile != null ? '});' : ''}
}
    ''';
  }
}
