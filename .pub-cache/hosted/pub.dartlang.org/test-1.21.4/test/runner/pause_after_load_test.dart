// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@OnPlatform({'windows': Skip('https://github.com/dart-lang/test/issues/1613')})

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('pauses the test runner for each file until the user presses enter',
      () async {
    await d.file('test1.dart', '''
import 'package:test/test.dart';

void main() {
  print('loaded test 1!');

  test("success", () {});
}
''').create();

    await d.file('test2.dart', '''
import 'package:test/test.dart';

void main() {

  print('loaded test 2!');
  test("success", () {});
}
''').create();

    var test = await runTest(
        ['--pause-after-load', '-p', 'chrome', 'test1.dart', 'test2.dart']);
    await expectLater(test.stdout, emitsThrough('loaded test 1!'));
    await expectLater(test.stdout, emitsThrough(equalsIgnoringWhitespace('''
      The test runner is paused. Open the dev console in Chrome and set
      breakpoints. Once you're finished, return to this terminal and press
      Enter.
    ''')));

    var nextLineFired = false;
    unawaited(test.stdout.next.then(expectAsync1((line) {
      expect(line, contains('+0: test1.dart: success'));
      nextLineFired = true;
    })));

    // Wait a little bit to be sure that the tests don't start running without
    // our input.
    await Future.delayed(Duration(seconds: 2));
    expect(nextLineFired, isFalse);

    test.stdin.writeln();

    await expectLater(test.stdout, emitsThrough('loaded test 2!'));
    await expectLater(test.stdout, emitsThrough(equalsIgnoringWhitespace('''
      The test runner is paused. Open the dev console in Chrome and set
      breakpoints. Once you're finished, return to this terminal and press
      Enter.
    ''')));

    nextLineFired = false;
    unawaited(test.stdout.next.then(expectAsync1((line) {
      expect(line, contains('+1: test2.dart: success'));
      nextLineFired = true;
    })));

    // Wait a little bit to be sure that the tests don't start running without
    // our input.
    await Future.delayed(Duration(seconds: 2));
    expect(nextLineFired, isFalse);

    test.stdin.writeln();
    await expectLater(
        test.stdout, emitsThrough(contains('+2: All tests passed!')));
    await test.shouldExit(0);
  }, tags: 'chrome');

  test('pauses the test runner for each platform until the user presses enter',
      () async {
    await d.file('test.dart', '''
import 'package:test/test.dart';

void main() {
  print('loaded test!');

  test("success", () {});
}
''').create();

    var test = await runTest([
      '--pause-after-load',
      '-p',
      'firefox',
      '-p',
      'chrome',
      '-p',
      'vm',
      'test.dart'
    ]);
    await expectLater(test.stdout, emitsThrough('loaded test!'));
    await expectLater(test.stdout, emitsThrough(equalsIgnoringWhitespace('''
      The test runner is paused. Open the dev console in Firefox and set
      breakpoints. Once you're finished, return to this terminal and press
      Enter.
    ''')));

    var nextLineFired = false;
    unawaited(test.stdout.next.then(expectAsync1((line) {
      expect(line, contains('+0: [Firefox] success'));
      nextLineFired = true;
    })));

    // Wait a little bit to be sure that the tests don't start running without
    // our input.
    await Future.delayed(Duration(seconds: 2));
    expect(nextLineFired, isFalse);

    test.stdin.writeln();

    await expectLater(test.stdout, emitsThrough('loaded test!'));
    await expectLater(
        test.stdout,
        emitsThrough(emitsInOrder([
          'The test runner is paused. Open the dev console in Chrome and set '
              "breakpoints. Once you're finished, return to this terminal and "
              'press Enter.'
        ])));

    nextLineFired = false;
    unawaited(test.stdout.next.then(expectAsync1((line) {
      expect(line, contains('+1: [Chrome] success'));
      nextLineFired = true;
    })));

    // Wait a little bit to be sure that the tests don't start running without
    // our input.
    await Future.delayed(Duration(seconds: 2));
    expect(nextLineFired, isFalse);

    test.stdin.writeln();
    await expectLater(test.stdout, emitsThrough('loaded test!'));
    await expectLater(
        test.stdout,
        emitsThrough(emitsInOrder([
          'The test runner is paused. Open the Observatory and set '
              "breakpoints. Once you're finished, return to this terminal "
              'and press Enter.'
        ])));

    nextLineFired = false;
    unawaited(test.stdout.next.then(expectAsync1((line) {
      expect(line, contains('+2: [VM] success'));
      nextLineFired = true;
    })));

    // Wait a little bit to be sure that the tests don't start running without
    // our input.
    await Future.delayed(Duration(seconds: 2));
    expect(nextLineFired, isFalse);

    test.stdin.writeln();

    await expectLater(
        test.stdout, emitsThrough(contains('+3: All tests passed!')));
    await test.shouldExit(0);
  }, tags: ['firefox', 'chrome', 'vm']);

  test('stops immediately if killed while paused', () async {
    await d.file('test.dart', '''
import 'package:test/test.dart';

void main() {
  print('loaded test!');

  test("success", () {});
}
''').create();

    var test =
        await runTest(['--pause-after-load', '-p', 'chrome', 'test.dart']);
    await expectLater(test.stdout, emitsThrough('loaded test!'));
    await expectLater(test.stdout, emitsThrough(equalsIgnoringWhitespace('''
      The test runner is paused. Open the dev console in Chrome and set
      breakpoints. Once you're finished, return to this terminal and press
      Enter.
    ''')));

    test.signal(ProcessSignal.sigterm);
    await test.shouldExit();
    await expectLater(test.stderr, emitsDone);
  }, tags: 'chrome', testOn: '!windows');

  test('disables timeouts', () async {
    await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  print('loaded test 1!');

  test("success", () async {
    await Future.delayed(Duration.zero);
  }, timeout: Timeout(Duration.zero));
}
''').create();

    var test = await runTest(
        ['--pause-after-load', '-p', 'chrome', '-n', 'success', 'test.dart']);
    await expectLater(test.stdout, emitsThrough('loaded test 1!'));
    await expectLater(test.stdout, emitsThrough(equalsIgnoringWhitespace('''
      The test runner is paused. Open the dev console in Chrome and set
      breakpoints. Once you're finished, return to this terminal and press
      Enter.
    ''')));

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
  }, tags: 'chrome');

  // Regression test for #304.
  test('supports test name patterns', () async {
    await d.file('test.dart', '''
import 'package:test/test.dart';

void main() {
  print('loaded test 1!');

  test("failure 1", () {});
  test("success", () {});
  test("failure 2", () {});
}
''').create();

    var test = await runTest(
        ['--pause-after-load', '-p', 'chrome', '-n', 'success', 'test.dart']);
    await expectLater(test.stdout, emitsThrough('loaded test 1!'));
    await expectLater(test.stdout, emitsThrough(equalsIgnoringWhitespace('''
      The test runner is paused. Open the dev console in Chrome and set
      breakpoints. Once you're finished, return to this terminal and press
      Enter.
    ''')));

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
  }, tags: 'chrome');
}
