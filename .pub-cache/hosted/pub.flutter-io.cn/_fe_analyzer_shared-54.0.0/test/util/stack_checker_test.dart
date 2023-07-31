// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:core' as type;
import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/util/stack_checker.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';

final Uri dummyUri = Uri.parse('dummy:test');
const int dummyOffset = -1;

class StackCheckerTester with StackChecker {
  final List<Object?> stack;

  StackCheckerTester(List<Object?> stack) : stack = stack.reversed.toList();

  @override
  Never internalProblem(Message message, int charOffset, Uri uri) {
    throw message;
  }

  @override
  Object? lookupStack(int index) {
    return stack[stack.length - index - 1];
  }

  @override
  int get stackHeight => stack.length;
}

class ValueKinds {
  static const ValueKind bool = const SingleValueKind<type.bool>();
  static const ValueKind int = const SingleValueKind<type.int>();
  static const ValueKind String = const SingleValueKind<type.String>();
}

void testBase(
    {required List<Object?> stack,
    required int base,
    String? expectedMessage}) {
  print('--- stack=${stack}, base=$base ---\n');
  try {
    StackCheckerTester(stack)
        .checkStackBaseStateForAssert(dummyUri, dummyOffset, base);
    if (expectedMessage != null) {
      throw 'Expected failure on stack=${stack}, base=$base';
    }
  } on Message catch (message) {
    print(message.problemMessage);
    if (expectedMessage != null) {
      if (message.problemMessage != expectedMessage) {
        throw 'Unexpected message:\n'
            'Expected:\n\n$expectedMessage\n\n'
            'Actual:\n\n${message.problemMessage}';
      }
    } else {
      throw 'Unexpected failure on stack=${stack}, base=$base';
    }
  }
}

void testStack(
    {required List<Object?> stack,
    required List<ValueKind> expected,
    int? base,
    String? expectedMessage}) {
  print('--- stack=${stack}, '
      'expected=$expected, base=$base ---\n');
  try {
    StackCheckerTester(stack)
        .checkStackStateForAssert(dummyUri, dummyOffset, expected, base: base);
    if (expectedMessage != null) {
      throw 'Expected failure on stack=${stack}, '
          'expected=$expected, base=$base';
    }
  } on Message catch (message) {
    print(message.problemMessage);
    if (expectedMessage != null) {
      if (message.problemMessage != expectedMessage) {
        throw 'Unexpected message:\n'
            'Expected:\n\n$expectedMessage\n\n'
            'Actual:\n\n${message.problemMessage}';
      }
    } else {
      throw 'Unexpected failure on stack=${stack}, '
          'expected=$expected, base=$base';
    }
  }
}

main() {
  // Empty stack.
  testBase(stack: [], base: 0);

  // More elements than needed 0.
  testBase(stack: ['foo', 0], base: 0);

  // More elements than needed 0.
  testBase(stack: ['foo', 0], base: 1);

  // More elements than needed 0.
  testBase(stack: ['foo', 0], base: 2);

  // Too few elements 1.
  testBase(
      stack: [],
      base: -1,
      expectedMessage: '''
StackCheckerTester failure
Too few elements on stack. Expected 1, found 0.''');

  // Too few elements 2.
  testBase(
      stack: ['foo', 0],
      base: -2,
      expectedMessage: '''
StackCheckerTester failure
Too few elements on stack. Expected 4, found 2.''');

  // Empty stack.
  testStack(stack: [], expected: []);

  // More elements than needed 0.
  testStack(stack: ['foo', 0], expected: []);

  // More elements than needed 1.
  testStack(stack: ['foo', 0], expected: [ValueKinds.String]);

  // Exactly elements needed.
  testStack(stack: ['foo', 0], expected: [ValueKinds.String, ValueKinds.int]);

  // Too few on stack 1.
  testStack(stack: [], expected: [ValueKinds.String], expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 1, found 0.
   0: String                                                      *---
   1: ---                                                          ---
''');

  // Too few on stack 2.
  testStack(
      stack: [],
      expected: [ValueKinds.String, ValueKinds.int],
      expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 2, found 0.
   0: String                                                      *---
   1: int                                                         *---
   2: ---                                                          ---
''');

  // Too few on stack 3.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.String, ValueKinds.int, ValueKinds.bool],
      expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 3, found 2.
   0: String                                                       foo (String)
   1: int                                                          0 (int)
   2: bool                                                        *---
   3: ---                                                          ---
''');

  // Wrong kind 1.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.int, ValueKinds.int],
      expectedMessage: '''
StackCheckerTester failure
 Unexpected element kind(s).
   0: int                                                         *foo (String)
   1: int                                                          0 (int)
   2: ---                                                          ---
''');

  // Wrong kind 2.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.String, ValueKinds.String],
      expectedMessage: '''
StackCheckerTester failure
 Unexpected element kind(s).
   0: String                                                       foo (String)
   1: String                                                      *0 (int)
   2: ---                                                          ---
''');

  // Wrong kind 3.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.int, ValueKinds.String],
      expectedMessage: '''
StackCheckerTester failure
 Unexpected element kind(s).
   0: int                                                         *foo (String)
   1: String                                                      *0 (int)
   2: ---                                                          ---
''');

  // Too few and wrong kind.
  testStack(
      stack: ['foo'],
      expected: [ValueKinds.int, ValueKinds.String],
      expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 2, found 1.
 Unexpected element kind(s).
   0: int                                                         *foo (String)
   1: String                                                      *---
   2: ---                                                          ---
''');

  // Expect empty.
  testStack(stack: [], expected: [], base: 0);

  // Too few on stack 1.
  testStack(
      stack: [],
      expected: [ValueKinds.String],
      base: 0,
      expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 1, found 0.
   *: String                                                      *---
>  0: ---                                                          ---
''');

  // Too few on stack 2.
  testStack(
      stack: [],
      expected: [ValueKinds.String, ValueKinds.int],
      base: 0,
      expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 2, found 0.
   *: String                                                      *---
   *: int                                                         *---
>  0: ---                                                          ---
''');

  // Too few on stack 3.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.String, ValueKinds.int, ValueKinds.bool],
      base: 0,
      expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 3, found 2.
 Unexpected element kind(s).
   *: String                                                      *---
   0: int                                                         *foo (String)
   1: bool                                                        *0 (int)
>  2: ---                                                          ---
''');

  // Wrong kind 1.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.int, ValueKinds.int],
      base: 0,
      expectedMessage: '''
StackCheckerTester failure
 Unexpected element kind(s).
   0: int                                                         *foo (String)
   1: int                                                          0 (int)
>  2: ---                                                          ---
''');

  // Wrong kind 2.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.String, ValueKinds.String],
      base: 0,
      expectedMessage: '''
StackCheckerTester failure
 Unexpected element kind(s).
   0: String                                                       foo (String)
   1: String                                                      *0 (int)
>  2: ---                                                          ---
''');

  // Wrong kind 3.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.int, ValueKinds.String],
      base: 0,
      expectedMessage: '''
StackCheckerTester failure
 Unexpected element kind(s).
   0: int                                                         *foo (String)
   1: String                                                      *0 (int)
>  2: ---                                                          ---
''');

  // Too many 1, expect empty.
  testStack(
      stack: ['foo', 0],
      expected: [],
      base: 0,
      expectedMessage: '''
StackCheckerTester failure
 Too many elements on stack. Expected 0, found 2.
   0:                                                              foo (String)
   1:                                                              0 (int)
>  2: ---                                                          ---
''');

  // Too many 2.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.String],
      base: 0,
      expectedMessage: '''
StackCheckerTester failure
 Too many elements on stack. Expected 1, found 2.
 Unexpected element kind(s).
   0:                                                              foo (String)
   1: String                                                      *0 (int)
>  2: ---                                                          ---
''');

  // Matching stack, relative base.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.String, ValueKinds.int],
      base: 0);

  // Expect empty, relative base.
  testStack(stack: ['foo', 0], expected: [], base: 2);

  // More elements but matching stack, relative base, 1.
  testStack(stack: ['foo', 0, true], expected: [ValueKinds.String], base: 2);

  // More elements but matching stack, relative base, 2.
  testStack(
      stack: ['foo', 0, true, 'bar'],
      expected: [ValueKinds.String, ValueKinds.int],
      base: 2);

  // Too few 1, relative base.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.String],
      base: 2,
      expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 1, found 0.
   *: String                                                      *---
>  0: ---                                                          foo (String)
   1: ---                                                          0 (int)
''');

  // Too few 2, relative base.
  testStack(
      stack: ['foo', 0],
      expected: [ValueKinds.String, ValueKinds.int],
      base: 2,
      expectedMessage: '''
StackCheckerTester failure
 Too few elements on stack. Expected 2, found 0.
   *: String                                                      *---
   *: int                                                         *---
>  0: ---                                                          foo (String)
   1: ---                                                          0 (int)
''');

  // Too many 1, relative base.
  testStack(
      stack: ['foo', 0, true, 'bar'],
      expected: [ValueKinds.String],
      base: 2,
      expectedMessage: '''
StackCheckerTester failure
 Too many elements on stack. Expected 1, found 2.
 Unexpected element kind(s).
   0:                                                              foo (String)
   1: String                                                      *0 (int)
>  2: ---                                                          true (bool)
   3: ---                                                          bar (String)
''');

  // Too many 2, relative base.
  testStack(
      stack: ['foo', 0, true, 'bar', 42],
      expected: [ValueKinds.String, ValueKinds.int],
      base: 2,
      expectedMessage: '''
StackCheckerTester failure
 Too many elements on stack. Expected 2, found 3.
 Unexpected element kind(s).
   0:                                                              foo (String)
   1: String                                                      *0 (int)
   2: int                                                         *true (bool)
>  3: ---                                                          bar (String)
   4: ---                                                          42 (int)
''');
}
