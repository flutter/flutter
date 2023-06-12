// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_core/src/util/io.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('ignores an empty file', () async {
    await d.file('dart_test.yaml', '').create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("success", () {});
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  });

  test('loads configuration from the path passed to --configuration', () async {
    // Make sure dart_test.yaml is ignored.
    await d.file('dart_test.yaml', jsonEncode({'run_skipped': true})).create();

    await d.file('special_test.yaml', jsonEncode({'skip': true})).create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("test", () => throw "oh no");
      }
    ''').create();

    var test =
        await runTest(['--configuration', 'special_test.yaml', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('All tests skipped.')));
    await test.shouldExit(0);
  });

  test('pauses the test runner after a suite loads with pause_after_load: true',
      () async {
    await d
        .file('dart_test.yaml', jsonEncode({'pause_after_load': true}))
        .create();

    await d.file('test.dart', '''
import 'package:test/test.dart';

void main() {
  print('loaded test!');

  test("success", () {});
}
''').create();

    var test = await runTest(['-p', 'chrome', 'test.dart']);
    await expectLater(test.stdout, emitsThrough('loaded test!'));
    await expectLater(
        test.stdout,
        emitsInOrder([
          '',
          equalsIgnoringWhitespace('''
            The test runner is paused. Open the dev console in Chrome and set
            breakpoints. Once you're finished, return to this terminal and press
            Enter.
          ''')
        ]));

    var nextLineFired = false;

    unawaited(test.stdout.next.then(expectAsync1((line) {
      expect(line, contains('+0: success'));
      nextLineFired = true;
    })));

    // Wait a little bit to be sure that the tests don't start running without
    // our input.
    await Future.delayed(Duration(seconds: 2));
    expect(nextLineFired, isFalse);

    test.stdin.writeln();
    await expectLater(
        test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  }, tags: 'chrome', onPlatform: const {
    'windows': Skip('https://github.com/dart-lang/test/issues/1613')
  });

  test('runs skipped tests with run_skipped: true', () async {
    await d.file('dart_test.yaml', jsonEncode({'run_skipped': true})).create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("skip", () => print("In test!"), skip: true);
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('In test!')));
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  });

  test('includes the full stack with verbose_trace: true', () async {
    await d
        .file('dart_test.yaml', jsonEncode({'verbose_trace': true}))
        .create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("failure", () => throw "oh no");
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('dart:async')));
    await test.shouldExit(1);
  });

  test('disables stack trace chaining with chain_stack_traces: false',
      () async {
    await d
        .file('dart_test.yaml', jsonEncode({'chain_stack_traces': false}))
        .create();

    await d.file('test.dart', '''
         import 'dart:async';

         import 'package:test/test.dart';

          void main() {
            test("failure", () async{
              await Future((){});
              await Future((){});
              throw "oh no";
            });
          }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(
        test.stdout,
        containsInOrder([
          '+0: failure',
          '+0 -1: failure [E]',
          'oh no',
          'test.dart 9:15  main.<fn>',
        ]));
    await test.shouldExit(1);
  });

  test("doesn't dartify stack traces for JS-compiled tests with js_trace: true",
      () async {
    await d.file('dart_test.yaml', jsonEncode({'js_trace': true})).create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("failure", () => throw "oh no");
      }
    ''').create();

    var test = await runTest(['-p', 'chrome', '--verbose-trace', 'test.dart']);
    expect(test.stdoutStream(), neverEmits(endsWith(' main.<fn>')));
    expect(test.stdoutStream(), neverEmits(contains('package:test')));
    expect(test.stdoutStream(), neverEmits(contains('dart:async/zone.dart')));
    expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
    await test.shouldExit(1);
  }, tags: 'chrome');

  test('retries tests with retry: 1', () async {
    await d.file('dart_test.yaml', jsonEncode({'retry': 1})).create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';
      import 'dart:async';

      var attempt = 0;
      void main() {
        test("test", () {
          attempt++;
          if(attempt <= 1) {
            throw 'Failure!';
          }
        });
      }

    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('+1: All tests passed')));
    await test.shouldExit(0);
  });

  test('skips tests with skip: true', () async {
    await d.file('dart_test.yaml', jsonEncode({'skip': true})).create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("test", () {});
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('All tests skipped.')));
    await test.shouldExit(0);
  });

  test('skips tests with skip: reason', () async {
    await d
        .file('dart_test.yaml', jsonEncode({'skip': 'Tests are boring.'}))
        .create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("test", () {});
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('Tests are boring.')));
    expect(test.stdout, emitsThrough(contains('All tests skipped.')));
    await test.shouldExit(0);
  });

  group('test_on', () {
    test('runs tests on a platform matching platform', () async {
      await d.file('dart_test.yaml', jsonEncode({'test_on': 'vm'})).create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    });

    test('warns about the VM when no OSes are supported', () async {
      await d
          .file('dart_test.yaml', jsonEncode({'test_on': 'chrome'}))
          .create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr,
          emits(
              "Warning: this package doesn't support running tests on the Dart "
              'VM.'));
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });

    test('warns about the OS when some OSes are supported', () async {
      await d.file('dart_test.yaml', jsonEncode({'test_on': otherOS})).create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr,
          emits("Warning: this package doesn't support running tests on "
              '${currentOS.name}.'));
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });

    test('warns about browsers in general when no browsers are supported',
        () async {
      await d.file('dart_test.yaml', jsonEncode({'test_on': 'vm'})).create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stderr,
          emits(
              "Warning: this package doesn't support running tests on browsers."));
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });

    test(
        'warns about specific browsers when specific browsers are '
        'supported', () async {
      await d
          .file('dart_test.yaml', jsonEncode({'test_on': 'safari'}))
          .create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['-p', 'chrome,firefox', 'test.dart']);
      expect(
          test.stderr,
          emits("Warning: this package doesn't support running tests on Chrome "
              'or Firefox.'));
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });
  });

  test('uses the specified reporter', () async {
    await d.file('dart_test.yaml', jsonEncode({'reporter': 'json'})).create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("success", () {});
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('"testStart"')));
    await test.shouldExit(0);
  });

  test('uses the specified pub serve port', () async {
    await d.file('pubspec.yaml', '''
name: myapp
dependencies:
  barback: any
  test: {path: ${p.current}}
transformers:
- myapp:
    \$include: test/**_test.dart
''').create();

    await d.dir('lib', [
      d.file('myapp.dart', '''
        import 'package:barback/barback.dart';

        class MyTransformer extends Transformer {
          final allowedExtensions = '.dart';

          MyTransformer.asPlugin();

          Future apply(Transform transform) async {
            var contents = await transform.primaryInput.readAsString();
            transform.addOutput(Asset.fromString(
                transform.primaryInput.id,
                contents.replaceAll("isFalse", "isTrue")));
          }
        }
      ''')
    ]).create();

    await (await runPub(['get'])).shouldExit(0);

    await d.dir('test', [
      d.file('my_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("success", () => expect(true, isFalse));
        }
      ''')
    ]).create();

    var pub = await runPubServe();

    await d
        .file('dart_test.yaml', jsonEncode({'pub_serve': pubServePort}))
        .create();

    var test = await runTest([]);
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
    await pub.kill();
  }, tags: 'pub', skip: 'https://github.com/dart-lang/test/issues/821');

  test('uses the specified concurrency', () async {
    await d.file('dart_test.yaml', jsonEncode({'concurrency': 2})).create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("success", () {});
      }
    ''').create();

    // We can't reliably test the concurrency, but this at least ensures that
    // it doesn't fail to parse.
    var test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  });

  test('uses the specified timeout', () async {
    await d.file('dart_test.yaml', jsonEncode({'timeout': '0s'})).create();

    await d.file('test.dart', '''
      import 'dart:async';

      import 'package:test/test.dart';

      void main() {
        test("success", () => Future.delayed(Duration.zero));
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(
        test.stdout,
        containsInOrder(
            ['Test timed out after 0 seconds.', '-1: Some tests failed.']));
    await test.shouldExit(1);
  });

  test('runs on the specified platforms', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'platforms': ['vm', 'chrome']
            }))
        .create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("success", () {});
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, containsInOrder(['[VM] success', '[Chrome] success']));
    await test.shouldExit(0);
  }, tags: 'chrome');

  test('command line args take precedence', () async {
    await d.file('dart_test.yaml', jsonEncode({'timeout': '0s'})).create();

    await d.file('test.dart', '''
      import 'dart:async';

      import 'package:test/test.dart';

      void main() {
        test("success", () => Future.delayed(Duration.zero));
      }
    ''').create();

    var test = await runTest(['--timeout=none', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('All tests passed!')));
    await test.shouldExit(0);
  });

  test('uses the specified regexp names', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'names': ['z[ia]p', 'a']
            }))
        .create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("zip", () {});
        test("zap", () {});
        test("zop", () {});
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, containsInOrder(['+0: zap', '+1: All tests passed!']));
    await test.shouldExit(0);
  });

  test('uses the specified plain names', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'names': ['z', 'a']
            }))
        .create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("zip", () {});
        test("zap", () {});
        test("zop", () {});
      }
    ''').create();

    var test = await runTest(['test.dart']);
    expect(test.stdout, containsInOrder(['+0: zap', '+1: All tests passed!']));
    await test.shouldExit(0);
  });

  test('uses the specified paths', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'paths': ['zip', 'zap']
            }))
        .create();

    await d.dir('zip', [
      d.file('zip_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("success", () {});
        }
      ''')
    ]).create();

    await d.dir('zap', [
      d.file('zip_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("success", () {});
        }
      ''')
    ]).create();

    await d.dir('zop', [
      d.file('zip_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("failure", () => throw "oh no");
        }
      ''')
    ]).create();

    var test = await runTest([]);
    expect(test.stdout, emitsThrough(contains('All tests passed!')));
    await test.shouldExit(0);
  });

  test('uses the specified filename', () async {
    await d
        .file('dart_test.yaml', jsonEncode({'filename': 'test_*.dart'}))
        .create();

    await d.dir('test', [
      d.file('test_foo.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("success", () {});
        }
      '''),
      d.file('foo_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("failure", () => throw "oh no");
        }
      '''),
      d.file('test_foo.bart', '''
        import 'package:test/test.dart';

        void main() {
          test("failure", () => throw "oh no");
        }
      ''')
    ]).create();

    var test = await runTest([]);
    expect(test.stdout, emitsThrough(contains('All tests passed!')));
    await test.shouldExit(0);
  });
}
