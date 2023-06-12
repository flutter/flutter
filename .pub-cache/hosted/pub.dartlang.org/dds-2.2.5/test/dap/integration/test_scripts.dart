// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

/// A marker used in some test scripts/tests for where to set breakpoints.
const breakpointMarker = '// BREAKPOINT';

/// A simple empty Dart script that should run with no output and no errors.
const emptyProgram = '''
  void main(List<String> args) {}
''';

/// A simple async Dart script that when stopped at the line of '// BREAKPOINT'
/// will contain SDK frames in the call stack.
const sdkStackFrameProgram = '''
  void main() {
    [0].where((i) {
      return i == 0; $breakpointMarker
    }).toList();
  }
''';

/// A simple Dart script that registers a simple service extension that returns
/// its params and waits until it is called before exiting.
const serviceExtensionProgram = '''
  import 'dart:async';
  import 'dart:convert';
  import 'dart:developer';

  void main(List<String> args) async {
    // Using a completer here causes the VM to quit when the extension is called
    // so use a flag.
    // https://github.com/dart-lang/sdk/issues/47279
    var wasCalled = false;
    registerExtension('ext.service.extension', (method, params) async {
      wasCalled = true;
      return ServiceExtensionResponse.result(jsonEncode(params));
    });
    while (!wasCalled) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
''';

/// A simple Dart script that prints its arguments.
const simpleArgPrintingProgram = r'''
  void main(List<String> args) async {
    print('Hello!');
    print('World!');
    print('args: $args');
  }
''';

/// A simple Dart script that prints to stderr without throwing/terminating.
///
/// The output will contain stack traces include both the supplied file and
/// package URIs.
String stderrPrintingProgram(Uri fileUri, Uri packageUri) {
  return '''
  import 'dart:io';
  import '$packageUri';

  void main(List<String> args) async {
    stderr.writeln('Start');
    stderr.writeln('#0      main ($fileUri:1:2)');
    stderr.writeln('#1      main2 ($packageUri:1:2)');
    stderr.write('End');
  }
''';
}

/// Returns a simple Dart script that prints the provided string repeatedly.
String stringPrintingProgram(String text) {
  // jsonEncode the string to get it into a quoted/escaped form that can be
  // embedded in the string.
  final encodedTextString = jsonEncode(text);
  return '''
  import 'dart:async';

  main() async {
    Timer.periodic(Duration(milliseconds: 10), (_) => printSomething());
  }

  void printSomething() {
    print($encodedTextString);
  }
''';
}

/// A simple async Dart script that when stopped at the line of '// BREAKPOINT'
/// will contain multiple stack frames across some async boundaries.
const simpleAsyncProgram = '''
  import 'dart:async';

  Future<void> main() async {
    await one();
  }

  Future<void> one() async {
    await two();
  }

  Future<void> two() async {
    await three();
  }

  Future<void> three() async {
    await Future.delayed(const Duration(microseconds: 1));
    four();
  }

  void four() {
    print('!'); $breakpointMarker
  }
''';

/// A simple Dart script that should run with no errors and contains a comment
/// marker '// BREAKPOINT' for use in tests that require stopping at a breakpoint
/// but require no other context.
const simpleBreakpointProgram = '''
  void main(List<String> args) async {
    print('Hello!'); $breakpointMarker
  }
''';

/// A simple Dart script that has a breakpoint and an exception used for
/// testing whether breakpoints and exceptions are being paused on (for example
/// during detach where they should not).
const simpleBreakpointAndThrowProgram = '''
  void main(List<String> args) async {
    print('Hello!'); $breakpointMarker
    throw 'error';
  }
''';

/// A simple Dart script that throws an error and catches it in user code.
const simpleCaughtErrorProgram = r'''
  void main(List<String> args) async {
    try {
      throw 'error';
    } catch (e) {
      print('Caught!');
    }
  }
''';

/// A simple package:test script that has a single group named 'group' with
/// tests named 'passing' and 'failing' respectively.
///
/// The 'passing' test contains a [breakpointMarker].
const simpleTestProgram = '''
  import 'package:test/test.dart';

  void main() {
    group('group 1', () {
      test('passing test', () {
        expect(1, equals(1)); $breakpointMarker
      });
      test('failing test', () {
        expect(1, equals(2));
      });
    });
  }
''';

/// Matches for the expected output of [simpleTestProgram].
final simpleTestProgramExpectedOutput = [
  // First test
  '✓ group 1 passing test',
  // Second test
  'Expected: <2>',
  '  Actual: <1>',
  // These lines contain paths, so just check the non-path parts.
  allOf(startsWith('package:test_api'), endsWith('expect')),
  endsWith('main.<fn>.<fn>'),
  '✖ group 1 failing test',
  // Exit
  '',
  'Exited (1).',
];

/// A simple Dart script that throws in user code.
const simpleThrowingProgram = r'''
  void main(List<String> args) async {
    throw 'error';
  }
''';

/// A marker used in some test scripts/tests for where to expected steps.
const stepMarker = '// STEP';
