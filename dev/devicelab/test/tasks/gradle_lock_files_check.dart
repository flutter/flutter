// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/utils.dart' show flutterDirectory;
import 'package:flutter_devicelab/tasks/gradle_lock_files_check.dart';

import '../common.dart';

const String _dartCommand = 'dart';
const String _scriptFilePath = 'tools/bin/generate_gradle_lockfiles.dart';

class MockExec {
  String? lastExecutable;
  List<String>? lastArguments;
  bool? lastCanFail;
  String? lastWorkingDirectory;

  int _nextResult = 0;
  Exception? _nextException;

  void setNextResult(int result) {
    _nextResult = result;
    _nextException = null;
  }

  void setNextException(Exception exception) {
    _nextException = exception;
  }

  Future<int> call(
      String executable,
      List<String> arguments, {
        Map<String, String>? environment,
        bool canFail = false,
        String? workingDirectory,
        StringBuffer? output,
        StringBuffer? stderr,
      }) async {
    lastExecutable = executable;
    lastArguments = arguments;
    lastCanFail = canFail;
    lastWorkingDirectory = workingDirectory;
    if (_nextException != null) {
      throw _nextException!;
    }
    return _nextResult;
  }
}

class MockEval {
  String? lastExecutable;
  List<String>? lastArguments;
  bool? lastCanFail;
  bool? lastPrintStdout;
  bool? lastPrintStderr;

  String _nextResult = '';
  Exception? _nextException;

  void setNextResult(String result) {
    _nextResult = result;
    _nextException = null;
  }

  void setNextException(Exception exception) {
    _nextException = exception;
  }

  Future<String> call(
      String executable,
      List<String> arguments, {
        Map<String, String>? environment,
        bool canFail = false,
        String? workingDirectory,
        StringBuffer? stdout,
        StringBuffer? stderr,
        bool printStdout = true,
        bool printStderr = true,
      }) async {
    lastExecutable = executable;
    lastArguments = arguments;
    lastCanFail = canFail;
    lastPrintStdout = printStdout;
    lastPrintStderr = printStderr;

    if (_nextException != null) {
      throw _nextException!;
    }
    return _nextResult;
  }
}

Matcher _throwsExceptionWithMessage(String messageSubstring) {
  return throwsA(isA<Exception>().having(
        (e) => e.toString(),
    'message',
    contains(messageSubstring),
  ));
}

void main() {
  late MockExec mockExec;
  late MockEval mockEval;

  setUp(() {
    mockExec = MockExec();
    mockEval = MockEval();
  });

  group('runGradleLockFilesCheck', () {
    test('succeeds when no lockfile changes are detected', () async {
      mockExec.setNextResult(0);
      mockEval.setNextResult(' M cache/somefile.txt\n?? ignored.txt\n');

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        completes,
      );

      expect(mockExec.lastExecutable, _dartCommand);
      expect(mockExec.lastArguments, contains(_scriptFilePath));
      expect(mockExec.lastArguments, contains('--no-gradle-generation'));
      expect(mockExec.lastCanFail, isTrue);
      expect(mockExec.lastWorkingDirectory, flutterDirectory.path);

      expect(mockEval.lastExecutable, 'git');
      expect(mockEval.lastArguments, contains('status'));
      expect(mockEval.lastCanFail, isTrue);
      expect(mockEval.lastPrintStdout, isFalse);
      expect(mockEval.lastPrintStderr, isFalse);
    });

    test('throws an exception when lockfile changes are detected', () async {
      mockExec.setNextResult(0);
      mockEval.setNextResult(' M path/to/file.lockfile\n?? another.lockfile\n');

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        _throwsExceptionWithMessage('Gradle lockfiles are not up to date, or new/modified lockfiles are not staged.'),
      );
    });

    test('exception message contains details of changed lockfiles and instructions', () async {
      mockExec.setNextResult(0);
      mockEval.setNextResult(' M path/to/file.lockfile\n?? another.lockfile\n');

      try {
        await runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        );
        fail('Expected an exception to be thrown.');
      } catch (e) {
        final String errorMessage = e.toString();
        expect(errorMessage, contains('  M path/to/file.lockfile'));
        expect(errorMessage, contains('  ?? another.lockfile'));
        expect(errorMessage, contains("Please run `dart tools/bin/generate_gradle_lockfiles.dart` locally"));
        expect(errorMessage, contains('then `git add` the files listed below'));
      }
    });

    test('throws if the dart command execution itself fails', () async {
      final Exception testException = Exception('Dart script execution failed');
      mockExec.setNextException(testException);

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        _throwsExceptionWithMessage('Dart script execution failed'),
      );
      expect(mockExec.lastExecutable, _dartCommand);
    });

    test('throws if git status command execution fails', () async {
      mockExec.setNextResult(0);
      final Exception testException = Exception('Git status command failed');
      mockEval.setNextException(testException);

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        _throwsExceptionWithMessage('Git status command failed'),
      );
      expect(mockExec.lastExecutable, _dartCommand);
      expect(mockEval.lastExecutable, 'git');
    });
  });
}
