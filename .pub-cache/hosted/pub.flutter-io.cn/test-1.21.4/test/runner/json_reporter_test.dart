// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';
import 'json_reporter_utils.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('runs several successful tests and reports when each completes', () {
    return _expectReport('''
      test('success 1', () {});
      test('success 2', () {});
      test('success 3', () {});
    ''', [
      [
        suiteJson(0),
        testStartJson(1, 'loading test.dart', groupIDs: []),
        testDoneJson(1, hidden: true),
      ],
      [
        groupJson(2, testCount: 3),
        testStartJson(3, 'success 1', line: 6, column: 7),
        testDoneJson(3),
        testStartJson(4, 'success 2', line: 7, column: 7),
        testDoneJson(4),
        testStartJson(5, 'success 3', line: 8, column: 7),
        testDoneJson(5),
      ]
    ], doneJson());
  });

  test('runs several failing tests and reports when each fails', () {
    return _expectReport('''
      test('failure 1', () => throw TestFailure('oh no'));
      test('failure 2', () => throw TestFailure('oh no'));
      test('failure 3', () => throw TestFailure('oh no'));
    ''', [
      [
        suiteJson(0),
        testStartJson(1, 'loading test.dart', groupIDs: []),
        testDoneJson(1, hidden: true),
      ],
      [
        groupJson(2, testCount: 3),
        testStartJson(3, 'failure 1', line: 6, column: 7),
        errorJson(3, 'oh no', isFailure: true),
        testDoneJson(3, result: 'failure'),
        testStartJson(4, 'failure 2', line: 7, column: 7),
        errorJson(4, 'oh no', isFailure: true),
        testDoneJson(4, result: 'failure'),
        testStartJson(5, 'failure 3', line: 8, column: 7),
        errorJson(5, 'oh no', isFailure: true),
        testDoneJson(5, result: 'failure'),
      ]
    ], doneJson(success: false));
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
        await runTest(['--verbose-trace', 'test.dart'], reporter: 'json');
    expect(test.stdout, emitsThrough(contains('dart:async')));
    await test.shouldExit(1);
  });

  test('runs failing tests along with successful tests', () {
    return _expectReport('''
      test('failure 1', () => throw TestFailure('oh no'));
      test('success 1', () {});
      test('failure 2', () => throw TestFailure('oh no'));
      test('success 2', () {});
    ''', [
      [
        suiteJson(0),
        testStartJson(1, 'loading test.dart', groupIDs: []),
        testDoneJson(1, hidden: true),
      ],
      [
        groupJson(2, testCount: 4),
        testStartJson(3, 'failure 1', line: 6, column: 7),
        errorJson(3, 'oh no', isFailure: true),
        testDoneJson(3, result: 'failure'),
        testStartJson(4, 'success 1', line: 7, column: 7),
        testDoneJson(4),
        testStartJson(5, 'failure 2', line: 8, column: 7),
        errorJson(5, 'oh no', isFailure: true),
        testDoneJson(5, result: 'failure'),
        testStartJson(6, 'success 2', line: 9, column: 7),
        testDoneJson(6),
      ]
    ], doneJson(success: false));
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
      test('wait', () => completer.future);
    ''', [
      [
        suiteJson(0),
        testStartJson(1, 'loading test.dart', groupIDs: []),
        testDoneJson(1, hidden: true),
      ],
      [
        groupJson(2, testCount: 2),
        testStartJson(3, 'failures', line: 9, column: 7),
        errorJson(3, 'first error'),
        errorJson(3, 'second error'),
        errorJson(3, 'third error'),
        testDoneJson(3, result: 'error'),
        testStartJson(4, 'wait', line: 15, column: 7),
        testDoneJson(4),
      ]
    ], doneJson(success: false));
  });

  test('gracefully handles a test failing after completion', () {
    return _expectReport('''
      // These completers ensure that the first test won't fail until the second
      // one is running, and that the test isolate isn't killed until all errors
      // have been thrown.
      var waitStarted = Completer();
      var testDone = Completer();
      test('failure', () {
        waitStarted.future.then((_) {
          Future.microtask(testDone.complete);
          throw 'oh no';
        });
      });
      test('wait', () {
        waitStarted.complete();
        return testDone.future;
      });
    ''', [
      [
        suiteJson(0),
        testStartJson(1, 'loading test.dart', groupIDs: []),
        testDoneJson(1, hidden: true),
      ],
      [
        groupJson(2, testCount: 2),
        testStartJson(3, 'failure', line: 11, column: 7),
        testDoneJson(3),
        testStartJson(4, 'wait', line: 17, column: 7),
        errorJson(3, 'oh no'),
        errorJson(
            3,
            'This test failed after it had already completed. Make sure to '
            'use [expectAsync]\n'
            'or the [completes] matcher when testing async code.'),
        testDoneJson(4),
      ]
    ], doneJson(success: false));
  });

  test('reports each test in its proper groups', () {
    return _expectReport('''
      group('group 1', () {
        group('.2', () {
          group('.3', () {
            test('success', () {});
          });
        });

        test('success1', () {});
        test('success2', () {});
      });
    ''', [
      [
        suiteJson(0),
        testStartJson(1, 'loading test.dart', groupIDs: []),
        testDoneJson(1, hidden: true),
      ],
      [
        groupJson(2, testCount: 3),
        groupJson(3,
            name: 'group 1', parentID: 2, testCount: 3, line: 6, column: 7),
        groupJson(4, name: 'group 1 .2', parentID: 3, line: 7, column: 9),
        groupJson(5, name: 'group 1 .2 .3', parentID: 4, line: 8, column: 11),
        testStartJson(6, 'group 1 .2 .3 success',
            groupIDs: [2, 3, 4, 5], line: 9, column: 13),
        testDoneJson(6),
        testStartJson(7, 'group 1 success1',
            groupIDs: [2, 3], line: 13, column: 9),
        testDoneJson(7),
        testStartJson(8, 'group 1 success2',
            groupIDs: [2, 3], line: 14, column: 9),
        testDoneJson(8),
      ]
    ], doneJson());
  });

  group('print:', () {
    test('handles multiple prints', () {
      return _expectReport('''
        test('test', () {
          print("one");
          print("two");
          print("three");
          print("four");
        });
      ''', [
        [
          suiteJson(0),
          testStartJson(1, 'loading test.dart', groupIDs: []),
          testDoneJson(1, hidden: true),
        ],
        [
          groupJson(2),
          testStartJson(3, 'test', line: 6, column: 9),
          printJson(3, 'one'),
          printJson(3, 'two'),
          printJson(3, 'three'),
          printJson(3, 'four'),
          testDoneJson(3),
        ]
      ], doneJson());
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
        });
      ''', [
        [
          suiteJson(0),
          testStartJson(1, 'loading test.dart', groupIDs: []),
          testDoneJson(1, hidden: true),
        ],
        [
          groupJson(2, testCount: 2),
          testStartJson(3, 'test', line: 10, column: 9),
          testDoneJson(3),
          testStartJson(4, 'wait', line: 20, column: 9),
          printJson(3, 'one'),
          printJson(3, 'two'),
          printJson(3, 'three'),
          printJson(3, 'four'),
          testDoneJson(4),
        ]
      ], doneJson());
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

        test('wait', () => completer.future);
      ''', [
        [
          suiteJson(0),
          testStartJson(1, 'loading test.dart', groupIDs: []),
          testDoneJson(1, hidden: true),
        ],
        [
          groupJson(2, testCount: 2),
          testStartJson(3, 'test', line: 9, column: 9),
          printJson(3, 'one'),
          printJson(3, 'two'),
          errorJson(3, 'first error'),
          printJson(3, 'three'),
          printJson(3, 'four'),
          errorJson(3, 'second error'),
          printJson(3, 'five'),
          printJson(3, 'six'),
          testDoneJson(3, result: 'error'),
          testStartJson(4, 'wait', line: 27, column: 9),
          testDoneJson(4),
        ]
      ], doneJson(success: false));
    });
  });

  group('skip:', () {
    test('reports skipped tests', () {
      return _expectReport('''
        test('skip 1', () {}, skip: true);
        test('skip 2', () {}, skip: true);
        test('skip 3', () {}, skip: true);
      ''', [
        [
          suiteJson(0),
          testStartJson(1, 'loading test.dart', groupIDs: []),
          testDoneJson(1, hidden: true),
        ],
        [
          groupJson(2, testCount: 3),
          testStartJson(3, 'skip 1', skip: true, line: 6, column: 9),
          testDoneJson(3, skipped: true),
          testStartJson(4, 'skip 2', skip: true, line: 7, column: 9),
          testDoneJson(4, skipped: true),
          testStartJson(5, 'skip 3', skip: true, line: 8, column: 9),
          testDoneJson(5, skipped: true),
        ]
      ], doneJson());
    });

    test('reports skipped groups', () {
      return _expectReport('''
        group('skip', () {
          test('success 1', () {});
          test('success 2', () {});
          test('success 3', () {});
        }, skip: true);
      ''', [
        [
          suiteJson(0),
          testStartJson(1, 'loading test.dart', groupIDs: []),
          testDoneJson(1, hidden: true),
        ],
        [
          groupJson(2, testCount: 3),
          groupJson(3,
              name: 'skip',
              parentID: 2,
              skip: true,
              testCount: 3,
              line: 6,
              column: 9),
          testStartJson(4, 'skip success 1',
              groupIDs: [2, 3], skip: true, line: 7, column: 11),
          testDoneJson(4, skipped: true),
          testStartJson(5, 'skip success 2',
              groupIDs: [2, 3], skip: true, line: 8, column: 11),
          testDoneJson(5, skipped: true),
          testStartJson(6, 'skip success 3',
              groupIDs: [2, 3], skip: true, line: 9, column: 11),
          testDoneJson(6, skipped: true),
        ]
      ], doneJson());
    });

    test('reports the skip reason if available', () {
      return _expectReport('''
        test('skip 1', () {}, skip: 'some reason');
        test('skip 2', () {}, skip: 'or another');
      ''', [
        [
          suiteJson(0),
          testStartJson(1, 'loading test.dart', groupIDs: []),
          testDoneJson(1, hidden: true),
        ],
        [
          groupJson(2, testCount: 2),
          testStartJson(3, 'skip 1', skip: 'some reason', line: 6, column: 9),
          printJson(3, 'Skip: some reason', type: 'skip'),
          testDoneJson(3, skipped: true),
          testStartJson(4, 'skip 2', skip: 'or another', line: 7, column: 9),
          printJson(4, 'Skip: or another', type: 'skip'),
          testDoneJson(4, skipped: true),
        ]
      ], doneJson());
    });

    test('runs skipped tests with --run-skipped', () {
      return _expectReport(
          '''
        test('skip 1', () {}, skip: 'some reason');
        test('skip 2', () {}, skip: 'or another');
      ''',
          [
            [
              suiteJson(0),
              testStartJson(1, 'loading test.dart', groupIDs: []),
              testDoneJson(1, hidden: true),
            ],
            [
              groupJson(2, testCount: 2),
              testStartJson(3, 'skip 1', line: 6, column: 9),
              testDoneJson(3),
              testStartJson(4, 'skip 2', line: 7, column: 9),
              testDoneJson(4),
            ]
          ],
          doneJson(),
          args: ['--run-skipped']);
    });
  });

  group('reports line and column numbers for', () {
    test('the first call to setUpAll()', () {
      return _expectReport('''
        setUpAll(() {});
        setUpAll(() {});
        setUpAll(() {});
        test('success', () {});
      ''', [
        [
          suiteJson(0),
          testStartJson(1, 'loading test.dart', groupIDs: []),
          testDoneJson(1, hidden: true),
        ],
        [
          groupJson(2, testCount: 1),
          testStartJson(3, '(setUpAll)', line: 6, column: 9),
          testDoneJson(3, hidden: true),
          testStartJson(4, 'success', line: 9, column: 9),
          testDoneJson(4),
          testStartJson(5, '(tearDownAll)'),
          testDoneJson(5, hidden: true),
        ]
      ], doneJson());
    });

    test('the first call to tearDownAll()', () {
      return _expectReport('''
        tearDownAll(() {});
        tearDownAll(() {});
        tearDownAll(() {});
        test('success', () {});
      ''', [
        [
          testStartJson(1, 'loading test.dart', groupIDs: []),
          testDoneJson(1, hidden: true),
        ],
        [
          suiteJson(0),
          groupJson(2, testCount: 1),
          testStartJson(3, 'success', line: 9, column: 9),
          testDoneJson(3),
          testStartJson(4, '(tearDownAll)', line: 6, column: 9),
          testDoneJson(4, hidden: true),
        ]
      ], doneJson());
    });

    test('a test compiled to JS', () {
      return _expectReport(
          '''
        test('success', () {});
      ''',
          [
            [
              suiteJson(0, platform: 'chrome'),
              testStartJson(1, 'compiling test.dart', groupIDs: []),
              printJson(
                  1,
                  isA<String>().having((s) => s.split('\n'), 'lines',
                      contains(startsWith('Compiled')))),
              testDoneJson(1, hidden: true),
            ],
            [
              groupJson(2, testCount: 1),
              testStartJson(3, 'success', line: 6, column: 9),
              testDoneJson(3),
            ]
          ],
          doneJson(),
          args: ['-p', 'chrome']);
    }, tags: ['chrome'], skip: 'https://github.com/dart-lang/test/issues/872');

    test('the root suite if applicable', () {
      return _expectReport(
          '''
      customTest('success 1', () {});
      test('success 2', () {});
    ''',
          [
            [
              suiteJson(0),
              testStartJson(1, 'loading test.dart', groupIDs: []),
              testDoneJson(1, hidden: true),
            ],
            [
              groupJson(2, testCount: 2),
              testStartJson(3, 'success 1',
                  line: 3,
                  column: 60,
                  url: p.toUri(p.join(d.sandbox, 'common.dart')).toString(),
                  rootColumn: 7,
                  rootLine: 7,
                  rootUrl: p.toUri(p.join(d.sandbox, 'test.dart')).toString()),
              testDoneJson(3),
              testStartJson(4, 'success 2', line: 8, column: 7),
              testDoneJson(4),
            ]
          ],
          doneJson(),
          externalLibraries: {
            'common.dart': '''
import 'package:test/test.dart';

void customTest(String name, dynamic Function() testFn) => test(name, testFn);
''',
          });
    });
  });

  test(
      "doesn't report line and column information for a test compiled to JS "
      'with --js-trace', () {
    return _expectReport(
        '''
      test('success', () {});
    ''',
        [
          [
            suiteJson(0, platform: 'chrome'),
            testStartJson(1, 'compiling test.dart', groupIDs: []),
            printJson(
                1,
                isA<String>().having((s) => s.split('\n'), 'lines',
                    contains(startsWith('Compiled')))),
            testDoneJson(1, hidden: true),
          ],
          [
            groupJson(2, testCount: 1),
            testStartJson(3, 'success'),
            testDoneJson(3),
          ],
        ],
        doneJson(),
        args: ['-p', 'chrome', '--js-trace']);
  }, tags: ['chrome']);
}

/// Asserts that the tests defined by [tests] produce the JSON events in
/// [expected].
///
/// If [externalLibraries] are provided it should be a map of relative file
/// paths to contents. All libraries will be added as imports to the test, and
/// files will be created for them.
Future<void> _expectReport(String tests,
    List<List<Object /*Map|Matcher*/ >> expected, Map<Object, Object> done,
    {List<String> args = const [],
    Map<String, String> externalLibraries = const {}}) async {
  var testContent = StringBuffer('''
import 'dart:async';

import 'package:test/test.dart';

''');
  for (var entry in externalLibraries.entries) {
    testContent.writeln("import '${entry.key}';");
    await d.file(entry.key, entry.value).create();
  }
  testContent
    ..writeln('void main() {')
    ..writeln(tests)
    ..writeln('}');

  await d.file('test.dart', testContent.toString()).create();

  var test = await runTest(['test.dart', '--chain-stack-traces', ...args],
      reporter: 'json');
  await test.shouldExit();

  var stdoutLines = await test.stdoutStream().toList();
  return expectJsonReport(stdoutLines, test.pid, expected, done);
}
