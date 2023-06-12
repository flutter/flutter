// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('an error causes the run to fail', () async {
    await d.file('test.dart', r'''
        import 'package:test/test.dart';

        void main() {
          tearDownAll(() => throw "oh no");

          test("test", () {});
        }
        ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('-1: (tearDownAll) [E]')));
    expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
    await test.shouldExit(1);
  });

  test("doesn't run if no tests in the group are selected", () async {
    await d.file('test.dart', r'''
        import 'package:test/test.dart';

        void main() {
          group("with tearDownAll", () {
            tearDownAll(() => throw "oh no");

            test("test", () {});
          });

          group("without tearDownAll", () {
            test("test", () {});
          });
        }
        ''').create();

    var test = await runTest(['test.dart', '--name', 'without']);
    expect(test.stdout, neverEmits(contains('(tearDownAll)')));
    await test.shouldExit(0);
  });

  test("doesn't run if no tests in the group match the platform", () async {
    await d.file('test.dart', r'''
        import 'package:test/test.dart';

        void main() {
          group("group1", () {
            tearDownAll(() => throw "oh no");

            test("with", () {}, testOn: "browser");
          });

          group("group2", () {
            test("without", () {});
          });
        }
        ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, neverEmits(contains('(tearDownAll)')));
    await test.shouldExit(0);
  });

  test("doesn't run if the group doesn't match the platform", () async {
    await d.file('test.dart', r'''
        import 'package:test/test.dart';

        void main() {
          group("group1", () {
            tearDownAll(() => throw "oh no");

            test("with", () {});
          }, testOn: "browser");

          group("group2", () {
            test("without", () {});
          });
        }
        ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, neverEmits(contains('(tearDownAll)')));
    await test.shouldExit(0);
  });
}
