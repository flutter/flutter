// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/test/flutter_web_goldens.dart';
import 'package:flutter_tools/src/test/test_compiler.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Uri goldenKey = Uri.parse('file://golden_key');
final Uri goldenKey2 = Uri.parse('file://second_golden_key');
final Uri testUri = Uri.parse('file://test_uri');
final Uri testUri2  = Uri.parse('file://second_test_uri');
final Uint8List imageBytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);

void main() {

  group('Test that TestGoldenComparator', () {
    FakeProcessManager processManager;

    setUp(() {
      processManager = FakeProcessManager.empty();
    });

    testWithoutContext('succeed when golden comparison succeed', () async {
      final Map<String, dynamic> expectedResponse = <String, dynamic>{
        'success': true,
        'message': 'some message',
      };
      processManager.addCommand(FakeCommand(
        command: const <String>[
          'shell',
          '--disable-observatory',
          '--non-interactive',
          '--packages=.dart_tool/package_config.json',
          'compiler_output'
        ], stdout: '${jsonEncode(expectedResponse)}\n',
      ));

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => FakeTestCompiler(),
        processManager: processManager,
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
      );

      final String result = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result, null);
    });

    testWithoutContext('fail with error message when golden comparison failed', () async {
      final Map<String, dynamic> expectedResponse = <String, dynamic>{
        'success': false,
        'message': 'some message',
      };

      processManager.addCommand(FakeCommand(
        command: const <String>[
          'shell',
          '--disable-observatory',
          '--non-interactive',
          '--packages=.dart_tool/package_config.json',
          'compiler_output'
        ], stdout: '${jsonEncode(expectedResponse)}\n',
      ));

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => FakeTestCompiler(),
        processManager: processManager,
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
      );

      final String result = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result, 'some message');
    });

    testWithoutContext('reuse the process for the same test file', () async {
      final Map<String, dynamic> expectedResponse1 = <String, dynamic>{
        'success': false,
        'message': 'some message',
      };
      final Map<String, dynamic> expectedResponse2 = <String, dynamic>{
        'success': false,
        'message': 'some other message',
      };

      processManager.addCommand(FakeCommand(
        command: const <String>[
          'shell',
          '--disable-observatory',
          '--non-interactive',
          '--packages=.dart_tool/package_config.json',
          'compiler_output'
        ], stdout: '${jsonEncode(expectedResponse1)}\n${jsonEncode(expectedResponse2)}\n',
      ));

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => FakeTestCompiler(),
        processManager: processManager,
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
      );

      final String result1 = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result1, 'some message');

      final String result2 = await comparator.compareGoldens(testUri, imageBytes, goldenKey2, false);
      expect(result2, 'some other message');
    });

    testWithoutContext('does not reuse the process for different test file', () async {
      final Map<String, dynamic> expectedResponse1 = <String, dynamic>{
        'success': false,
        'message': 'some message',
      };
      final Map<String, dynamic> expectedResponse2 = <String, dynamic>{
        'success': false,
        'message': 'some other message',
      };

      processManager.addCommand(FakeCommand(
        command: const <String>[
          'shell',
          '--disable-observatory',
          '--non-interactive',
          '--packages=.dart_tool/package_config.json',
          'compiler_output'
        ], stdout: '${jsonEncode(expectedResponse1)}\n',
      ));
      processManager.addCommand(FakeCommand(
        command: const <String>[
          'shell',
          '--disable-observatory',
          '--non-interactive',
          '--packages=.dart_tool/package_config.json',
          'compiler_output'
        ], stdout: '${jsonEncode(expectedResponse2)}\n',
      ));

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => FakeTestCompiler(),
        processManager: processManager,
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
      );

      final String result1 = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result1, 'some message');

      final String result2 = await comparator.compareGoldens(testUri2, imageBytes, goldenKey2, false);
      expect(result2, 'some other message');
    });

    testWithoutContext('removes all temporary files when closed', () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final Map<String, dynamic> expectedResponse = <String, dynamic>{
        'success': true,
        'message': 'some message',
      };
      final StreamController<List<int>> controller = StreamController<List<int>>();
      final IOSink stdin = IOSink(controller.sink);
      processManager.addCommand(FakeCommand(
        command: const <String>[
          'shell',
          '--disable-observatory',
          '--non-interactive',
          '--packages=.dart_tool/package_config.json',
          'compiler_output'
        ], stdout: '${jsonEncode(expectedResponse)}\n',
        stdin: stdin,
      ));

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => FakeTestCompiler(),
        processManager: processManager,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
      );

      final String result = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result, null);

      await comparator.close();
      expect(fileSystem.systemTempDirectory.listSync(recursive: true), isEmpty);
    });
  });
}

class FakeTestCompiler extends Fake implements TestCompiler {
  @override
  Future<String> compile(Uri mainDart) {
    return Future<String>.value('compiler_output');
  }

  @override
  Future<void> dispose() async { }
}
