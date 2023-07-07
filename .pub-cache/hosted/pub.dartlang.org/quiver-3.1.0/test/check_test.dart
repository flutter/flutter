// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// TODO(cbracken): Eliminate once checkNotNull is deleted in Quiver 4.0.0.
// ignore_for_file: deprecated_member_use_from_same_package
library quiver.check_test;

import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {
  group('checkArgument', () {
    group('success', () {
      test('simple', () => checkArgument(true));
      test('null message', () => checkArgument(true, message: null));
      test('string message', () => checkArgument(true, message: 'foo'));
      test(
          'function message',
          () =>
              checkArgument(true, message: () => fail("Shouldn't be called")));
    });

    group('failure', () {
      void checkArgumentShouldFail(Function f, [String? expectedMessage]) {
        try {
          f();
          fail('Should have thrown an ArgumentError');
        } on ArgumentError catch (e) {
          expect(e.message, expectedMessage);
        }
      }

      test('no message',
          () => checkArgumentShouldFail(() => checkArgument(false)));

      test(
          'failure and simple string message',
          () => checkArgumentShouldFail(
              () => checkArgument(false, message: 'message'), 'message'));

      test(
          'failure and null message',
          () => checkArgumentShouldFail(
              () => checkArgument(false, message: null)));
      test(
          'failure and object as message',
          () => checkArgumentShouldFail(
              () => checkArgument(false, message: 5), '5'));
      test(
          'failure and message closure returns object',
          () => checkArgumentShouldFail(
              () => checkArgument(false, message: () => 5), '5'));

      test('failure and message function', () {
        int five = 5;
        checkArgumentShouldFail(
            () => checkArgument(false, message: () => 'I ate $five pies'),
            'I ate 5 pies');
      });
    });
  });

  group('checkState', () {
    group('success', () {
      test('simple', () => checkState(true));
      test('null message', () => checkState(true, message: null));
      test('string message', () => checkState(true, message: 'foo'));
      test('function message',
          () => checkState(true, message: () => fail("Shouldn't be called")));
    });

    group('failure', () {
      void checkStateShouldFail(Function f, [String? expectedMessage]) {
        expectedMessage ??= 'failed precondition';
        try {
          f();
          fail('Should have thrown a StateError');
        } on StateError catch (e) {
          expect(e.message, expectedMessage);
        }
      }

      test('no message', () => checkStateShouldFail(() => checkState(false)));

      test(
          'failure and simple string message',
          () => checkStateShouldFail(
              () => checkState(false, message: 'message'), 'message'));

      test('failure and null message',
          () => checkStateShouldFail(() => checkState(false, message: null)));
      test(
          'message closure returns null',
          () => checkStateShouldFail(
              () => checkState(false, message: () => null)));

      test('failure and message function', () {
        int five = 5;
        checkStateShouldFail(
            () => checkState(false, message: () => 'I ate $five pies'),
            'I ate 5 pies');
      });
    });
  });

  group('checkNotNull', () {
    group('success', () {
      test('simple', () => expect(checkNotNull(''), ''));
      test('string message', () => expect(checkNotNull(5, message: 'foo'), 5));
      test(
          'function message',
          () => expect(
              checkNotNull(true, message: () => fail("Shouldn't be called")),
              true));
    });

    group('failure', () {
      void checkNotNullShouldFail(Function f, [String? expectedMessage]) {
        expectedMessage ??= 'null pointer';
        try {
          f();
          fail('Should have thrown an ArgumentError');
        } on ArgumentError catch (e) {
          expect(e.message, expectedMessage);
        }
      }

      test(
          'no message', () => checkNotNullShouldFail(() => checkNotNull(null)));

      test(
          'simple failure message',
          () => checkNotNullShouldFail(
              () => checkNotNull(null, message: 'message'), 'message'));

      test(
          'null message',
          () =>
              checkNotNullShouldFail(() => checkNotNull(null, message: null)));

      test(
          'message closure returns null',
          () => checkNotNullShouldFail(
              () => checkNotNull(null, message: () => null)));

      test('failure and message function', () {
        int five = 5;
        checkNotNullShouldFail(
            () => checkNotNull(null, message: () => 'I ate $five pies'),
            'I ate 5 pies');
      });
    });
  });

  group('checkListIndex', () {
    test('success', () {
      checkListIndex(0, 1);
      checkListIndex(0, 1, message: () => fail("shouldn't be called"));
      checkListIndex(0, 2);
      checkListIndex(0, 2, message: () => fail("shouldn't be called"));
      checkListIndex(1, 2);
      checkListIndex(1, 2, message: () => fail("shouldn't be called"));
    });

    group('failure', () {
      void checkListIndexShouldFail(int index, int size,
          [message, String? expectedMessage]) {
        try {
          checkListIndex(index, size, message: message);
          fail('Should have thrown a RangeError');
        } on RangeError catch (e) {
          expect(
              e.message,
              expectedMessage ??
                  'index $index not valid for list of size $size');
        }
      }

      test('negative size', () => checkListIndexShouldFail(0, -1));
      test('negative index', () => checkListIndexShouldFail(-1, 1));
      test('index too high', () => checkListIndexShouldFail(1, 1));
      test('zero size', () => checkListIndexShouldFail(0, 0));

      test('with failure message',
          () => checkListIndexShouldFail(1, 1, 'foo', 'foo'));
      test('with failure message function', () {
        int five = 5;
        checkListIndexShouldFail(
            1, 1, () => 'I ate $five pies', 'I ate 5 pies');
      });
    });
  });
}
