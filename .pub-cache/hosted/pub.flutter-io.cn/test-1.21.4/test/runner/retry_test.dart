// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('respects --no-retry flag with retry option', () async {
    await d.file('test.dart', '''
          import 'dart:async';

          import 'package:test/test.dart';

          var attempt = 0;
          void main() {
            test("eventually passes", () {
               attempt++;
               if(attempt <= 1 ) {
                 throw TestFailure("oh no");
               }
            }, retry: 1);
          }
          ''').create();

    var test = await runTest(['test.dart', '--no-retry']);
    expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
    await test.shouldExit(1);
  });

  test('respects --no-retry flag with @Retry declaration', () async {
    await d.file('test.dart', '''
          @Retry(3)

          import 'dart:async';

          import 'package:test/test.dart';

          var attempt = 0;
          void main() {
            test("eventually passes", () {
               attempt++;
               if(attempt <= 1 ) {
                 throw TestFailure("oh no");
               }
            });
          }
          ''').create();

    var test = await runTest(['test.dart', '--no-retry']);
    expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
    await test.shouldExit(1);
  });

  test('respects top-level @Retry declarations', () async {
    await d.file('test.dart', '''
          @Retry(3)

          import 'dart:async';

          import 'package:test/test.dart';

          var attempt = 0;
          void main() {
            test("failure", () {
               attempt++;
               if(attempt <= 3) {
                 throw TestFailure("oh no");
               }
            });
          }
          ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  });

  test('respects group retry declarations', () async {
    await d.file('test.dart', '''
          import 'dart:async';

          import 'package:test/test.dart';

          var attempt = 0;
          void main() {
            group("retry", () {
              test("failure", () {
                 attempt++;
                 if(attempt <= 3) {
                   throw TestFailure("oh no");
                 }
              });
             }, retry: 3);
          }
          ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  });

  test('tests are not retried after they have already been reported successful',
      () async {
    await d.file('test.dart', '''
              import 'dart:async';

              import 'package:test/test.dart';

              void main() {
                var completer1 = Completer();
                var completer2 = Completer();
                test("first", () {
                  completer1.future.then((_) {
                    completer2.complete();
                    throw "oh no";
                  });
                }, retry: 2);

                test("second", () async {
                  completer1.complete();
                  await completer2.future;
                });
              }
          ''').create();

    var test = await runTest(['test.dart']);
    expect(
        test.stdout,
        emitsThrough(
            contains('This test failed after it had already completed')));
    await test.shouldExit(1);
  });

  group('retries tests', () {
    test('and eventually passes for valid tests', () async {
      await d.file('test.dart', '''
              import 'dart:async';

              import 'package:test/test.dart';

              var attempt = 0;
              void main() {
                test("eventually passes", () {
                 attempt++;
                 if(attempt <= 2) {
                   throw TestFailure("oh no");
                 }
                }, retry: 2);
              }
          ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('and ignores previous errors', () async {
      await d.file('test.dart', '''
              import 'dart:async';

              import 'package:test/test.dart';

              var attempt = 0;
              Completer completer = Completer();
              void main() {
                test("failure", () async {
                  attempt++;
                  if (attempt == 1) {
                    completer.future.then((_) => throw 'some error');
                    throw TestFailure("oh no");
                  }
                  completer.complete(null);
                  await Future((){});
                }, retry: 1);
              }
          ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('and eventually fails for invalid tests', () async {
      await d.file('test.dart', '''
              import 'dart:async';

              import 'package:test/test.dart';

              void main() {
                test("failure", () {
                 throw TestFailure("oh no");
                }, retry: 2);
              }
          ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
      await test.shouldExit(1);
    });

    test('only after a failure', () async {
      await d.file('test.dart', '''
              import 'dart:async';

              import 'package:test/test.dart';

              var attempt = 0;
              void main() {
                test("eventually passes", () {
                attempt++;
                if (attempt != 2){
                 throw TestFailure("oh no");
                }
                }, retry: 5);
          }
          ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });
  });
}
