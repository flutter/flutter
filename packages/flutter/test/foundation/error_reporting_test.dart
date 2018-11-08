// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

dynamic getAssertionErrorWithMessage() {
  try {
    assert(false, 'Message goes here.');
  } catch (e) {
    return e;
  }
  throw 'assert failed';
}

dynamic getAssertionErrorWithoutMessage() {
  try {
    assert(false);
  } catch (e) {
    return e;
  }
  throw 'assert failed';
}

dynamic getAssertionErrorWithLongMessage() {
  try {
    assert(false, 'word ' * 100);
  } catch (e) {
    return e;
  }
  throw 'assert failed';
}

Future<StackTrace> getSampleStack() async {
  return await Future<StackTrace>.sync(() => StackTrace.current);
}

Future<void> main() async {
  final List<String> console = <String>[];

  final StackTrace sampleStack = await getSampleStack();

  test('Error reporting - pretest', () async {
    expect(debugPrint, equals(debugPrintThrottled));
    debugPrint = (String message, { int wrapWidth }) {
      console.add(message);
    };
  });

  test('Error reporting - assert with message', () async {
    expect(console, isEmpty);
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: getAssertionErrorWithMessage(),
      stack: sampleStack,
      library: 'error handling test',
      context: 'testing the error handling logic',
      informationCollector: (StringBuffer information) {
        information.writeln('line 1 of extra information');
        information.writeln('line 2 of extra information\n'); // the double trailing newlines here are intentional
      },
    ));
    expect(console.join('\n'), matches(
      '^══╡ EXCEPTION CAUGHT BY ERROR HANDLING TEST ╞═══════════════════════════════════════════════════════\n'
      'The following assertion was thrown testing the error handling logic:\n'
      'Message goes here\\.\n'
      '\'[^\']+flutter/test/foundation/error_reporting_test\\.dart\': Failed assertion: line [0-9]+ pos [0-9]+: \'false\'\n'
      '\n'
      'Either the assertion indicates an error in the framework itself, or we should provide substantially '
      'more information in this error message to help you determine and fix the underlying cause\\.\n'
      'In either case, please report this assertion by filing a bug on GitHub:\n'
      '  https://github\\.com/flutter/flutter/issues/new\\?template=BUG\\.md\n'
      '\n'
      'When the exception was thrown, this was the stack:\n'
      '#0      getSampleStack\\.<anonymous closure> \\([^)]+flutter/test/foundation/error_reporting_test\\.dart:[0-9]+:[0-9]+\\)\n'
      '#2      getSampleStack \\([^)]+flutter/test/foundation/error_reporting_test\\.dart:[0-9]+:[0-9]+\\)\n'
      '<asynchronous suspension>\n' // TODO(ianh): https://github.com/flutter/flutter/issues/4021
      '#3      main \\([^)]+flutter/test/foundation/error_reporting_test\\.dart:[0-9]+:[0-9]+\\)\n'
      '(.+\n)+' // TODO(ianh): when fixing #4021, also filter out frames from the test infrastructure below the first call to our main()
      '\\(elided [0-9]+ frames from package dart:async\\)\n'
      '\n'
      'line 1 of extra information\n'
      'line 2 of extra information\n'
      '════════════════════════════════════════════════════════════════════════════════════════════════════\$',
    ));
    console.clear();
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: getAssertionErrorWithMessage(),
    ));
    expect(console.join('\n'), 'Another exception was thrown: Message goes here.');
    console.clear();
    FlutterError.resetErrorCount();
  });

  test('Error reporting - assert with long message', () async {
    expect(console, isEmpty);
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: getAssertionErrorWithLongMessage(),
    ));
    expect(console.join('\n'), matches(
      '^══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════\n'
      'The following assertion was thrown:\n'
      'word word word word word word word word word word word word word word word word word word word word '
      'word word word word word word word word word word word word word word word word word word word word '
      'word word word word word word word word word word word word word word word word word word word word '
      'word word word word word word word word word word word word word word word word word word word word '
      'word word word word word word word word word word word word word word word word word word word word\n'
      '\'[^\']+flutter/test/foundation/error_reporting_test\\.dart\': Failed assertion: line [0-9]+ pos [0-9]+: \'false\'\n'
      '\n'
      'Either the assertion indicates an error in the framework itself, or we should provide substantially '
      'more information in this error message to help you determine and fix the underlying cause\\.\n'
      'In either case, please report this assertion by filing a bug on GitHub:\n'
      '  https://github\\.com/flutter/flutter/issues/new\\?template=BUG\\.md\n'
      '════════════════════════════════════════════════════════════════════════════════════════════════════\$',
    ));
    console.clear();
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: getAssertionErrorWithLongMessage(),
    ));
    expect(
      console.join('\n'),
      'Another exception was thrown: '
      'word word word word word word word word word word word word word word word word word word word word '
      'word word word word word word word word word word word word word word word word word word word word '
      'word word word word word word word word word word word word word word word word word word word word '
      'word word word word word word word word word word word word word word word word word word word word '
      'word word word word word word word word word word word word word word word word word word word word'
    );
    console.clear();
    FlutterError.resetErrorCount();
  });

  test('Error reporting - assert with no message', () async {
    expect(console, isEmpty);
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: getAssertionErrorWithoutMessage(),
      stack: sampleStack,
      library: 'error handling test',
      context: 'testing the error handling logic',
      informationCollector: (StringBuffer information) {
        information.writeln('line 1 of extra information');
        information.writeln('line 2 of extra information\n'); // the double trailing newlines here are intentional
      },
    ));
    expect(console.join('\n'), matches(
      '^══╡ EXCEPTION CAUGHT BY ERROR HANDLING TEST ╞═══════════════════════════════════════════════════════\n'
      'The following assertion was thrown testing the error handling logic:\n'
      '\'[^\']+flutter/test/foundation/error_reporting_test\\.dart\': Failed assertion: line [0-9]+ pos [0-9]+: \'false\': is not true\\.\n'
      '\n'
      'Either the assertion indicates an error in the framework itself, or we should provide substantially '
      'more information in this error message to help you determine and fix the underlying cause\\.\n'
      'In either case, please report this assertion by filing a bug on GitHub:\n'
      '  https://github\\.com/flutter/flutter/issues/new\\?template=BUG\\.md\n'
      '\n'
      'When the exception was thrown, this was the stack:\n'
      '#0      getSampleStack\\.<anonymous closure> \\([^)]+flutter/test/foundation/error_reporting_test\\.dart:[0-9]+:[0-9]+\\)\n'
      '#2      getSampleStack \\([^)]+flutter/test/foundation/error_reporting_test\\.dart:[0-9]+:[0-9]+\\)\n'
      '<asynchronous suspension>\n' // TODO(ianh): https://github.com/flutter/flutter/issues/4021
      '#3      main \\([^)]+flutter/test/foundation/error_reporting_test\\.dart:[0-9]+:[0-9]+\\)\n'
      '(.+\n)+' // TODO(ianh): when fixing #4021, also filter out frames from the test infrastructure below the first call to our main()
      '\\(elided [0-9]+ frames from package dart:async\\)\n'
      '\n'
      'line 1 of extra information\n'
      'line 2 of extra information\n'
      '════════════════════════════════════════════════════════════════════════════════════════════════════\$',
    ));
    console.clear();
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: getAssertionErrorWithoutMessage(),
    ));
    expect(console.join('\n'), matches('Another exception was thrown: \'[^\']+flutter/test/foundation/error_reporting_test\\.dart\': Failed assertion: line [0-9]+ pos [0-9]+: \'false\': is not true\\.'));
    console.clear();
    FlutterError.resetErrorCount();
  });

  test('Error reporting - NoSuchMethodError', () async {
    expect(console, isEmpty);
    final dynamic exception = NoSuchMethodError(5, #foo, <dynamic>[2, 4], null); // ignore: deprecated_member_use
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: exception,
    ));
    expect(console.join('\n'), matches(
      '^══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════\n'
      'The following NoSuchMethodError was thrown:\n'
      'Receiver: 5\n'
      'Tried calling: foo = 2, 4\n'
      '════════════════════════════════════════════════════════════════════════════════════════════════════\$',
    ));
    console.clear();
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: exception,
    ));
    expect(console.join('\n'), 'Another exception was thrown: NoSuchMethodError: Receiver: 5');
    console.clear();
    FlutterError.resetErrorCount();
  });

  test('Error reporting - NoSuchMethodError', () async {
    expect(console, isEmpty);
    FlutterError.dumpErrorToConsole(const FlutterErrorDetails(
      exception: 'hello',
    ));
    expect(console.join('\n'), matches(
      '^══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════\n'
      'The following message was thrown:\n'
      'hello\n'
      '════════════════════════════════════════════════════════════════════════════════════════════════════\$',
    ));
    console.clear();
    FlutterError.dumpErrorToConsole(const FlutterErrorDetails(
      exception: 'hello again',
    ));
    expect(console.join('\n'), 'Another exception was thrown: hello again');
    console.clear();
    FlutterError.resetErrorCount();
  });

  test('Error reporting - posttest', () async {
    expect(console, isEmpty);
    debugPrint = debugPrintThrottled;
  });
}
