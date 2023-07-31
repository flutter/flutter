// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'utils.dart';

void main() {
  compileFormatterExecutable();

  test('formats a directory', () async {
    await d.dir('code', [
      d.file('a.dart', unformattedSource),
      d.file('b.dart', formattedSource),
      d.file('c.dart', unformattedSource)
    ]).create();

    var process = await runFormatterOnDir();
    await expectLater(
        process.stdout, emits(startsWith('Formatting directory')));

    // Prints the formatting result.
    await expectLater(process.stdout, emits(formattedOutput));
    await expectLater(process.stdout, emits(formattedOutput));
    await expectLater(process.stdout, emits(formattedOutput));
    await process.shouldExit(0);

    // Does not overwrite by default.
    await d.dir('code', [d.file('a.dart', unformattedSource)]).validate();
    await d.dir('code', [d.file('c.dart', unformattedSource)]).validate();
  });

  test('Overwrites files', () async {
    await d.dir('code', [
      d.file('a.dart', unformattedSource),
      d.file('b.dart', formattedSource),
      d.file('c.dart', unformattedSource)
    ]).create();

    var process = await runFormatterOnDir(['--overwrite']);
    await expectLater(
        process.stdout, emits(startsWith('Formatting directory')));

    // Prints whether each file was changed.
    await expectLater(
        process.stdout, emits('Formatted ${p.join('code', 'a.dart')}'));
    await expectLater(
        process.stdout, emits('Unchanged ${p.join('code', 'b.dart')}'));
    await expectLater(
        process.stdout, emits('Formatted ${p.join('code', 'c.dart')}'));
    await process.shouldExit(0);

    // Overwrites the files.
    await d.dir('code', [d.file('a.dart', formattedSource)]).validate();
    await d.dir('code', [d.file('c.dart', formattedSource)]).validate();
  });

  test('exits with 64 on a command line argument error', () async {
    var process = await runFormatter(['-wat']);
    await process.shouldExit(64);
  });

  test('exits with 65 on a parse error', () async {
    await d.dir('code', [d.file('a.dart', 'herp derp i are a dart')]).create();

    var process = await runFormatterOnDir();
    await process.shouldExit(65);
  });

  test('errors if --dry-run and --overwrite are both passed', () async {
    var process = await runFormatter(['--dry-run', '--overwrite']);
    await process.shouldExit(64);
  });

  test('errors if --dry-run and --machine are both passed', () async {
    var process = await runFormatter(['--dry-run', '--machine']);
    await process.shouldExit(64);
  });

  test('errors if --machine and --overwrite are both passed', () async {
    var process = await runFormatter(['--machine', '--overwrite']);
    await process.shouldExit(64);
  });

  test('errors if --dry-run and --machine are both passed', () async {
    var process = await runFormatter(['--dry-run', '--machine']);
    await process.shouldExit(64);
  });

  test('errors if --machine and --overwrite are both passed', () async {
    var process = await runFormatter(['--machine', '--overwrite']);
    await process.shouldExit(64);
  });

  test('errors if --stdin-name and a path are both passed', () async {
    var process = await runFormatter(['--stdin-name=name', 'path.dart']);
    await process.shouldExit(64);
  });

  test('--version prints the version number', () async {
    var process = await runFormatter(['--version']);

    // Match something roughly semver-like.
    expect(await process.stdout.next, matches(RegExp(r'\d+\.\d+\.\d+.*')));
    await process.shouldExit(0);
  });

  group('--help', () {
    test('non-verbose shows description and common options', () async {
      var process = await runFormatter(['--help']);
      await expectLater(
          process.stdout, emits('Idiomatically format Dart source code.'));
      await expectLater(process.stdout, emits(''));
      await expectLater(process.stdout,
          emits('Usage:   dartfmt [options...] [files or directories...]'));
      await expectLater(process.stdout, emitsThrough(contains('--overwrite')));
      await expectLater(
          process.stdout, emitsThrough(contains('--set-exit-if-changed')));
      await expectLater(process.stdout, emitsThrough(contains('--fix')));
      await process.shouldExit(0);
    });

    test('verbose shows description and all options', () async {
      var process = await runFormatter(['--help', '--verbose']);
      await expectLater(
          process.stdout, emits('Idiomatically format Dart source code.'));
      await expectLater(process.stdout, emits(''));
      await expectLater(process.stdout,
          emits('Usage:   dartfmt [options...] [files or directories...]'));
      await expectLater(process.stdout, emitsThrough(contains('--overwrite')));
      await expectLater(
          process.stdout, emitsThrough(contains('--set-exit-if-changed')));
      await expectLater(process.stdout, emitsThrough(contains('--fix')));
      await process.shouldExit(0);
    });
  });

  test('--verbose errors if not used with --help', () async {
    var process = await runFormatterOnDir(['--verbose']);
    expect(await process.stdout.next, 'Can only use --verbose with --help.');
    await process.shouldExit(64);
  });

  test('only prints a hidden directory once', () async {
    await d.dir('code', [
      d.dir('.skip', [
        d.file('a.dart', unformattedSource),
        d.file('b.dart', unformattedSource)
      ])
    ]).create();

    var process = await runFormatterOnDir();

    expect(await process.stdout.next, startsWith('Formatting directory'));
    expect(await process.stdout.next,
        "Skipping hidden path ${p.join("code", ".skip")}");
    await process.shouldExit();
  });

  group('--dry-run', () {
    test('prints names of files that would change', () async {
      await d.dir('code', [
        d.file('a_bad.dart', unformattedSource),
        d.file('b_good.dart', formattedSource),
        d.file('c_bad.dart', unformattedSource),
        d.file('d_good.dart', formattedSource)
      ]).create();

      var aBad = p.join('code', 'a_bad.dart');
      var cBad = p.join('code', 'c_bad.dart');

      var process = await runFormatterOnDir(['--dry-run']);

      // The order isn't specified.
      expect(await process.stdout.next, anyOf(aBad, cBad));
      expect(await process.stdout.next, anyOf(aBad, cBad));
      await process.shouldExit();
    });

    test('does not modify files', () async {
      await d.dir('code', [d.file('a.dart', unformattedSource)]).create();

      var process = await runFormatterOnDir(['--dry-run']);
      expect(await process.stdout.next, p.join('code', 'a.dart'));
      await process.shouldExit();

      await d.dir('code', [d.file('a.dart', unformattedSource)]).validate();
    });
  });

  group('--machine', () {
    test('writes each output as json', () async {
      await d.dir('code', [
        d.file('a.dart', unformattedSource),
        d.file('b.dart', unformattedSource)
      ]).create();

      var jsonA = jsonEncode({
        'path': p.join('code', 'a.dart'),
        'source': formattedSource,
        'selection': {'offset': -1, 'length': -1}
      });

      var jsonB = jsonEncode({
        'path': p.join('code', 'b.dart'),
        'source': formattedSource,
        'selection': {'offset': -1, 'length': -1}
      });

      var process = await runFormatterOnDir(['--machine']);

      // The order isn't specified.
      expect(await process.stdout.next, anyOf(jsonA, jsonB));
      expect(await process.stdout.next, anyOf(jsonA, jsonB));
      await process.shouldExit();
    });
  });

  group('--preserve', () {
    test('errors if given paths', () async {
      var process = await runFormatter(['--preserve', 'path', 'another']);
      await process.shouldExit(64);
    });

    test('errors on wrong number of components', () async {
      var process = await runFormatter(['--preserve', '1']);
      await process.shouldExit(64);

      process = await runFormatter(['--preserve', '1:2:3']);
      await process.shouldExit(64);
    });

    test('errors on non-integer component', () async {
      var process = await runFormatter(['--preserve', '1:2.3']);
      await process.shouldExit(64);
    });

    test('updates selection', () async {
      var process = await runFormatter(['--preserve', '6:10', '-m']);
      process.stdin.writeln(unformattedSource);
      await process.stdin.close();

      var json = jsonEncode({
        'path': 'stdin',
        'source': formattedSource,
        'selection': {'offset': 5, 'length': 9}
      });

      expect(await process.stdout.next, json);
      await process.shouldExit();
    });
  });

  group('--indent', () {
    test('sets the leading indentation of the output', () async {
      var process = await runFormatter(['--indent', '3']);
      process.stdin.writeln("main() {'''");
      process.stdin.writeln("a flush left multi-line string''';}");
      await process.stdin.close();

      expect(await process.stdout.next, '   main() {');
      expect(await process.stdout.next, "     '''");
      expect(await process.stdout.next, "a flush left multi-line string''';");
      expect(await process.stdout.next, '   }');
      await process.shouldExit(0);
    });

    test('errors if the indent is not a non-negative number', () async {
      var process = await runFormatter(['--indent', 'notanum']);
      await process.shouldExit(64);

      process = await runFormatter(['--indent', '-4']);
      await process.shouldExit(64);
    });
  });

  group('--set-exit-if-changed', () {
    test('gives exit code 0 if there are no changes', () async {
      await d.dir('code', [d.file('a.dart', formattedSource)]).create();

      var process = await runFormatterOnDir(['--set-exit-if-changed']);
      await process.shouldExit(0);
    });

    test('gives exit code 1 if there are changes', () async {
      await d.dir('code', [d.file('a.dart', unformattedSource)]).create();

      var process = await runFormatterOnDir(['--set-exit-if-changed']);
      await process.shouldExit(1);
    });

    test('gives exit code 1 if there are changes even in dry run', () async {
      await d.dir('code', [d.file('a.dart', unformattedSource)]).create();

      var process =
          await runFormatterOnDir(['--set-exit-if-changed', '--dry-run']);
      await process.shouldExit(1);
    });
  });

  group('fix', () {
    test('--fix applies all fixes', () async {
      var process = await runFormatter(['--fix']);
      process.stdin.writeln('foo({a:1}) {');
      process.stdin.writeln('  new Bar(const Baz(const []));}');
      await process.stdin.close();

      expect(await process.stdout.next, 'foo({a = 1}) {');
      expect(await process.stdout.next, '  Bar(const Baz([]));');
      expect(await process.stdout.next, '}');
      await process.shouldExit(0);
    });

    test('--fix-named-default-separator', () async {
      var process = await runFormatter(['--fix-named-default-separator']);
      process.stdin.writeln('foo({a:1}) {');
      process.stdin.writeln('  new Bar();}');
      await process.stdin.close();

      expect(await process.stdout.next, 'foo({a = 1}) {');
      expect(await process.stdout.next, '  new Bar();');
      expect(await process.stdout.next, '}');
      await process.shouldExit(0);
    });

    test('--fix-optional-const', () async {
      var process = await runFormatter(['--fix-optional-const']);
      process.stdin.writeln('foo({a:1}) {');
      process.stdin.writeln('  const Bar(const Baz());}');
      await process.stdin.close();

      expect(await process.stdout.next, 'foo({a: 1}) {');
      expect(await process.stdout.next, '  const Bar(Baz());');
      expect(await process.stdout.next, '}');
      await process.shouldExit(0);
    });

    test('--fix-optional-new', () async {
      var process = await runFormatter(['--fix-optional-new']);
      process.stdin.writeln('foo({a:1}) {');
      process.stdin.writeln('  new Bar();}');
      await process.stdin.close();

      expect(await process.stdout.next, 'foo({a: 1}) {');
      expect(await process.stdout.next, '  Bar();');
      expect(await process.stdout.next, '}');
      await process.shouldExit(0);
    });

    test('errors with --fix and specific fix flag', () async {
      var process =
          await runFormatter(['--fix', '--fix-named-default-separator']);
      await process.shouldExit(64);
    });
  });

  group('with no paths', () {
    test('errors on --overwrite', () async {
      var process = await runFormatter(['--overwrite']);
      await process.shouldExit(64);
    });

    test('exits with 65 on parse error', () async {
      var process = await runFormatter();
      process.stdin.writeln('herp derp i are a dart');
      await process.stdin.close();
      await process.shouldExit(65);
    });

    test('reads from stdin', () async {
      var process = await runFormatter();
      process.stdin.writeln(unformattedSource);
      await process.stdin.close();

      // No trailing newline at the end.
      expect(await process.stdout.next, formattedOutput);
      await process.shouldExit(0);
    });

    test('allows specifying stdin path name', () async {
      var path = p.join('some', 'path.dart');
      var process = await runFormatter(['--stdin-name=$path']);
      process.stdin.writeln('herp');
      await process.stdin.close();

      expect(await process.stderr.next,
          'Could not format because the source could not be parsed:');
      expect(await process.stderr.next, '');
      expect(await process.stderr.next, contains(path));
      await process.stderr.cancel();
      await process.shouldExit(65);
    });
  });
}
