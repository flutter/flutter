// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show ProcessException;

import 'package:collection/collection.dart';
import 'package:flutter_devicelab/framework/utils.dart' show flutterDirectory;
import 'package:flutter_devicelab/tasks/gradle_lock_files_check.dart';
import 'package:meta/meta.dart';

import '../common.dart';

const String _dartCommand = 'dart';
const String _scriptFilePath = 'tools/bin/generate_gradle_lockfiles.dart';

@immutable
class MockCall {
  MockCall(this.executable, List<String> args, this.canFail, this.workingDirectory)
    : arguments = List<String>.unmodifiable(args);

  final String executable;
  final List<String> arguments;
  final bool canFail;
  final String? workingDirectory;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MockCall &&
        other.executable == executable &&
        const DeepCollectionEquality().equals(other.arguments, arguments) &&
        other.canFail == canFail &&
        other.workingDirectory == workingDirectory;
  }

  @override
  int get hashCode => Object.hash(
    executable,
    const DeepCollectionEquality().hash(arguments),
    canFail,
    workingDirectory,
  );

  @override
  String toString() {
    return 'MockCall(executable: $executable, arguments: $arguments, canFail: $canFail, workingDirectory: $workingDirectory)';
  }
}

class MockExec {
  final List<MockCall> calls = <MockCall>[];
  final List<dynamic> _responses = <dynamic>[];
  int _responseIndex = 0;

  void addResponse(dynamic response) {
    _responses.add(response);
  }

  void reset() {
    calls.clear();
    _responses.clear();
    _responseIndex = 0;
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
    calls.add(MockCall(executable, List<String>.from(arguments), canFail, workingDirectory));

    if (_responseIndex < _responses.length) {
      final dynamic response = _responses[_responseIndex++];
      if (response is Exception) {
        throw response;
      }
      if (response is int) {
        if (!canFail && response != 0) {
          throw ProcessException(
            executable,
            arguments,
            'MockProcessException: Command failed with exit code $response',
            response,
          );
        }
        return response;
      }
      throw StateError(
        'Unexpected response type in MockExec: ${response.runtimeType}, value: $response',
      );
    }
    return 0;
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

  String get nextResult => _nextResult;
  set nextResult(String result) {
    _nextResult = result;
    _nextException = null;
  }

  Exception? get nextException => _nextException;
  set nextException(Exception? exception) {
    _nextException = exception;
    if (exception != null) {
      _nextResult = '';
    }
  }

  void reset() {
    lastExecutable = null;
    lastArguments = null;
    lastCanFail = null;
    lastPrintStdout = null;
    lastPrintStderr = null;
    _nextResult = '';
    _nextException = null;
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

    if (nextException != null) {
      throw nextException!;
    }
    return nextResult;
  }
}

Matcher _throwsExceptionWithMessage(String messageSubstring) {
  return throwsA(
    isA<Exception>().having((Exception e) => e.toString(), 'message', contains(messageSubstring)),
  );
}

Matcher _throwsProcessExceptionWithCode(int exitCode) {
  return throwsA(
    isA<ProcessException>()
        .having((ProcessException e) => e.errorCode, 'errorCode', exitCode)
        .having((ProcessException e) => e.message, 'message', contains('MockProcessException')),
  );
}

void main() {
  late MockExec mockExec;
  late MockEval mockEval;

  setUp(() {
    mockExec = MockExec();
    mockEval = MockEval();
  });

  tearDown(() {
    mockExec.reset();
    mockEval.reset();
  });

  group('runGradleLockFilesCheck', () {
    test('succeeds when no lockfile changes are detected and pop succeeds', () async {
      mockExec.addResponse(0); // git stash
      mockExec.addResponse(0); // dart script
      mockExec.addResponse(0); // git stash pop
      mockEval.nextResult = ' M cache/somefile.txt\n?? ignored.txt\n'; // git status

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        completes,
      );

      expect(mockExec.calls.length, 3);
      expect(mockExec.calls[0], MockCall('git', const <String>['stash'], true, flutterDirectory.path));
      expect(
        mockExec.calls[1],
        MockCall(
          _dartCommand,
          const <String>[_scriptFilePath, '--no-gradle-generation'],
          true,
          flutterDirectory.path,
        ),
      );
      expect(
        mockExec.calls[2],
        MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
      );

      expect(mockEval.lastExecutable, 'git');
      expect(mockEval.lastArguments, contains('status'));
    });

    test('throws an exception when lockfile changes are detected and pop succeeds', () async {
      mockExec.addResponse(0); // git stash
      mockExec.addResponse(0); // dart script
      mockExec.addResponse(0); // git stash pop (succeeds)
      mockEval.nextResult = ' M path/to/file.lockfile\n?? another.lockfile\n'; // git status

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        _throwsExceptionWithMessage('Gradle lockfiles are not up to date'),
      );

      expect(mockExec.calls.length, 3);
      expect(
        mockExec.calls[2],
        MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
      );
    });

    test(
      'exception message contains details when lockfile changes are detected and pop succeeds',
      () async {
        mockExec.addResponse(0); // git stash
        mockExec.addResponse(0); // dart script
        mockExec.addResponse(0); // git stash pop (succeeds)
        mockEval.nextResult = ' M path/to/file.lockfile\n?? another.lockfile\n'; // git status

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
          expect(errorMessage, contains('Please run `$_dartCommand $_scriptFilePath` locally'));
        }
        expect(mockExec.calls.length, 3);
        expect(
          mockExec.calls[2],
          MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
        );
      },
    );

    test('throws if the dart command execution itself fails and pop succeeds', () async {
      final Exception dartException = Exception('Dart script execution failed');
      mockExec.addResponse(0); // git stash
      mockExec.addResponse(dartException); // dart script fails
      mockExec.addResponse(0); // git stash pop (succeeds)

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        _throwsExceptionWithMessage('Dart script execution failed'),
      );

      expect(mockExec.calls.length, 3); // stash, dart, pop
      expect(mockExec.calls[0], MockCall('git', const <String>['stash'], true, flutterDirectory.path));
      expect(
        mockExec.calls[1],
        MockCall(
          _dartCommand,
          const <String>[_scriptFilePath, '--no-gradle-generation'],
          true,
          flutterDirectory.path,
        ),
      );
      expect(
        mockExec.calls[2],
        MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
      );
      expect(mockEval.lastExecutable, isNull);
    });

    test('throws if git status command execution fails and pop succeeds', () async {
      mockExec.addResponse(0); // git stash
      mockExec.addResponse(0); // dart script
      mockExec.addResponse(0); // git stash pop (succeeds)
      final Exception gitStatusException = Exception('Git status command failed');
      mockEval.nextException = gitStatusException;

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        _throwsExceptionWithMessage('Git status command failed'),
      );
      expect(mockExec.calls.length, 3); // stash, dart, pop
      expect(
        mockExec.calls[2],
        MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
      );
      expect(mockEval.lastExecutable, 'git');
    });

    test(
      'handles failure of initial git stash command, pop succeeds, original exception seen',
      () async {
        final Exception stashException = Exception('Initial git stash failed');
        mockExec.addResponse(stashException); // git stash fails
        // dart script is not called
        mockExec.addResponse(0); // git stash pop (succeeds in finally)

        await expectLater(
          runGradleLockFilesCheck(
            execFn: mockExec.call,
            evalFn: mockEval.call,
            shouldPrintOutput: false,
          ),
          _throwsExceptionWithMessage('Initial git stash failed'),
        );
        expect(mockExec.calls.length, 2); // stash, pop
        expect(mockExec.calls[0], MockCall('git', const <String>['stash'], true, flutterDirectory.path));
        expect(
          mockExec.calls[1],
          MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
        );
        expect(mockEval.lastExecutable, isNull);
      },
    );

    test('throws ProcessException if git stash pop fails when try block succeeded', () async {
      mockExec.addResponse(0); // git stash
      mockExec.addResponse(0); // dart script
      mockExec.addResponse(1); // git stash pop fails (returns 1, canFail=false -> ProcessException)
      mockEval.nextResult = ''; // git status clean

      await expectLater(
        runGradleLockFilesCheck(
          execFn: mockExec.call,
          evalFn: mockEval.call,
          shouldPrintOutput: false,
        ),
        _throwsProcessExceptionWithCode(1),
      );
      expect(mockExec.calls.length, 3);
      expect(
        mockExec.calls[2],
        MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
      );
    });

    test(
      'throws ProcessException from git stash pop, masking try block lockfile exception',
      () async {
        mockExec.addResponse(0); // git stash
        mockExec.addResponse(0); // dart script
        mockExec.addResponse(
          1,
        ); // git stash pop fails (returns 1, canFail=false -> ProcessException)
        mockEval.nextResult = ' M path/to/file.lockfile\n'; // git status shows lockfile changes

        await expectLater(
          runGradleLockFilesCheck(
            execFn: mockExec.call,
            evalFn: mockEval.call,
            shouldPrintOutput: false,
          ),
          _throwsProcessExceptionWithCode(1), // Exception from pop should mask the lockfile one.
        );
        expect(mockExec.calls.length, 3);
        expect(
          mockExec.calls[2],
          MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
        );
      },
    );

    test(
      'throws ProcessException from git stash pop, masking try block dart script exception',
      () async {
        final Exception dartException = Exception('Dart script execution failed');
        mockExec.addResponse(0); // git stash
        mockExec.addResponse(dartException); // dart script fails
        mockExec.addResponse(
          1,
        ); // git stash pop fails (returns 1, canFail=false -> ProcessException)

        await expectLater(
          runGradleLockFilesCheck(
            execFn: mockExec.call,
            evalFn: mockEval.call,
            shouldPrintOutput: false,
          ),
          _throwsProcessExceptionWithCode(1), // Exception from pop should mask the dart script one.
        );
        expect(mockExec.calls.length, 3); // stash, dart, pop
        expect(
          mockExec.calls[2],
          MockCall('git', const <String>['stash', 'pop'], false, flutterDirectory.path),
        );
      },
    );
  });
}
