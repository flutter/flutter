// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
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

    var test = await runTest(['test.dart'], reporter: 'github');
    expect(test.stdout, emitsThrough(contains('0 tests passed')));
    await test.shouldExit(79);
  });

  test('runs several successful tests and reports when each completes', () {
    return _expectReport('''
        test('success 1', () {});
        test('success 2', () {});
        test('success 3', () {});''', '''
        ::group::✅ success 1
        ::endgroup::
        ::group::✅ success 2
        ::endgroup::
        ::group::✅ success 3
        ::endgroup::
        🎉 3 tests passed.''');
  });

  test('includes the platform name when multiple platforms are ran', () {
    return _expectReportLines('''
        test('success 1', () {});''', [
      '::group::✅ [VM] success 1',
      '::endgroup::',
      '::group::✅ [Chrome] success 1',
      '::endgroup::',
      '🎉 2 tests passed.',
    ], args: [
      '-p',
      'vm,chrome'
    ]);
  });

  test('runs several failing tests and reports when each fails', () {
    return _expectReport('''
        test('failure 1', () => throw TestFailure('oh no'));
        test('failure 2', () => throw TestFailure('oh no'));
        test('failure 3', () => throw TestFailure('oh no'));''', '''
        ::group::❌ failure 1 (failed)
        oh no
        test.dart 6:33  main.<fn>
        ::endgroup::
        ::group::❌ failure 2 (failed)
        oh no
        test.dart 7:33  main.<fn>
        ::endgroup::
        ::group::❌ failure 3 (failed)
        oh no
        test.dart 8:33  main.<fn>
        ::endgroup::
        ::error::0 tests passed, 3 failed.''');
  });

  test('includes the full stack trace with --verbose-trace', () async {
    await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("failure", () => throw "oh no");
}
''').create();

    var test =
        await runTest(['--verbose-trace', 'test.dart'], reporter: 'github');
    expect(test.stdout, emitsThrough(contains('dart:async')));
    await test.shouldExit(1);
  });

  test('runs failing tests along with successful tests', () {
    return _expectReport('''
        test('failure 1', () => throw TestFailure('oh no'));
        test('success 1', () {});
        test('failure 2', () => throw TestFailure('oh no'));
        test('success 2', () {});''', '''
        ::group::❌ failure 1 (failed)
        oh no
        test.dart 6:33  main.<fn>
        ::endgroup::
        ::group::✅ success 1
        ::endgroup::
        ::group::❌ failure 2 (failed)
        oh no
        test.dart 8:33  main.<fn>
        ::endgroup::
        ::group::✅ success 2
        ::endgroup::
        ::error::2 tests passed, 2 failed.''');
  });

  test('always prints the full test name', () {
    return _expectReport(
      '''
        test(
           'really gosh dang long test name. Even longer than that. No, yet '
               'longer. A little more... okay, that should do it.',
           () {});''',
      '''
        ::group::✅ really gosh dang long test name. Even longer than that. No, yet longer. A little more... okay, that should do it.
        ::endgroup::''',
      useContains: true,
    );
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
        ::group::❌ failures (failed)
        first error
        test.dart 10:34  main.<fn>.<fn>
        second error
        test.dart 11:34  main.<fn>.<fn>
        third error
        test.dart 12:34  main.<fn>.<fn>
        ::endgroup::
        ::group::✅ wait
        ::endgroup::
        ::error::1 test passed, 1 failed.''');
  });

  group('print:', () {
    test('handles multiple prints', () {
      return _expectReport(
        '''
        test('test', () {
          print("one");
          print("two");
          print("three");
          print("four");
        });''',
        '''
        ::group::✅ test
        one
        two
        three
        four
        ::endgroup::''',
        useContains: true,
      );
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
        ::group::✅ test
        ::endgroup::
        one
        two
        three
        four
        ::group::✅ wait
        ::endgroup::
        🎉 2 tests passed.''');
    });
  });

  group('skip:', () {
    test('displays skipped tests', () {
      return _expectReport('''
          test('skip 1', () {}, skip: true);
          test('skip 2', () {}, skip: true);
          test('skip 3', () {}, skip: true);''', '''
          ::group::❎ skip 1 (skipped)
          ::endgroup::
          ::group::❎ skip 2 (skipped)
          ::endgroup::
          ::group::❎ skip 3 (skipped)
          ::endgroup::
          🎉 0 tests passed, 3 skipped.''');
    });

    test('displays a skipped group', () {
      return _expectReport('''
          group('skip', () {
            test('test 1', () {});
            test('test 2', () {});
            test('test 3', () {});
          }, skip: true);''', '''
          ::group::❎ skip test 1 (skipped)
          ::endgroup::
          ::group::❎ skip test 2 (skipped)
          ::endgroup::
          ::group::❎ skip test 3 (skipped)
          ::endgroup::
          🎉 0 tests passed, 3 skipped.''');
    });

    test('runs skipped tests along with successful tests', () {
      return _expectReport('''
          test('skip 1', () {}, skip: true);
          test('success 1', () {});
          test('skip 2', () {}, skip: true);
          test('success 2', () {});''', '''
          ::group::❎ skip 1 (skipped)
          ::endgroup::
          ::group::✅ success 1
          ::endgroup::
          ::group::❎ skip 2 (skipped)
          ::endgroup::
          ::group::✅ success 2
          ::endgroup::
          🎉 2 tests passed, 2 skipped.''');
    });

    test('runs skipped tests along with successful and failing tests', () {
      return _expectReport('''
          test('failure 1', () => throw TestFailure('oh no'));
          test('skip 1', () {}, skip: true);
          test('success 1', () {});
          test('failure 2', () => throw TestFailure('oh no'));
          test('skip 2', () {}, skip: true);
          test('success 2', () {});''', '''
          ::group::❌ failure 1 (failed)
          oh no
          test.dart 6:35  main.<fn>
          ::endgroup::
          ::group::❎ skip 1 (skipped)
          ::endgroup::
          ::group::✅ success 1
          ::endgroup::
          ::group::❌ failure 2 (failed)
          oh no
          test.dart 9:35  main.<fn>
          ::endgroup::
          ::group::❎ skip 2 (skipped)
          ::endgroup::
          ::group::✅ success 2
          ::endgroup::
          ::error::2 tests passed, 2 failed, 2 skipped.''');
    });

    test('displays the skip reason if available', () {
      return _expectReport('''
          test('skip 1', () {}, skip: 'some reason');
          test('skip 2', () {}, skip: 'or another');''', '''
          ::group::❎ skip 1 (skipped)
          Skip: some reason
          ::endgroup::
          ::group::❎ skip 2 (skipped)
          Skip: or another
          ::endgroup::
          🎉 0 tests passed, 2 skipped.''');
    });
  });

  test('loadSuite, setUpAll, and tearDownAll hidden if no content', () {
    return _expectReport('''
          group('one', () {
            setUpAll(() {/* nothing to do here */});
            tearDownAll(() {/* nothing to do here */});
            test('test 1', () {});
          });''', '''
          ::group::✅ one test 1
          ::endgroup::
          🎉 1 test passed.''');
  });

  test('setUpAll and tearDownAll show when they have content', () {
    return _expectReport('''
          group('one', () {
            setUpAll(() { print('one'); });
            tearDownAll(() { print('two'); });
            test('test 1', () {});
          });''', '''
          ::group::✅ one (setUpAll)
          one
          ::endgroup::
          ::group::✅ one test 1
          ::endgroup::
          ::group::✅ one (tearDownAll)
          two
          ::endgroup::
          🎉 1 test passed.''');
  });
}

/// Expects exactly [expected] to appear in the test output.
///
/// If [useContains] is passed, then the output only must contain [expected].
Future<void> _expectReport(
  String tests,
  String expected, {
  List<String> args = const [],
  bool useContains = false,
}) async {
  expected = expected.split('\n').map(_unindent).join('\n');

  var actual = (await _reportLines(tests, args)).join('\n');

  expect(actual, useContains ? contains(expected) : equals(expected));
}

/// Expects all of [expected] lines to appear in the test output, but additional
/// output is allowed.
Future<void> _expectReportLines(
  String tests,
  List<String> expected, {
  List<String> args = const [],
}) async {
  expected = [for (var line in expected) _unindent(line)];
  var actual = await _reportLines(tests, args);
  expect(actual, containsAllInOrder(expected));
}

/// All the output lines from running [tests].
Future<List<String>> _reportLines(String tests, List<String> args) async {
  await d.file('test.dart', '''
    import 'dart:async';

    import 'package:test/test.dart';

    void main() {
$tests
    }
  ''').create();

  var test = await runTest([
    'test.dart',
    ...args,
  ], reporter: 'github');
  await test.shouldExit();

  var stdoutLines = await test.stdoutStream().toList();
  return stdoutLines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

/// Removes all leading space from [line].
String _unindent(String line) => line.trimLeft();
