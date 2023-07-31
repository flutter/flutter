// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_core/src/util/exit_codes.dart' as exit_codes;
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

final _success = '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {});
}
''';

final _failure = '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("failure", () => throw TestFailure("oh no"));
}
''';

final _asyncFailure = '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("failure", () async {
    await Future(() {}).then((_) {
      throw 'oh no';
    });
  });
}
''';

final _defaultConcurrency = math.max(1, Platform.numberOfProcessors ~/ 2);

final _usage = '''
Usage: dart test [files or directories...]

-h, --help                            Show this usage information.
    --version                         Show the package:test version.

Selecting Tests:
-n, --name                            A substring of the name of the test to run.
                                      Regular expression syntax is supported.
                                      If passed multiple times, tests must match all substrings.
-N, --plain-name                      A plain-text substring of the name of the test to run.
                                      If passed multiple times, tests must match all substrings.
-t, --tags                            Run only tests with all of the specified tags.
                                      Supports boolean selector syntax.
-x, --exclude-tags                    Don't run tests with any of the specified tags.
                                      Supports boolean selector syntax.
    --[no-]run-skipped                Run skipped tests instead of skipping them.

Running Tests:
-p, --platform                        The platform(s) on which to run the tests.
                                      $_browsers
-P, --preset                          The configuration preset(s) to use.
-j, --concurrency=<threads>           The number of concurrent test suites run.
                                      (defaults to "$_defaultConcurrency")
    --total-shards                    The total number of invocations of the test runner being run.
    --shard-index                     The index of this test runner invocation (of --total-shards).
    --pub-serve=<port>                The port of a pub serve instance serving "test/".
    --timeout                         The default test timeout. For example: 15s, 2x, none
                                      (defaults to "30s")
    --ignore-timeouts                 Ignore all timeouts (useful if debugging)
    --pause-after-load                Pause for debugging before any tests execute.
                                      Implies --concurrency=1, --debug, and --ignore-timeouts.
                                      Currently only supported for browser tests.
    --debug                           Run the VM and Chrome tests in debug mode.
    --coverage=<directory>            Gather coverage and output it to the specified directory.
                                      Implies --debug.
    --[no-]chain-stack-traces         Use chained stack traces to provide greater exception details
                                      especially for asynchronous code. It may be useful to disable
                                      to provide improved test performance but at the cost of
                                      debuggability.
    --no-retry                        Don't rerun tests that have retry set.
    --use-data-isolate-strategy       Use `data:` uri isolates when spawning VM tests instead of the
                                      default strategy. This may be faster when you only ever run a
                                      single test suite at a time.
    --test-randomize-ordering-seed    Use the specified seed to randomize the execution order of test cases.
                                      Must be a 32bit unsigned integer or "random".
                                      If "random", pick a random seed to use.
                                      If not passed, do not randomize test case execution order.

Output:
-r, --reporter=<option>               Set how to print test results.

          [compact]                   A single line, updated continuously.
          [expanded] (default)        A separate line for each update.
          [github]                    A custom reporter for GitHub Actions (the default reporter when running on GitHub Actions).
          [json]                      A machine-readable format (see https://dart.dev/go/test-docs/json_reporter.md).

    --file-reporter                   Enable an additional reporter writing test results to a file.
                                      Should be in the form <reporter>:<filepath>, Example: "json:reports/tests.json"
    --verbose-trace                   Emit stack traces with core library frames.
    --js-trace                        Emit raw JavaScript stack traces for browser tests.
    --[no-]color                      Use terminal colors.
                                      (auto-detected by default)

''';

final _browsers = '[vm (default), chrome, firefox'
    '${Platform.isMacOS ? ', safari' : ''}'
    '${Platform.isWindows ? ', ie' : ''}, node]';

void main() {
  setUpAll(precompileTestExecutable);

  test('prints help information', () async {
    var test = await runTest(['--help']);
    expectStdoutEquals(test, '''
Runs tests in this package.

$_usage''');
    await test.shouldExit(0);
  });

  group('fails gracefully if', () {
    test('an invalid option is passed', () async {
      var test = await runTest(['--asdf']);
      expectStderrEquals(test, '''
Could not find an option named "asdf".

$_usage''');
      await test.shouldExit(exit_codes.usage);
    });

    test('a non-existent file is passed', () async {
      var test = await runTest(['file']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: loading file [E]',
            'Failed to load "file": Does not exist.'
          ]));
      await test.shouldExit(1);
    });

    test("the default directory doesn't exist", () async {
      var test = await runTest([]);
      expectStderrEquals(test, '''
No test files were passed and the default "test/" directory doesn't exist.

$_usage''');
      await test.shouldExit(exit_codes.data);
    });

    test('a test file fails to load', () async {
      await d.file('test.dart', 'invalid Dart file').create();
      var test = await runTest(['test.dart']);

      expect(
          test.stdout,
          containsInOrder([
            'Failed to load "test.dart":',
            "test.dart:1:9: Error: Expected ';' after this.",
            'invalid Dart file'
          ]));

      await test.shouldExit(1);
    });

    // This syntax error is detected lazily, and so requires some extra
    // machinery to support.
    test('a test file fails to parse due to a missing semicolon', () async {
      await d.file('test.dart', 'void main() {foo}').create();
      var test = await runTest(['test.dart']);

      expect(
          test.stdout,
          containsInOrder([
            '-1: loading test.dart [E]',
            'Failed to load "test.dart":',
            "test.dart:1:14: Error: Expected ';' after this"
          ]));

      await test.shouldExit(1);
    });

    // This is slightly different from the above test because it's an error
    // that's caught first by the analyzer when it's used to parse the file.
    test('a test file fails to parse', () async {
      await d.file('test.dart', '@TestOn)').create();
      var test = await runTest(['test.dart']);

      expect(
          test.stdout,
          containsInOrder([
            '-1: loading test.dart [E]',
            'Failed to load "test.dart":',
            "test.dart:1:8: Error: Expected a declaration, but got ')'",
            '@TestOn)',
          ]));

      await test.shouldExit(1);
    });

    test("an annotation's contents are invalid", () async {
      await d.file('test.dart', "@TestOn('zim')\nlibrary foo;").create();
      var test = await runTest(['test.dart']);

      expect(
          test.stdout,
          containsInOrder([
            '-1: loading test.dart [E]',
            'Failed to load "test.dart":',
            'Error on line 1, column 10: Undefined variable.',
            "@TestOn('zim')",
            '         ^^^'
          ]));
      await test.shouldExit(1);
    });

    test('a test file throws', () async {
      await d.file('test.dart', "void main() => throw 'oh no';").create();
      var test = await runTest(['test.dart']);

      expect(
          test.stdout,
          containsInOrder([
            '-1: loading test.dart [E]',
            'Failed to load "test.dart": oh no'
          ]));
      await test.shouldExit(1);
    });

    test("a test file doesn't have a main defined", () async {
      await d.file('test.dart', 'void foo() {}').create();
      var test = await runTest(['test.dart']);

      expect(
          test.stdout,
          emitsThrough(
            contains('-1: loading test.dart [E]'),
          ));
      expect(
          test.stdout,
          emitsThrough(anyOf([
            contains("Error: Getter not found: 'main'"),
            contains("Error: Undefined name 'main'"),
          ])));

      await test.shouldExit(1);
    });

    test('a test file has a non-function main', () async {
      await d.file('test.dart', 'int main = 0;').create();
      var test = await runTest(['test.dart']);

      expect(test.stdout, emitsThrough(contains('-1: loading test.dart [E]')));
      expect(
          test.stdout,
          emitsThrough(anyOf([
            contains(
              "A value of type 'int' can't be assigned to a variable of type "
              "'Function'",
            ),
            contains(
              "A value of type 'int' can't be returned from a function with "
              "return type 'Function'",
            ),
          ])));

      await test.shouldExit(1);
    });

    test('a test file has a main with arguments', () async {
      await d.file('test.dart', 'void main(arg) {}').create();
      var test = await runTest(['test.dart']);

      expect(
          test.stdout,
          containsInOrder([
            '-1: loading test.dart [E]',
            'Failed to load "test.dart": Top-level main() function takes arguments.'
          ]));
      await test.shouldExit(1);
    });

    test('multiple load errors occur', () async {
      await d.file('test.dart', 'invalid Dart file').create();
      var test = await runTest(['test.dart', 'nonexistent.dart']);

      expect(
          await test.stdoutStream().toList(),
          containsAll([
            contains('loading nonexistent.dart [E]'),
            contains('Failed to load "nonexistent.dart": Does not exist'),
            contains('loading test.dart [E]'),
            contains('Failed to load "test.dart"'),
          ]));

      await test.shouldExit(1);
    });

    // TODO(nweiz): test what happens when a test file is unreadable once issue
    // 15078 is fixed.
  });

  group('runs successful tests', () {
    test('defined in a single file', () async {
      await d.file('test.dart', _success).create();
      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('defined in a directory', () async {
      for (var i = 0; i < 3; i++) {
        await d.file('${i}_test.dart', _success).create();
      }

      var test = await runTest(['.']);
      expect(test.stdout, emitsThrough(contains('+3: All tests passed!')));
      await test.shouldExit(0);
    });

    test('defaulting to the test directory', () async {
      await d
          .dir(
              'test',
              Iterable.generate(3, (i) {
                return d.file('${i}_test.dart', _success);
              }))
          .create();

      var test = await runTest([]);
      expect(test.stdout, emitsThrough(contains('+3: All tests passed!')));
      await test.shouldExit(0);
    });

    test('directly', () async {
      await d.file('test.dart', _success).create();
      var test = await runDart(['test.dart']);

      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    });

    // Regression test; this broke in 0.12.0-beta.9.
    test('on a file in a subdirectory', () async {
      await d.dir('dir', [d.file('test.dart', _success)]).create();

      var test = await runTest(['dir/test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });
  });

  group('runs successful tests with async setup', () {
    setUp(() async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() async {
          test("success 1", () {});

          await () async {};

          test("success 2", () {});
        }
      ''').create();
    });

    test('defined in a single file', () async {
      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
      await test.shouldExit(0);
    });

    test('directly', () async {
      var test = await runDart(['test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    });
  });

  group('runs failing tests', () {
    test('respects the chain-stack-traces flag', () async {
      await d.file('test.dart', _asyncFailure).create();

      var test = await runTest(['test.dart', '--chain-stack-traces']);
      expect(test.stdout, emitsThrough(contains('asynchronous gap')));
      await test.shouldExit(1);
    });

    test('defaults to not chaining stack traces', () async {
      await d.file('test.dart', _asyncFailure).create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '00:00 +0: failure',
            '00:00 +0 -1: failure [E]',
            'oh no',
            'test.dart 8:7  main.<fn>.<fn>',
          ]));
      await test.shouldExit(1);
    });

    test('defined in a single file', () async {
      await d.file('test.dart', _failure).create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
      await test.shouldExit(1);
    });

    test('defined in a directory', () async {
      for (var i = 0; i < 3; i++) {
        await d.file('${i}_test.dart', _failure).create();
      }

      var test = await runTest(['.']);
      expect(test.stdout, emitsThrough(contains('-3: Some tests failed.')));
      await test.shouldExit(1);
    });

    test('defaulting to the test directory', () async {
      await d
          .dir(
              'test',
              Iterable.generate(3, (i) {
                return d.file('${i}_test.dart', _failure);
              }))
          .create();

      var test = await runTest([]);
      expect(test.stdout, emitsThrough(contains('-3: Some tests failed.')));
      await test.shouldExit(1);
    });

    test('directly', () async {
      await d.file('test.dart', _failure).create();
      var test = await runDart(['test.dart']);
      expect(test.stdout, emitsThrough(contains('Some tests failed.')));
      await test.shouldExit(255);
    });
  });

  test('runs tests even when a file fails to load', () async {
    await d.file('test.dart', _success).create();

    var test = await runTest(['test.dart', 'nonexistent.dart']);
    expect(test.stdout, emitsThrough(contains('+1 -1: Some tests failed.')));
    await test.shouldExit(1);
  });

  group('with a top-level @Skip declaration', () {
    setUp(() async {
      await d.file('test.dart', '''
        @Skip()

        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("success", () {});
        }
      ''').create();
    });

    test('skips all tests', () async {
      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+0 ~1: All tests skipped.')));
      await test.shouldExit(0);
    });

    test('runs all tests with --run-skipped', () async {
      var test = await runTest(['--run-skipped', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });
  });

  group('with onPlatform', () {
    test('respects matching Skips', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("fail", () => throw 'oh no', onPlatform: {"vm": Skip()});
}
''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+0 ~1: All tests skipped.')));
      await test.shouldExit(0);
    });

    test('ignores non-matching Skips', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {}, onPlatform: {"chrome": Skip()});
}
''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('respects matching Timeouts', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("fail", () async {
    await Future.delayed(Duration.zero);
    throw 'oh no';
  }, onPlatform: {
    "vm": Timeout(Duration.zero)
  });
}
''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder(
              ['Test timed out after 0 seconds.', '-1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('ignores non-matching Timeouts', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {}, onPlatform: {
    "chrome": Timeout(Duration(seconds: 0))
  });
}
''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('applies matching platforms in order', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {}, onPlatform: {
    "vm": Skip("first"),
    "vm || windows": Skip("second"),
    "vm || linux": Skip("third"),
    "vm || mac-os": Skip("fourth"),
    "vm || android": Skip("fifth")
  });
}
''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdoutStream(), neverEmits(contains('Skip: first')));
      expect(test.stdoutStream(), neverEmits(contains('Skip: second')));
      expect(test.stdoutStream(), neverEmits(contains('Skip: third')));
      expect(test.stdoutStream(), neverEmits(contains('Skip: fourth')));
      expect(test.stdout, emitsThrough(contains('Skip: fifth')));
      await test.shouldExit(0);
    });

    test('applies platforms to a group', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  group("group", () {
    test("success", () {});
  }, onPlatform: {
    "vm": Skip()
  });
}
''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests skipped.')));
      await test.shouldExit(0);
    });
  });

  group('with an @OnPlatform annotation', () {
    test('respects matching Skips', () async {
      await d.file('test.dart', '''
@OnPlatform(const {"vm": const Skip()})

import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("fail", () => throw 'oh no');
}
''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+0 ~1: All tests skipped.')));
      await test.shouldExit(0);
    });

    test('ignores non-matching Skips', () async {
      await d.file('test.dart', '''
@OnPlatform(const {"chrome": const Skip()})

import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {});
}
''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('respects matching Timeouts', () async {
      await d.file('test.dart', '''
@OnPlatform(const {
  "vm": const Timeout(const Duration(seconds: 0))
})

import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("fail", () async {
    await Future.delayed(Duration.zero);
    throw 'oh no';
  });
}
''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder(
              ['Test timed out after 0 seconds.', '-1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('ignores non-matching Timeouts', () async {
      await d.file('test.dart', '''
@OnPlatform(const {
  "chrome": const Timeout(const Duration(seconds: 0))
})

import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {});
}
''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });
  });

  test('with the --color flag, uses colors', () async {
    await d.file('test.dart', _failure).create();
    var test = await runTest(['--color', 'test.dart']);
    // This is the color code for red.
    expect(test.stdout, emitsThrough(contains('\u001b[31m')));
    await test.shouldExit();
  });

  group('runs tests successfully more than once when calling runTests', () {
    test('defined in a single file', () async {
      await d.file('test.dart', _success).create();
      await d.file('runner.dart', '''
import 'package:test_core/src/executable.dart' as test;

void main(List<String> args) async {
  await test.runTests(args);
  await test.runTests(args);
  test.completeShutdown();
}''').create();
      var test = await runDart([
        'runner.dart',
        '--no-color',
        '--reporter',
        'compact',
        '--',
        'test.dart',
      ], description: 'dart runner.dart -- test.dart');
      expect(
          test.stdout,
          emitsThrough(containsInOrder([
            '+0: loading test.dart',
            '+0: success',
            '+1: success',
            'All tests passed!'
          ])));
      expect(
          test.stdout,
          emitsThrough(containsInOrder([
            '+0: loading test.dart',
            '+0: success',
            '+1: success',
            '+1: All tests passed!',
          ])));
      await test.shouldExit(0);
    });
  }, onPlatform: const {
    'windows': Skip('https://github.com/dart-lang/test/issues/1615')
  });

  group('nnbd', () {
    final testContents = '''
import 'package:test/test.dart';
import 'opted_out.dart';

void main() {
  test("success", () {
    expect(foo, true);
  });
}''';

    setUp(() async {
      await d.file('opted_out.dart', '''
// @dart=2.8
final foo = true;''').create();
    });

    test('sound null safety is enabled if the entrypoint opts in explicitly',
        () async {
      await d.file('test.dart', '''
// @dart=2.12
$testContents
''').create();
      var test = await runTest(['test.dart']);

      expect(
          test.stdout,
          emitsThrough(contains(
              'Error: A library can\'t opt out of null safety by default, '
              'when using sound null safety.')));
      await test.shouldExit(1);
    });

    test('sound null safety is disabled if the entrypoint opts out explicitly',
        () async {
      await d.file('test.dart', '''
// @dart=2.8
$testContents''').create();
      var test = await runTest(['test.dart']);

      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    group('defaults', () {
      late PackageConfig currentPackageConfig;

      setUpAll(() async {
        currentPackageConfig =
            await loadPackageConfigUri((await Isolate.packageConfig)!);
      });

      setUp(() async {
        await d.file('test.dart', testContents).create();
      });

      test('sound null safety is enabled if the package is opted in', () async {
        var newPackageConfig = PackageConfig([
          ...currentPackageConfig.packages,
          Package('example', Uri.file('${d.sandbox}/'),
              languageVersion: LanguageVersion(2, 12),
              // TODO: https://github.com/dart-lang/package_config/issues/81
              packageUriRoot: Uri.file('${d.sandbox}/')),
        ]);

        await d
            .file('package_config.json',
                jsonEncode(PackageConfig.toJson(newPackageConfig)))
            .create();

        var test = await runTest(['test.dart'],
            packageConfig: p.join(d.sandbox, 'package_config.json'));

        expect(
            test.stdout,
            emitsThrough(contains(
                'Error: A library can\'t opt out of null safety by default, '
                'when using sound null safety.')));
        await test.shouldExit(1);
      });

      test('sound null safety is disabled if the package is opted out',
          () async {
        var newPackageConfig = PackageConfig([
          ...currentPackageConfig.packages,
          Package('example', Uri.file('${d.sandbox}/'),
              languageVersion: LanguageVersion(2, 8),
              // TODO: https://github.com/dart-lang/package_config/issues/81
              packageUriRoot: Uri.file('${d.sandbox}/')),
        ]);

        await d
            .file('package_config.json',
                jsonEncode(PackageConfig.toJson(newPackageConfig)))
            .create();

        var test = await runTest(['test.dart'],
            packageConfig: p.join(d.sandbox, 'package_config.json'));

        expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
        await test.shouldExit(0);
      });
    });
  });

  group('language experiments', () {
    group('are inherited from the executable arguments', () {
      setUp(() async {
        await d.file('test.dart', '''
// @dart=2.10
import 'package:test/test.dart';

// Compile time error if the experiment is enabled
int x;

void main() {
  test('x is null', () {
    expect(x, isNull);
  });
}
''').create();
      });

      for (var platform in ['vm', 'chrome']) {
        test('on the $platform platform', () async {
          var test = await runTest(['test.dart', '-p', platform],
              vmArgs: ['--enable-experiment=non-nullable']);

          await expectLater(test.stdout, emitsThrough(contains('int x;')));
          await test.shouldExit(1);

          // Test that they can be removed on subsequent runs as well
          test = await runTest(['test.dart', '-p', platform]);
          await expectLater(
              test.stdout, emitsThrough(contains('+1: All tests passed!')));
          await test.shouldExit(0);
        });
      }
    });
  });
}
