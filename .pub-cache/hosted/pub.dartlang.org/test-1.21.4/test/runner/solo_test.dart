// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('only runs the tests marked as solo', () async {
    await d.file('test.dart', '''
          import 'dart:async';

          import 'package:test/test.dart';

          void main() {
            test("passes", () {
              expect(true, isTrue);
            }, solo: true);
            test("failed", () {
              throw 'some error';
            });
          }
          ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('+1 ~1: All tests passed!')));
    await test.shouldExit(0);
  });

  test('only runs groups marked as solo', () async {
    await d.file('test.dart', '''
          import 'dart:async';

          import 'package:test/test.dart';

          void main() {
            group('solo', () {
              test("first pass", () {
                expect(true, isTrue);
              });
              test("second pass", () {
                expect(true, isTrue);
              });
            }, solo: true);
            group('no solo', () {
              test("failure", () {
                throw 'some error';
              });
              test("another failure", () {
                throw 'some error';
              });
            });
          }
          ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('+2 ~1: All tests passed!')));
    await test.shouldExit(0);
  });
}
