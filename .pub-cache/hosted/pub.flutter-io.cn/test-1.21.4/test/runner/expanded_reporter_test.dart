// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:async';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('reports when no tests are run', () async {
    await d.file('test.dart', 'void main() {}').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('No tests ran.')));
    await test.shouldExit(79);
  });

  test('runs several successful tests and reports when each completes', () {
    return _expectReport('''
        test('success 1', () {});
        test('success 2', () {});
        test('success 3', () {});''', '''
        +0: success 1
        +1: success 2
        +2: success 3
        +3: All tests passed!''');
  });

  test('runs several failing tests and reports when each fails', () {
    return _expectReport('''
        test('failure 1', () => throw TestFailure('oh no'));
        test('failure 2', () => throw TestFailure('oh no'));
        test('failure 3', () => throw TestFailure('oh no'));''', '''
        +0: failure 1
        +0 -1: failure 1 [E]
          oh no
          test.dart 6:33  main.<fn>

        +0 -1: failure 2
        +0 -2: failure 2 [E]
          oh no
          test.dart 7:33  main.<fn>

        +0 -2: failure 3
        +0 -3: failure 3 [E]
          oh no
          test.dart 8:33  main.<fn>

        +0 -3: Some tests failed.''');
  });

  test('includes the full stack trace with --verbose-trace', () async {
    await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("failure", () => throw "oh no");
}
''').create();

    var test = await runTest(['--verbose-trace', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('dart:async')));
    await test.shouldExit(1);
  });

  test('runs failing tests along with successful tests', () {
    return _expectReport('''
        test('failure 1', () => throw TestFailure('oh no'));
        test('success 1', () {});
        test('failure 2', () => throw TestFailure('oh no'));
        test('success 2', () {});''', '''
        +0: failure 1
        +0 -1: failure 1 [E]
          oh no
          test.dart 6:33  main.<fn>

        +0 -1: success 1
        +1 -1: failure 2
        +1 -2: failure 2 [E]
          oh no
          test.dart 8:33  main.<fn>

        +1 -2: success 2
        +2 -2: Some tests failed.''');
  });

  test('always prints the full test name', () {
    return _expectReport('''
        test(
           'really gosh dang long test name. Even longer than that. No, yet '
               'longer. A little more... okay, that should do it.',
           () {});''', '''
        +0: really gosh dang long test name. Even longer than that. No, yet longer. A little more... okay, that should do it.
        +1: All tests passed!''');
  });

  test('gracefully handles multiple test failures in a row', () {
    return _expectReport('''
        // This completer ensures that the test isolate isn't killed until all
        // errors have been thrown.
        var completer = Completer();
        test('failures', () {
          Future.microtask(() => throw 'first error');
          Future.microtask(() => throw 'second error');
          Future.microtask(() => throw 'third error');
          Future.microtask(completer.complete);
        });
        test('wait', () => completer.future);''', '''
        +0: failures
        +0 -1: failures [E]
          first error
          test.dart 10:34  main.<fn>.<fn>
          ===== asynchronous gap ===========================
          dart:async       new Future.microtask
          test.dart 10:18  main.<fn>

          second error
          test.dart 11:34  main.<fn>.<fn>
          ===== asynchronous gap ===========================
          dart:async       new Future.microtask
          test.dart 11:18  main.<fn>

          third error
          test.dart 12:34  main.<fn>.<fn>
          ===== asynchronous gap ===========================
          dart:async       new Future.microtask
          test.dart 12:18  main.<fn>

        +0 -1: wait
        +1 -1: Some tests failed.''');
  });

  group('print:', () {
    test('handles multiple prints', () {
      return _expectReport('''
        test('test', () {
          print("one");
          print("two");
          print("three");
          print("four");
        });''', '''
        +0: test
        one
        two
        three
        four
        +1: All tests passed!''');
    });

    test('handles a print after the test completes', () {
      return _expectReport('''
        // This completer ensures that the test isolate isn't killed until all
        // prints have happened.
        var testDone = Completer();
        var waitStarted = Completer();
        test('test', () async {
          waitStarted.future.then((_) {
            Future(() => print("one"));
            Future(() => print("two"));
            Future(() => print("three"));
            Future(() => print("four"));
            Future(testDone.complete);
          });
        });

        test('wait', () {
          waitStarted.complete();
          return testDone.future;
        });''', '''
        +0: test
        +1: wait
        +1: test
        one
        two
        three
        four
        +2: All tests passed!''');
    });

    test('interleaves prints and errors', () {
      return _expectReport('''
        // This completer ensures that the test isolate isn't killed until all
        // prints have happened.
        var completer = Completer();
        test('test', () {
          scheduleMicrotask(() {
            print("three");
            print("four");
            throw "second error";
          });

          scheduleMicrotask(() {
            print("five");
            print("six");
            completer.complete();
          });

          print("one");
          print("two");
          throw "first error";
        });

        test('wait', () => completer.future);''', '''
        +0: test
        one
        two
        +0 -1: test [E]
          first error
          test.dart 24:11  main.<fn>

        three
        four
          second error
          test.dart 13:13  main.<fn>.<fn>
          ===== asynchronous gap ===========================
          dart:async       scheduleMicrotask
          test.dart 10:11  main.<fn>

        five
        six
        +0 -1: wait
        +1 -1: Some tests failed.''');
    });
  });

  group('skip:', () {
    test('displays skipped tests separately', () {
      return _expectReport('''
          test('skip 1', () {}, skip: true);
          test('skip 2', () {}, skip: true);
          test('skip 3', () {}, skip: true);''', '''
          +0: skip 1
          +0 ~1: skip 2
          +0 ~2: skip 3
          +0 ~3: All tests skipped.''');
    });

    test('displays a skipped group', () {
      return _expectReport('''
          group('skip', () {
            test('test 1', () {});
            test('test 2', () {});
            test('test 3', () {});
          }, skip: true);''', '''
          +0: skip test 1
          +0 ~1: skip test 2
          +0 ~2: skip test 3
          +0 ~3: All tests skipped.''');
    });

    test('runs skipped tests along with successful tests', () {
      return _expectReport('''
          test('skip 1', () {}, skip: true);
          test('success 1', () {});
          test('skip 2', () {}, skip: true);
          test('success 2', () {});''', '''
          +0: skip 1
          +0 ~1: success 1
          +1 ~1: skip 2
          +1 ~2: success 2
          +2 ~2: All tests passed!''');
    });

    test('runs skipped tests along with successful and failing tests', () {
      return _expectReport('''
          test('failure 1', () => throw TestFailure('oh no'));
          test('skip 1', () {}, skip: true);
          test('success 1', () {});
          test('failure 2', () => throw TestFailure('oh no'));
          test('skip 2', () {}, skip: true);
          test('success 2', () {});''', '''
          +0: failure 1
          +0 -1: failure 1 [E]
            oh no
            test.dart 6:35  main.<fn>

          +0 -1: skip 1
          +0 ~1 -1: success 1
          +1 ~1 -1: failure 2
          +1 ~1 -2: failure 2 [E]
            oh no
            test.dart 9:35  main.<fn>

          +1 ~1 -2: skip 2
          +1 ~2 -2: success 2
          +2 ~2 -2: Some tests failed.''');
    });

    test('displays the skip reason if available', () {
      return _expectReport('''
          test('skip 1', () {}, skip: 'some reason');
          test('skip 2', () {}, skip: 'or another');''', '''
          +0: skip 1
            Skip: some reason
          +0 ~1: skip 2
            Skip: or another
          +0 ~2: All tests skipped.''');
    });

    test('runs skipped tests with --run-skipped', () {
      return _expectReport('''
          test('skip 1', () {}, skip: 'some reason');
          test('skip 2', () {}, skip: 'or another');''', '''
          +0: skip 1
          +1: skip 2
          +2: All tests passed!''', args: ['--run-skipped']);
    });
  });

  test('Directs users to enable stack trace chaining if disabled', () async {
    await _expectReport(
        '''test('failure 1', () => throw TestFailure('oh no'));''', '''
        +0: failure 1
        +0 -1: failure 1 [E]
          oh no
          test.dart 6:25  main.<fn>

        +0 -1: Some tests failed.

        Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
        For example, 'dart test --chain-stack-traces'.''',
        chainStackTraces: false);
  });
}

Future<void> _expectReport(String tests, String expected,
    {List<String> args = const [], bool chainStackTraces = true}) async {
  await d.file('test.dart', '''
    import 'dart:async';

    import 'package:test/test.dart';

    void main() {
$tests
    }
  ''').create();

  var test = await runTest([
    'test.dart',
    if (chainStackTraces) '--chain-stack-traces',
    ...args,
  ]);
  await test.shouldExit();

  var stdoutLines = await test.stdoutStream().toList();

  // Remove excess trailing whitespace and trim off timestamps.
  var actual = stdoutLines.map((line) {
    if (line.startsWith('  ') || line.isEmpty) return line.trimRight();
    return line.trim().replaceFirst(RegExp('^[0-9]{2}:[0-9]{2} '), '');
  }).join('\n');

  // Un-indent the expected string.
  var indentation = expected.indexOf(RegExp('[^ ]'));
  expected = expected.split('\n').map((line) {
    if (line.isEmpty) return line;
    return line.substring(indentation);
  }).join('\n');

  expect(actual, equals(expected));
}
