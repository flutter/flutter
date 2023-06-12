// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Tags(['pub'])
@Skip('https://github.com/dart-lang/test/issues/821')

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

/// The `--pub-serve` argument for the test process, based on [pubServePort].
String get _pubServeArg => '--pub-serve=$pubServePort';

void main() {
  setUpAll(precompileTestExecutable);

  setUp(() async {
    await d.file('pubspec.yaml', '''
name: myapp
dependencies:
  barback: any
  test: {path: ${p.current}}
transformers:
- myapp:
    \$include: test/**_test.dart
''').create();

    await d.dir('test', [
      d.file('my_test.dart', '''
import 'package:test/test.dart';

void main() {
  test("test", () => expect(true, isTrue));
}
''')
    ]).create();

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
  });

  group('with transformed tests', () {
    setUp(() async {
      // Give the test a failing assertion that the transformer will convert to
      // a passing assertion.
      await d.file('test/my_test.dart', '''
import 'package:test/test.dart';

void main() {
  test("test", () => expect(true, isFalse));
}
''').create();
    });

    test('runs those tests in the VM', () async {
      var pub = await runPubServe();
      var test = await runTest([_pubServeArg]);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    });

    testWithCompiler('runs those tests on Chrome', (compilerArgs) async {
      var pub = await runPubServe(args: compilerArgs);
      var test = await runTest([_pubServeArg, '-p', 'chrome']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    }, tags: 'chrome');

    test('runs those tests on Node', () async {
      var pub = await runPubServe();
      var test = await runTest([_pubServeArg, '-p', 'node']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    }, tags: 'node');

    test(
        'gracefully handles pub serve running on the wrong directory for '
        'VM tests', () async {
      await d.dir('web').create();

      var pub = await runPubServe(args: ['web']);
      var test = await runTest([_pubServeArg]);
      expect(
          test.stdout,
          containsInOrder([
            '-1: loading ${p.join("test", "my_test.dart")} [E]',
            'Failed to load "${p.join("test", "my_test.dart")}":',
            '404 Not Found',
            'Make sure "pub serve" is serving the test/ directory.'
          ]));
      await test.shouldExit(1);

      await pub.kill();
    });

    group(
        'gracefully handles pub serve running on the wrong directory for '
        'browser tests', () {
      testWithCompiler('when run on Chrome', (compilerArgs) async {
        await d.dir('web').create();

        var pub = await runPubServe(args: ['web', ...compilerArgs]);
        var test = await runTest([_pubServeArg, '-p', 'chrome']);
        expect(
            test.stdout,
            containsInOrder([
              '-1: compiling ${p.join("test", "my_test.dart")} [E]',
              'Failed to load "${p.join("test", "my_test.dart")}":',
              '404 Not Found',
              'Make sure "pub serve" is serving the test/ directory.'
            ]));
        await test.shouldExit(1);

        await pub.kill();
      }, tags: 'chrome');
    });

    test(
        'gracefully handles pub serve running on the wrong directory for Node '
        'tests', () async {
      await d.dir('web').create();

      var pub = await runPubServe(args: ['web']);
      var test = await runTest([_pubServeArg, '-p', 'node']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: compiling ${p.join("test", "my_test.dart")} [E]',
            'Failed to load "${p.join("test", "my_test.dart")}":',
            '404 Not Found',
            'Make sure "pub serve" is serving the test/ directory.'
          ]));
      await test.shouldExit(1);

      await pub.kill();
    }, tags: 'node');
  });

  group('uses a custom HTML file', () {
    setUp(() async {
      await d.dir('test', [
        d.file('test.dart', '''
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test("failure", () {
    expect(document.querySelector('#foo'), isNull);
  });
}
'''),
        d.file('test.html', '''
<html>
<head>
  <link rel='x-dart-test' href='test.dart'>
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="foo"></div>
</body>
''')
      ]).create();
    });

    testWithCompiler('on Chrome', (compilerArgs) async {
      var pub = await runPubServe(args: compilerArgs);
      var test = await runTest([_pubServeArg, '-p', 'chrome']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    }, tags: 'chrome');
  });

  group('with a failing test', () {
    setUp(() async {
      await d.file('test/my_test.dart', '''
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test("failure", () => throw 'oh no');
}
''').create();
    });

    group('dartifies stack traces for JS-compiled tests by default', () {
      test('on a browser', () async {
        var pub = await runPubServe();
        var test =
            await runTest([_pubServeArg, '-p', 'chrome', '--verbose-trace']);
        expect(
            test.stdout,
            containsInOrder(
                [' main.<fn>', 'package:test', 'dart:async/zone.dart']));
        await test.shouldExit(1);
        await pub.kill();
      }, tags: 'chrome');

      test('on Node', () async {
        var pub = await runPubServe();
        var test =
            await runTest([_pubServeArg, '-p', 'node', '--verbose-trace']);
        expect(
            test.stdout,
            containsInOrder(
                [' main.<fn>', 'package:test', 'dart:async/zone.dart']));
        await test.shouldExit(1);
        await pub.kill();
      }, tags: 'node');
    });

    group("doesn't dartify stack traces for JS-compiled tests with --js-trace",
        () {
      test('on a browser', () async {
        var pub = await runPubServe();
        var test = await runTest(
            [_pubServeArg, '-p', 'chrome', '--js-trace', '--verbose-trace']);

        expect(test.stdoutStream(), neverEmits(endsWith(' main.<fn>')));
        expect(test.stdoutStream(), neverEmits(contains('package:test')));
        expect(
            test.stdoutStream(), neverEmits(contains('dart:async/zone.dart')));
        expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
        await test.shouldExit(1);

        await pub.kill();
      }, tags: 'chrome');

      test('on Node', () async {
        var pub = await runPubServe();
        var test = await runTest(
            [_pubServeArg, '-p', 'node', '--js-trace', '--verbose-trace']);

        expect(test.stdoutStream(), neverEmits(endsWith(' main.<fn>')));
        expect(test.stdoutStream(), neverEmits(contains('package:test')));
        expect(
            test.stdoutStream(), neverEmits(contains('dart:async/zone.dart')));
        expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
        await test.shouldExit(1);

        await pub.kill();
      }, tags: 'node');
    });
  });

  test('gracefully handles pub serve not running for VM tests', () async {
    var test = await runTest(['--pub-serve=54321']);
    expect(
        test.stdout,
        containsInOrder([
          '-1: loading ${p.join("test", "my_test.dart")} [E]',
          'Failed to load "${p.join("test", "my_test.dart")}":',
          'Error getting http://localhost:54321/my_test.dart.vm_test.dart: '
              'Connection refused',
          'Make sure "pub serve" is running.'
        ]));
    await test.shouldExit(1);
  });

  test('gracefully handles pub serve not running for browser tests', () async {
    var test = await runTest(['--pub-serve=54321', '-p', 'chrome']);
    var message = Platform.isWindows
        ? 'The remote computer refused the network connection.'
        : 'Connection refused (errno ';

    expect(
        test.stdout,
        containsInOrder([
          '-1: compiling ${p.join("test", "my_test.dart")} [E]',
          'Failed to load "${p.join("test", "my_test.dart")}":',
          'Error getting http://localhost:54321/my_test.dart.browser_test.dart.js'
              '.map: $message',
          'Make sure "pub serve" is running.'
        ]));
    await test.shouldExit(1);
  }, tags: 'chrome');

  test('gracefully handles pub serve not running for Node tests', () async {
    var test = await runTest(['--pub-serve=54321', '-p', 'node']);
    var message = Platform.isWindows
        ? 'The remote computer refused the network connection.'
        : 'Connection refused (errno ';

    expect(
        test.stdout,
        containsInOrder([
          '-1: compiling ${p.join("test", "my_test.dart")} [E]',
          'Failed to load "${p.join("test", "my_test.dart")}":',
          'Error getting http://localhost:54321/my_test.dart.node_test.dart.js:'
              ' $message',
          'Make sure "pub serve" is running.'
        ]));
    await test.shouldExit(1);
  }, tags: 'node');

  test('gracefully handles a test file not being in test/', () async {
    File(p.join(d.sandbox, 'test/my_test.dart'))
        .copySync(p.join(d.sandbox, 'my_test.dart'));

    var test = await runTest(['--pub-serve=54321', 'my_test.dart']);
    expect(
        test.stdout,
        containsInOrder([
          '-1: loading my_test.dart [E]',
          'Failed to load "my_test.dart": When using "pub serve", all test files '
              'must be in test/.'
        ]));
    await test.shouldExit(1);
  });
}

/// The list of supported compilers for the current [Platform.version].
final Iterable<String> _compilers = ['dart2js', 'dartdevc'];

/// Runs the test described by [testFn] once for each supported compiler on the
/// current [Platform.version], passing the relevant compiler args for pub serve
/// as the first argument.
void testWithCompiler(
    String name, dynamic Function(List<String> compilerArgs) testFn,
    {tags}) {
  for (var compiler in _compilers) {
    var compilerArgs = ['--web-compiler', compiler];
    test('$name with $compiler', () => testFn(compilerArgs), tags: tags);
  }
}
