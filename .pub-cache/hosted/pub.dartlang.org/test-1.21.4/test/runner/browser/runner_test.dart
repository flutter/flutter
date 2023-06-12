// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';

final _success = '''
import 'package:test/test.dart';

void main() {
  test("success", () {});
}
''';

final _failure = '''
import 'package:test/test.dart';

void main() {
  test("failure", () => throw TestFailure("oh no"));
}
''';

void main() {
  setUpAll(precompileTestExecutable);

  group('fails gracefully if', () {
    test('a test file fails to compile', () async {
      await d.file('test.dart', 'invalid Dart file').create();
      var test = await runTest(['-p', 'chrome', 'test.dart']);

      expect(
          test.stdout,
          containsInOrder([
            'Error: Compilation failed.',
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": dart2js failed.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('a test file throws', () async {
      await d.file('test.dart', "void main() => throw 'oh no';").create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": oh no'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test("a test file doesn't have a main defined", () async {
      await d.file('test.dart', 'void foo() {}').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": No top-level main() function defined.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome', skip: 'https://github.com/dart-lang/test/issues/894');

    test('a test file has a non-function main', () async {
      await d.file('test.dart', 'int main;').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": Top-level main getter is not a function.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome', skip: 'https://github.com/dart-lang/test/issues/894');

    test('a test file has a main with arguments', () async {
      await d.file('test.dart', 'void main(arg) {}').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": Top-level main() function takes arguments.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('a custom HTML file has no script tag', () async {
      await d.file('test.dart', 'void main() {}').create();

      await d.file('test.html', '''
<html>
<head>
  <link rel="x-dart-test" href="test.dart">
</head>
</html>
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": "test.html" must contain '
                '<script src="packages/test/dart.js"></script>.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('a custom HTML file has no link', () async {
      await d.file('test.dart', 'void main() {}').create();

      await d.file('test.html', '''
<html>
<head>
  <script src="packages/test/dart.js"></script>
</head>
</html>
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": Expected exactly 1 '
                '<link rel="x-dart-test"> in test.html, found 0.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('a custom HTML file has too many links', () async {
      await d.file('test.dart', 'void main() {}').create();

      await d.file('test.html', '''
<html>
<head>
  <link rel='x-dart-test' href='test.dart'>
  <link rel='x-dart-test' href='test.dart'>
  <script src="packages/test/dart.js"></script>
</head>
</html>
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": Expected exactly 1 '
                '<link rel="x-dart-test"> in test.html, found 2.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('a custom HTML file has no href in the link', () async {
      await d.file('test.dart', 'void main() {}').create();

      await d.file('test.html', '''
<html>
<head>
  <link rel='x-dart-test'>
  <script src="packages/test/dart.js"></script>
</head>
</html>
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": Expected <link rel="x-dart-test"> in '
                'test.html to have an "href" attribute.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('a custom HTML file has an invalid test URL', () async {
      await d.file('test.dart', 'void main() {}').create();

      await d.file('test.html', '''
<html>
<head>
  <link rel='x-dart-test' href='wrong.dart'>
  <script src="packages/test/dart.js"></script>
</head>
</html>
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": Failed to load script at '
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test(
        'still errors even with a custom HTML template set since it will take precedence',
        () async {
      await d.file('test.dart', 'void main() {}').create();

      await d.file('test.html', '''
<html>
<head>
  <link rel="x-dart-test" href="test.dart">
</head>
</html>
''').create();

      await d
          .file(
              'global_test.yaml',
              jsonEncode(
                  {'custom_html_template_path': 'html_template.html.tpl'}))
          .create();

      await d.file('html_template.html.tpl', '''
<html>
<head>
  {{testScript}}
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="foo"></div>
</body>
</html>
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart'],
          environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling test.dart [E]',
            'Failed to load "test.dart": "test.html" must contain '
                '<script src="packages/test/dart.js"></script>.'
          ]));
      await test.shouldExit(1);
    }, tags: 'chrome');

    group('with a custom HTML template', () {
      setUp(() async {
        await d.file('test.dart', _success).create();
        await d
            .file(
                'global_test.yaml',
                jsonEncode(
                    {'custom_html_template_path': 'html_template.html.tpl'}))
            .create();
      });

      test('that does not exist', () async {
        var test = await runTest(['-p', 'chrome', 'test.dart'],
            environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
        expect(
            test.stdout,
            containsInOrder([
              '-1: compiling test.dart [E]',
              'Failed to load "test.dart": "html_template.html.tpl" does not exist or is not readable'
            ]));
        await test.shouldExit(1);
      }, tags: 'chrome');

      test("that doesn't contain the {{testScript}} tag", () async {
        await d.file('html_template.html.tpl', '''
<html>
<head>
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="foo"></div>
</body>
</html>
''').create();

        var test = await runTest(['-p', 'chrome', 'test.dart'],
            environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
        expect(
            test.stdout,
            containsInOrder([
              '-1: compiling test.dart [E]',
              'Failed to load "test.dart": "html_template.html.tpl" must contain exactly one {{testScript}} placeholder'
            ]));
        await test.shouldExit(1);
      }, tags: 'chrome');

      test('that contains more than one {{testScript}} tag', () async {
        await d.file('html_template.html.tpl', '''
<html>
<head>
  {{testScript}}
  {{testScript}}
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="foo"></div>
</body>
</html>
''').create();

        var test = await runTest(['-p', 'chrome', 'test.dart'],
            environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
        expect(
            test.stdout,
            containsInOrder([
              '-1: compiling test.dart [E]',
              'Failed to load "test.dart": "html_template.html.tpl" must contain exactly one {{testScript}} placeholder'
            ]));
        await test.shouldExit(1);
      }, tags: 'chrome');

      test('that has no script tag', () async {
        await d.file('html_template.html.tpl', '''
<html>
<head>
  {{testScript}}
</head>
</html>
''').create();

        var test = await runTest(['-p', 'chrome', 'test.dart'],
            environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
        expect(
            test.stdout,
            containsInOrder([
              '-1: compiling test.dart [E]',
              'Failed to load "test.dart": "html_template.html.tpl" must contain '
                  '<script src="packages/test/dart.js"></script>.'
            ]));
        await test.shouldExit(1);
      }, tags: 'chrome');

      test('that is named like the test file', () async {
        await d.file('test.html', '''
<html>
<head>
  {{testScript}}
  <script src="packages/test/dart.js"></script>
</head>
</html>
''').create();

        await d
            .file('global_test_2.yaml',
                jsonEncode({'custom_html_template_path': 'test.html'}))
            .create();
        var test = await runTest(['-p', 'chrome', 'test.dart'],
            environment: {'DART_TEST_CONFIG': 'global_test_2.yaml'});
        expect(
            test.stdout,
            containsInOrder([
              '-1: compiling test.dart [E]',
              'Failed to load "test.dart": template file "test.html" cannot be named '
                  'like the test file.'
            ]));
        await test.shouldExit(1);
      });
    });
  });

  group('runs successful tests', () {
    test('on a browser and the VM', () async {
      await d.file('test.dart', _success).create();
      var test = await runTest(['-p', 'chrome', '-p', 'vm', 'test.dart']);

      expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test('with setUpAll', () async {
      await d.file('test.dart', r'''
          import 'package:test/test.dart';

          void main() {
            setUpAll(() => print("in setUpAll"));

            test("test", () {});
          }
          ''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+0: (setUpAll)')));
      expect(test.stdout, emits('in setUpAll'));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test('with tearDownAll', () async {
      await d.file('test.dart', r'''
          import 'package:test/test.dart';

          void main() {
            tearDownAll(() => print("in tearDownAll"));

            test("test", () {});
          }
          ''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: (tearDownAll)')));
      expect(test.stdout, emits('in tearDownAll'));
      await test.shouldExit(0);
    }, tags: 'chrome');

    // Regression test; this broke in 0.12.0-beta.9.
    test('on a file in a subdirectory', () async {
      await d.dir('dir', [d.file('test.dart', _success)]).create();

      var test = await runTest(['-p', 'chrome', 'dir/test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    group('with a custom HTML template file', () {
      group('without a {{testName}} tag', () {
        setUp(() async {
          await d
              .file(
                  'global_test.yaml',
                  jsonEncode(
                      {'custom_html_template_path': 'html_template.html.tpl'}))
              .create();
          await d.file('html_template.html.tpl', '''
  <html>
  <head>
    {{testScript}}
    <script src="packages/test/dart.js"></script>
  </head>
  <body>
    <div id="foo"></div>
  </body>
  </html>
  ''').create();

          await d.file('test.dart', '''
  import 'dart:html';

  import 'package:test/test.dart';

  void main() {
    test("success", () {
      expect(document.querySelector('#foo'), isNotNull);
    });
  }
  ''').create();
        });

        test('on Chrome', () async {
          var test = await runTest(['-p', 'chrome', 'test.dart'],
              environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
          expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
          await test.shouldExit(0);
        }, tags: 'chrome');
      });

      group('with a {{testName}} tag', () {
        setUp(() async {
          await d
              .file(
                  'global_test.yaml',
                  jsonEncode(
                      {'custom_html_template_path': 'html_template.html.tpl'}))
              .create();
          await d.file('html_template.html.tpl', '''
  <html>
  <head>
    <title>{{testName}}</title>
    {{testScript}}
    <script src="packages/test/dart.js"></script>
  </head>
  <body>
    <div id="foo"></div>
  </body>
  </html>
  ''').create();

          await d.file('test-with-title.dart', '''
  import 'dart:html';

  import 'package:test/test.dart';

  void main() {
    test("success", () {
      expect(document.querySelector('#foo'), isNotNull);
    });
    test("title", () {
      expect(document.title, 'test-with-title.dart');
    });
  }
  ''').create();
        });

        test('on Chrome', () async {
          var test = await runTest(['-p', 'chrome', 'test-with-title.dart'],
              environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
          expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
          await test.shouldExit(0);
        }, tags: 'chrome');
      });
    });

    group('with a custom HTML file', () {
      setUp(() async {
        await d.file('test.dart', '''
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test("success", () {
    expect(document.querySelector('#foo'), isNotNull);
  });
}
''').create();

        await d.file('test.html', '''
<html>
<head>
  <link rel='x-dart-test' href='test.dart'>
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="foo"></div>
</body>
</html>
''').create();
      });

      test('on Chrome', () async {
        var test = await runTest(['-p', 'chrome', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'chrome');

      // Regression test for https://github.com/dart-lang/test/issues/82.
      test('ignores irrelevant link tags', () async {
        await d.file('test.html', '''
<html>
<head>
  <link rel='x-dart-test-not'>
  <link rel='other' href='test.dart'>
  <link rel='x-dart-test' href='test.dart'>
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="foo"></div>
</body>
</html>
''').create();

        var test = await runTest(['-p', 'chrome', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'chrome');

      test('takes precedence over provided HTML template', () async {
        await d
            .file(
                'global_test.yaml',
                jsonEncode(
                    {'custom_html_template_path': 'html_template.html.tpl'}))
            .create();
        await d.file('html_template.html.tpl', '''
<html>
<head>
  {{testScript}}
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="not-foo"></div>
</body>
</html>
''').create();

        var test = await runTest(['-p', 'chrome', 'test.dart'],
            environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
        expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'chrome');
    });
  });

  group('runs failing tests', () {
    test('that fail only on the browser', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test("test", () {
    if (p.style == p.Style.url) throw TestFailure("oh no");
  });
}
''').create();

      var test = await runTest(['-p', 'chrome', '-p', 'vm', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1 -1: Some tests failed.')));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('that fail only on the VM', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test("test", () {
    if (p.style != p.Style.url) throw TestFailure("oh no");
  });
}
''').create();

      var test = await runTest(['-p', 'chrome', '-p', 'vm', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1 -1: Some tests failed.')));
      await test.shouldExit(1);
    }, tags: 'chrome');

    group('with a custom HTML file', () {
      setUp(() async {
        await d.file('test.dart', '''
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test("failure", () {
    expect(document.querySelector('#foo'), isNull);
  });
}
''').create();

        await d.file('test.html', '''
<html>
<head>
  <link rel='x-dart-test' href='test.dart'>
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="foo"></div>
</body>
</html>
''').create();
      });

      test('on Chrome', () async {
        var test = await runTest(['-p', 'chrome', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
        await test.shouldExit(1);
      }, tags: 'chrome');
    });
  });

  test('the compiler uses colors if the test runner uses colors', () async {
    await d.file('test.dart', '{').create();

    var test = await runTest(['--color', '-p', 'chrome', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('\u001b[31m')));
    await test.shouldExit(1);
  }, tags: 'chrome');

  test('forwards prints from the browser test', () async {
    await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("test", () {
    print("Hello,");
    return Future(() => print("world!"));
  });
}
''').create();

    var test = await runTest(['-p', 'chrome', 'test.dart']);
    expect(test.stdout, emitsInOrder([emitsThrough('Hello,'), 'world!']));
    await test.shouldExit(0);
  }, tags: 'chrome');

  test('dartifies stack traces for JS-compiled tests by default', () async {
    await d.file('test.dart', _failure).create();

    var test = await runTest(['-p', 'chrome', '--verbose-trace', 'test.dart']);
    expect(test.stdout,
        containsInOrder([' main.<fn>', 'package:test', 'dart:async/zone.dart']),
        skip: 'https://github.com/dart-lang/sdk/issues/41949');
    await test.shouldExit(1);
  }, tags: 'chrome');

  test("doesn't dartify stack traces for JS-compiled tests with --js-trace",
      () async {
    await d.file('test.dart', _failure).create();

    var test = await runTest(
        ['-p', 'chrome', '--verbose-trace', '--js-trace', 'test.dart']);
    expect(test.stdoutStream(), neverEmits(endsWith(' main.<fn>')));
    expect(test.stdoutStream(), neverEmits(contains('package:test')));
    expect(test.stdoutStream(), neverEmits(contains('dart:async/zone.dart')));
    expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
    await test.shouldExit(1);
  }, tags: 'chrome');

  test('respects top-level @Timeout declarations', () async {
    await d.file('test.dart', '''
@Timeout(const Duration(seconds: 0))

import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("timeout", () => Future.delayed(Duration.zero));
}
''').create();

    var test = await runTest(['-p', 'chrome', 'test.dart']);
    expect(
        test.stdout,
        containsInOrder(
            ['Test timed out after 0 seconds.', '-1: Some tests failed.']));
    await test.shouldExit(1);
  }, tags: 'chrome');

  group('with onPlatform', () {
    test('respects matching Skips', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("fail", () => throw 'oh no', onPlatform: {"browser": Skip()});
}
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+0 ~1: All tests skipped.')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test('ignores non-matching Skips', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {}, onPlatform: {"vm": Skip()});
}
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test('respects matching Timeouts', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("fail", () async {
    await Future.delayed(Duration.zero);
    throw 'oh no';
  }, onPlatform: {
    "browser": Timeout(Duration.zero)
  });
}
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder(
              ['Test timed out after 0 seconds.', '-1: Some tests failed.']));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('ignores non-matching Timeouts', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {}, onPlatform: {
    "vm": Timeout(Duration(seconds: 0))
  });
}
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test('applies matching platforms in order', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {}, onPlatform: {
    "browser": Skip("first"),
    "browser || windows": Skip("second"),
    "browser || linux": Skip("third"),
    "browser || mac-os": Skip("fourth"),
    "browser || android": Skip("fifth")
  });
}
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(test.stdoutStream(), neverEmits(contains('Skip: first')));
      expect(test.stdoutStream(), neverEmits(contains('Skip: second')));
      expect(test.stdoutStream(), neverEmits(contains('Skip: third')));
      expect(test.stdoutStream(), neverEmits(contains('Skip: fourth')));
      expect(test.stdout, emitsThrough(contains('Skip: fifth')));
      await test.shouldExit(0);
    }, tags: 'chrome');
  });

  group('with an @OnPlatform annotation', () {
    test('respects matching Skips', () async {
      await d.file('test.dart', '''
@OnPlatform(const {"browser": const Skip()})

import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("fail", () => throw 'oh no');
}
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('~1: All tests skipped.')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test('ignores non-matching Skips', () async {
      await d.file('test.dart', '''
@OnPlatform(const {"vm": const Skip()})

import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {});
}
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test('respects matching Timeouts', () async {
      await d.file('test.dart', '''
@OnPlatform(const {
  "browser": const Timeout(const Duration(seconds: 0))
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

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder(
              ['Test timed out after 0 seconds.', '-1: Some tests failed.']));
      await test.shouldExit(1);
    }, tags: 'chrome');

    test('ignores non-matching Timeouts', () async {
      await d.file('test.dart', '''
@OnPlatform(const {
  "vm": const Timeout(const Duration(seconds: 0))
})

import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {});
}
''').create();

      var test = await runTest(['-p', 'chrome', 'test.dart']);
      await test.shouldExit(0);
    }, tags: 'chrome');
  });
}
