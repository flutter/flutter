// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Object getAssertionErrorWithMessage() {
  try {
    assert(false, 'Message goes here.');
  } catch (e) {
    return e;
  }
  throw 'assert failed';
}

Object getAssertionErrorWithoutMessage() {
  try {
    assert(false);
  } catch (e) {
    return e;
  }
  throw 'assert failed';
}

Object getAssertionErrorWithLongMessage() {
  try {
    assert(false, 'word ' * 100);
  } catch (e) {
    return e;
  }
  throw 'assert failed';
}

Future<StackTrace> getSampleStack() async {
  return Future<StackTrace>.sync(() => StackTrace.current);
}

Future<void> main() async {
  final List<String?> console = <String?>[];

  final StackTrace sampleStack = await getSampleStack();

  setUp(() async {
    expect(debugPrint, equals(debugPrintThrottled));
    debugPrint = (String? message, { int? wrapWidth }) {
      console.add(message);
    };
  });

  tearDown(() async {
    expect(console, isEmpty);
    debugPrint = debugPrintThrottled;
  });

  test('Error reporting - assert with message', () async {
    expect(console, isEmpty);
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: getAssertionErrorWithMessage(),
      stack: sampleStack,
      library: 'error handling test',
      context: ErrorDescription('testing the error handling logic'),
      informationCollector: () sync* {
        yield ErrorDescription('line 1 of extra information');
        yield ErrorHint('line 2 of extra information\n');
      },
    ));
    expect(console.join('\n'), matches(
      r'^══╡ EXCEPTION CAUGHT BY ERROR HANDLING TEST ╞═══════════════════════════════════════════════════════\n'
      r'The following assertion was thrown testing the error handling logic:\n'
      r'Message goes here\.\n'
      r"'[^']+flutter/test/foundation/error_reporting_test\.dart':\n"
      r"Failed assertion: line [0-9]+ pos [0-9]+: 'false'\n"
      r'\n'
      r'When the exception was thrown, this was the stack:\n'
      r'#0      getSampleStack\.<anonymous closure> \([^)]+flutter/test/foundation/error_reporting_test\.dart:[0-9]+:[0-9]+\)\n'
      r'#2      getSampleStack \([^)]+flutter/test/foundation/error_reporting_test\.dart:[0-9]+:[0-9]+\)\n'
      r'#3      main \([^)]+flutter/test/foundation/error_reporting_test\.dart:[0-9]+:[0-9]+\)\n'
      r'(.+\n)+' // TODO(ianh): when fixing #4021, also filter out frames from the test infrastructure below the first call to our main()
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
      r'^══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════\n'
      r'The following assertion was thrown:\n'
      r'word word word word word word word word word word word word word word word word word word word word\n'
      r'word word word word word word word word word word word word word word word word word word word word\n'
      r'word word word word word word word word word word word word word word word word word word word word\n'
      r'word word word word word word word word word word word word word word word word word word word word\n'
      r'word word word word word word word word word word word word word word word word word word word word\n'
      r"'[^']+flutter/test/foundation/error_reporting_test\.dart':\n"
      r"Failed assertion: line [0-9]+ pos [0-9]+: 'false'\n"
      r'════════════════════════════════════════════════════════════════════════════════════════════════════$',
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
      'word word word word word word word word word word word word word word word word word word word word',
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
      context: ErrorDescription('testing the error handling logic'),
      informationCollector: () sync* {
        yield ErrorDescription('line 1 of extra information');
        yield ErrorDescription('line 2 of extra information\n'); // the trailing newlines here are intentional
      },
    ));
    expect(console.join('\n'), matches(
      r'^══╡ EXCEPTION CAUGHT BY ERROR HANDLING TEST ╞═══════════════════════════════════════════════════════\n'
      r'The following assertion was thrown testing the error handling logic:\n'
      r"'[^']+flutter/test/foundation/error_reporting_test\.dart':[\n ]"
      r"Failed[\n ]assertion:[\n ]line[\n ][0-9]+[\n ]pos[\n ][0-9]+:[\n ]'false':[\n ]is[\n ]not[\n ]true\.\n"
      r'\n'
      r'When the exception was thrown, this was the stack:\n'
      r'#0      getSampleStack\.<anonymous closure> \([^)]+flutter/test/foundation/error_reporting_test\.dart:[0-9]+:[0-9]+\)\n'
      r'#2      getSampleStack \([^)]+flutter/test/foundation/error_reporting_test\.dart:[0-9]+:[0-9]+\)\n'
      r'#3      main \([^)]+flutter/test/foundation/error_reporting_test\.dart:[0-9]+:[0-9]+\)\n'
      r'(.+\n)+' // TODO(ianh): when fixing #4021, also filter out frames from the test infrastructure below the first call to our main()
    ));
    console.clear();
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: getAssertionErrorWithoutMessage(),
    ));
    expect(console.join('\n'), matches(r"Another exception was thrown: '[^']+flutter/test/foundation/error_reporting_test\.dart': Failed assertion: line [0-9]+ pos [0-9]+: 'false': is not true\."));
    console.clear();
    FlutterError.resetErrorCount();
  });

  test('Error reporting - NoSuchMethodError', () async {
    expect(console, isEmpty);
    final Object exception = NoSuchMethodError.withInvocation(5,
        Invocation.method(#foo, <dynamic>[2, 4]));

    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: exception,
    ));
    expect(console.join('\n'), matches(
      r'^══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════\n'
      r'The following NoSuchMethodError was thrown:\n'
      r'int has no foo method accepting arguments \(_, _\)\n'
      r'════════════════════════════════════════════════════════════════════════════════════════════════════$',
    ));
    console.clear();
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: exception,
    ));
    expect(console.join('\n'),
      'Another exception was thrown: NoSuchMethodError: int has no foo method accepting arguments (_, _)');
    console.clear();
    FlutterError.resetErrorCount();
  });

  test('Error reporting - NoSuchMethodError', () async {
    expect(console, isEmpty);
    FlutterError.dumpErrorToConsole(const FlutterErrorDetails(
      exception: 'hello',
    ));
    expect(console.join('\n'), matches(
      r'^══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════\n'
      r'The following message was thrown:\n'
      r'hello\n'
      r'════════════════════════════════════════════════════════════════════════════════════════════════════$',
    ));
    console.clear();
    FlutterError.dumpErrorToConsole(const FlutterErrorDetails(
      exception: 'hello again',
    ));
    expect(console.join('\n'), 'Another exception was thrown: hello again');
    console.clear();
    FlutterError.resetErrorCount();
  });

  // Regression test for https://github.com/flutter/flutter/issues/62223
  test('Error reporting - empty stack', () async {
    expect(console, isEmpty);
    FlutterError.dumpErrorToConsole(FlutterErrorDetails(
      exception: 'exception - empty stack',
      stack: StackTrace.fromString(''),
    ));
    expect(console.join('\n'), matches(
      r'^══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════\n'
      r'The following message was thrown:\n'
      r'exception - empty stack\n'
      r'\n'
      r'When the exception was thrown, this was the stack:\n'
      r'...\n'
      r'════════════════════════════════════════════════════════════════════════════════════════════════════$',
    ));
    console.clear();
  });
}
