// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_tools/src/test/flutter_web_goldens.dart';
import 'package:flutter_tools/src/test/test_compiler.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';
import '../../src/testbed.dart';

void main() {

  group('Test that TestGoldenComparator', () {
    Testbed testbed;
    Uri goldenKey;
    Uri goldenKey2;
    Uri testUri;
    Uri testUri2;
    Uint8List imageBytes;
    MockProcessManager mockProcessManager;
    MockTestCompiler mockCompiler;

    setUp(() {
      goldenKey = Uri.parse('file://golden_key');
      goldenKey2 = Uri.parse('file://second_golden_key');
      testUri = Uri.parse('file://test_uri');
      testUri2 = Uri.parse('file://second_test_uri');
      imageBytes = Uint8List.fromList(<int>[1,2,3,4,5]);
      mockProcessManager = MockProcessManager();
      mockCompiler = MockTestCompiler();
      when(mockCompiler.compile(any)).thenAnswer((_) => Future<String>.value('compiler_output'));

      testbed = Testbed(overrides: <Type, Generator>{
        ProcessManager: () {
          return mockProcessManager;
        }
      });
    });

    test('succeed when golden comparison succeed', () => testbed.run(() async {
      final Map<String, dynamic> expectedResponse = <String, dynamic>{
        'success': true,
        'message': 'some message',
      };

      when(mockProcessManager.start(any, environment: anyNamed('environment')))
        .thenAnswer((Invocation invocation) async {
          return FakeProcess(
            exitCode: Future<int>.value(0),
            stdout: stdoutFromString(jsonEncode(expectedResponse) + '\n'),
          );
      });

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => mockCompiler,
      );

      final String result = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result, null);
    }));

    test('fail with error message when golden comparison failed', () => testbed.run(() async {
      final Map<String, dynamic> expectedResponse = <String, dynamic>{
        'success': false,
        'message': 'some message',
      };

      when(mockProcessManager.start(any, environment: anyNamed('environment')))
        .thenAnswer((Invocation invocation) async {
          return FakeProcess(
            exitCode: Future<int>.value(0),
            stdout: stdoutFromString(jsonEncode(expectedResponse) + '\n'),
          );
      });

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => mockCompiler,
      );

      final String result = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result, 'some message');
    }));

    test('reuse the process for the same test file', () => testbed.run(() async {
      final Map<String, dynamic> expectedResponse1 = <String, dynamic>{
        'success': false,
        'message': 'some message',
      };
      final Map<String, dynamic> expectedResponse2 = <String, dynamic>{
        'success': false,
        'message': 'some other message',
      };

      when(mockProcessManager.start(any, environment: anyNamed('environment')))
        .thenAnswer((Invocation invocation) async {
          return FakeProcess(
            exitCode: Future<int>.value(0),
            stdout: stdoutFromString(jsonEncode(expectedResponse1) + '\n' + jsonEncode(expectedResponse2) + '\n'),
          );
      });

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => mockCompiler,
      );

      final String result1 = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result1, 'some message');
      final String result2 = await comparator.compareGoldens(testUri, imageBytes, goldenKey2, false);
      expect(result2, 'some other message');
      verify(mockProcessManager.start(any, environment: anyNamed('environment'))).called(1);
    }));

    test('does not reuse the process for different test file', () => testbed.run(() async {
      final Map<String, dynamic> expectedResponse1 = <String, dynamic>{
        'success': false,
        'message': 'some message',
      };
      final Map<String, dynamic> expectedResponse2 = <String, dynamic>{
        'success': false,
        'message': 'some other message',
      };

      when(mockProcessManager.start(any, environment: anyNamed('environment')))
        .thenAnswer((Invocation invocation) async {
          return FakeProcess(
            exitCode: Future<int>.value(0),
            stdout: stdoutFromString(jsonEncode(expectedResponse1) + '\n' + jsonEncode(expectedResponse2) + '\n'),
          );
      });

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => mockCompiler,
      );

      final String result1 = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result1, 'some message');
      final String result2 = await comparator.compareGoldens(testUri2, imageBytes, goldenKey2, false);
      expect(result2, 'some message');
      verify(mockProcessManager.start(any, environment: anyNamed('environment'))).called(2);
    }));

    test('removes all temporary files when closed', () => testbed.run(() async {
      final Map<String, dynamic> expectedResponse = <String, dynamic>{
        'success': true,
        'message': 'some message',
      };

      when(mockProcessManager.start(any, environment: anyNamed('environment')))
        .thenAnswer((Invocation invocation) async {
          return FakeProcess(
            exitCode: Future<int>.value(0),
            stdout: stdoutFromString(jsonEncode(expectedResponse) + '\n'),
          );
      });

      final TestGoldenComparator comparator = TestGoldenComparator(
        'shell',
        () => mockCompiler,
      );

      final String result = await comparator.compareGoldens(testUri, imageBytes, goldenKey, false);
      expect(result, null);

      await comparator.close();
      expect(globals.fs.systemTempDirectory.listSync(recursive: true), isEmpty);
    }));
  });
}

Stream<List<int>> stdoutFromString(String string) => Stream<List<int>>.fromIterable(<List<int>>[
  utf8.encode(string),
]);

class MockProcessManager extends Mock implements ProcessManager {}
class MockTestCompiler extends Mock implements TestCompiler {}
