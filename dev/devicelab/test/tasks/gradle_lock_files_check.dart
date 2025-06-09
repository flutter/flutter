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
    test('succeeds', () async {
      mockEval.nextResult = '';
      mockExec.addResponse(0);
      mockExec.addResponse(0);

      await runGradleLockFilesCheck(
        execFn: mockExec.call,
        evalFn: mockEval.call,
        shouldPrintOutput: false,
      );

      expect(mockExec.calls, <MockCall>[
        MockCall(
          _dartCommand,
          <String>[_scriptFilePath, '--no-gradle-generation'],
          false,
          flutterDirectory.path,
        ),
        MockCall(
          'git',
          <String>['stash', 'pop'],
          true,
          flutterDirectory.path,
        ),
      ]);

      expect(mockEval.lastExecutable, 'git');
      expect(mockEval.lastArguments,
          <String>['status', '--porcelain', '--untracked-files=all']);
      expect(mockEval.lastCanFail, false);
    });

    test(
        'throws Exception for gradle changes when there are lockfile modifications', () async {
      mockEval.nextResult = ' M  path/to/some.lockfile';
      mockExec.addResponse(0);
      mockExec.addResponse(0);

      await expectLater(
            () =>
            runGradleLockFilesCheck(
              execFn: mockExec.call,
              evalFn: mockEval.call,
              shouldPrintOutput: false,
            ),
        _throwsExceptionWithMessage(
          'Gradle lockfiles are not up to date, or new/modified lockfiles are not staged.',
        ),
      );

      expect(mockExec.calls, <MockCall>[
        MockCall(
          _dartCommand,
          <String>[_scriptFilePath, '--no-gradle-generation'],
          false,
          flutterDirectory.path,
        ),
        MockCall(
          'git',
          <String>['stash', 'pop'],
          true,
          flutterDirectory.path,
        ),
      ]);

      expect(mockEval.lastExecutable, 'git');
      expect(mockEval.lastArguments,
          <String>['status', '--porcelain', '--untracked-files=all']);
    });

    group('finally block behavior', () {
      test(
          'rethrows ProcessException when git stash pop fails with "No such file or directory"', () async {
        mockEval.nextResult = '';
        mockExec.addResponse(0);
        final noSuchFileException = ProcessException(
            'git', <String>['stash', 'pop'],
            'No such file or directory, errno = 2', 2
        );
        mockExec.addResponse(noSuchFileException);

        await expectLater(
              () =>
              runGradleLockFilesCheck(
                execFn: mockExec.call,
                evalFn: mockEval.call,
                shouldPrintOutput: false,
              ),
          throwsA(
              isA<ProcessException>()
                  .having((ProcessException e) => e.executable, 'executable',
                  'git')
                  .having((ProcessException e) => e.arguments, 'arguments',
                  <String>['stash', 'pop'])
                  .having((ProcessException e) => e.message, 'message',
                  contains('No such file or directory'))
                  .having((ProcessException e) => e.errorCode, 'errorCode', 2)
          ),
        );

        expect(mockExec.calls, <MockCall>[
          MockCall(
              _dartCommand, <String>[_scriptFilePath, '--no-gradle-generation'],
              false, flutterDirectory.path),
          MockCall(
              'git', <String>['stash', 'pop'], true, flutterDirectory.path),
        ]);
        expect(mockEval.lastExecutable, 'git');
        expect(mockEval.lastArguments,
            <String>['status', '--porcelain', '--untracked-files=all']);
      });

      test(
          'rethrows ProcessException when git restore . fails with "No such file or directory"', () async {
        mockEval.nextResult = 'No local changes to save';

        mockExec.addResponse(0);
        final noSuchFileException = ProcessException(
            'git', <String>['restore', '.'],
            'No such file or directory, errno = 2', 2
        );
        mockExec.addResponse(noSuchFileException);

        await expectLater(
              () =>
              runGradleLockFilesCheck(
                execFn: mockExec.call,
                evalFn: mockEval.call,
                shouldPrintOutput: false,
              ),
          throwsA(
              isA<ProcessException>()
                  .having((ProcessException e) => e.executable, 'executable',
                  'git')
                  .having((ProcessException e) => e.arguments, 'arguments',
                  <String>['restore', '.'])
                  .having((ProcessException e) => e.message, 'message',
                  contains('No such file or directory'))
                  .having((ProcessException e) => e.errorCode, 'errorCode', 2)
          ),
        );

        expect(mockExec.calls, <MockCall>[
          MockCall(
              _dartCommand, <String>[_scriptFilePath, '--no-gradle-generation'],
              false, flutterDirectory.path),
          MockCall(
              'git', <String>['restore', '.'], true, flutterDirectory.path),
        ]);
        expect(mockEval.lastExecutable, 'git');
        expect(mockEval.lastArguments,
            <String>['status', '--porcelain', '--untracked-files=all']);
      });

      test(
          'original try block exception propagates if git stash pop fails gracefully', () async {
        mockEval.nextResult = 'No local changes to save\n  M  some.lockfile';
        mockExec.addResponse(0);
        mockExec.addResponse(1);

        await expectLater(
              () =>
              runGradleLockFilesCheck(
                execFn: mockExec.call,
                evalFn: mockEval.call,
                shouldPrintOutput: false,
              ),
          _throwsExceptionWithMessage('Gradle lockfiles are not up to date'),
        );

        expect(mockExec.calls, <MockCall>[
          MockCall(
              _dartCommand, <String>[_scriptFilePath, '--no-gradle-generation'],
              false, flutterDirectory.path),
          MockCall(
              'git', <String>['restore', '.'], true, flutterDirectory.path),
        ]);
        expect(mockEval.lastExecutable, 'git');
        expect(mockEval.lastArguments,
            <String>['status', '--porcelain', '--untracked-files=all']);
      });
    });
  });
}
