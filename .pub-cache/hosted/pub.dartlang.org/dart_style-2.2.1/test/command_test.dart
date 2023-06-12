// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'utils.dart';

void main() {
  compileCommandExecutable();

  test('formats a directory', () async {
    await d.dir('code', [
      d.file('a.dart', unformattedSource),
      d.file('b.dart', formattedSource),
      d.file('c.dart', unformattedSource)
    ]).create();

    var process = await runCommandOnDir();
    expect(await process.stdout.next, 'Formatted ${p.join('code', 'a.dart')}');
    expect(await process.stdout.next, 'Formatted ${p.join('code', 'c.dart')}');
    expect(await process.stdout.next,
        startsWith(r'Formatted 3 files (2 changed)'));
    await process.shouldExit(0);

    // Overwrites the files.
    await d.dir('code', [d.file('a.dart', formattedSource)]).validate();
    await d.dir('code', [d.file('c.dart', formattedSource)]).validate();
  });

  test('formats multiple paths', () async {
    await d.dir('code', [
      d.dir('subdir', [
        d.file('a.dart', unformattedSource),
      ]),
      d.file('b.dart', unformattedSource),
      d.file('c.dart', unformattedSource)
    ]).create();

    var process =
        await runCommand([p.join('code', 'subdir'), p.join('code', 'c.dart')]);
    expect(await process.stdout.next,
        'Formatted ${p.join('code', 'subdir', 'a.dart')}');
    expect(await process.stdout.next, 'Formatted ${p.join('code', 'c.dart')}');
    expect(await process.stdout.next,
        startsWith(r'Formatted 2 files (2 changed)'));
    await process.shouldExit(0);

    // Overwrites the selected files.
    await d.dir('code', [
      d.dir('subdir', [
        d.file('a.dart', formattedSource),
      ]),
      d.file('b.dart', unformattedSource),
      d.file('c.dart', formattedSource)
    ]).validate();
  });

  test('exits with 64 on a command line argument error', () async {
    var process = await runCommand(['-wat']);
    await process.shouldExit(64);
  });

  test('exits with 65 on a parse error', () async {
    await d.dir('code', [d.file('a.dart', 'herp derp i are a dart')]).create();

    var process = await runCommandOnDir();
    await process.shouldExit(65);
  });

  group('--show', () {
    test('all shows all files', () async {
      await d.dir('code', [
        d.file('a.dart', unformattedSource),
        d.file('b.dart', formattedSource),
        d.file('c.dart', unformattedSource)
      ]).create();

      var process = await runCommandOnDir(['--show=all']);
      expect(
          await process.stdout.next, 'Formatted ${p.join('code', 'a.dart')}');
      expect(
          await process.stdout.next, 'Unchanged ${p.join('code', 'b.dart')}');
      expect(
          await process.stdout.next, 'Formatted ${p.join('code', 'c.dart')}');
      expect(await process.stdout.next,
          startsWith(r'Formatted 3 files (2 changed)'));
      await process.shouldExit(0);
    });

    test('none shows nothing', () async {
      await d.dir('code', [
        d.file('a.dart', unformattedSource),
        d.file('b.dart', formattedSource),
        d.file('c.dart', unformattedSource)
      ]).create();

      var process = await runCommandOnDir(['--show=none']);
      expect(await process.stdout.next,
          startsWith(r'Formatted 3 files (2 changed)'));
      await process.shouldExit(0);
    });

    test('changed shows changed files', () async {
      await d.dir('code', [
        d.file('a.dart', unformattedSource),
        d.file('b.dart', formattedSource),
        d.file('c.dart', unformattedSource)
      ]).create();

      var process = await runCommandOnDir(['--show=changed']);
      expect(
          await process.stdout.next, 'Formatted ${p.join('code', 'a.dart')}');
      expect(
          await process.stdout.next, 'Formatted ${p.join('code', 'c.dart')}');
      expect(await process.stdout.next,
          startsWith(r'Formatted 3 files (2 changed)'));
      await process.shouldExit(0);
    });
  });

  group('--output', () {
    group('show', () {
      test('prints only formatted output by default', () async {
        await d.dir('code', [
          d.file('a.dart', unformattedSource),
          d.file('b.dart', formattedSource)
        ]).create();

        var process = await runCommandOnDir(['--output=show']);
        expect(await process.stdout.next, formattedOutput);
        expect(await process.stdout.next, formattedOutput);
        expect(await process.stdout.next,
            startsWith(r'Formatted 2 files (1 changed)'));
        await process.shouldExit(0);

        // Does not overwrite files.
        await d.dir('code', [d.file('a.dart', unformattedSource)]).validate();
      });

      test('with --show=all prints all files and names first', () async {
        await d.dir('code', [
          d.file('a.dart', unformattedSource),
          d.file('b.dart', formattedSource)
        ]).create();

        var process = await runCommandOnDir(['--output=show', '--show=all']);
        expect(
            await process.stdout.next, 'Changed ${p.join('code', 'a.dart')}');
        expect(await process.stdout.next, formattedOutput);
        expect(
            await process.stdout.next, 'Unchanged ${p.join('code', 'b.dart')}');
        expect(await process.stdout.next, formattedOutput);
        expect(await process.stdout.next,
            startsWith(r'Formatted 2 files (1 changed)'));
        await process.shouldExit(0);

        // Does not overwrite files.
        await d.dir('code', [d.file('a.dart', unformattedSource)]).validate();
      });

      test('with --show=changed prints only changed files', () async {
        await d.dir('code', [
          d.file('a.dart', unformattedSource),
          d.file('b.dart', formattedSource)
        ]).create();

        var process =
            await runCommandOnDir(['--output=show', '--show=changed']);
        expect(
            await process.stdout.next, 'Changed ${p.join('code', 'a.dart')}');
        expect(await process.stdout.next, formattedOutput);
        expect(await process.stdout.next,
            startsWith(r'Formatted 2 files (1 changed)'));
        await process.shouldExit(0);

        // Does not overwrite files.
        await d.dir('code', [d.file('a.dart', unformattedSource)]).validate();
      });
    });

    group('json', () {
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

        var process = await runCommandOnDir(['--output=json']);

        expect(await process.stdout.next, jsonA);
        expect(await process.stdout.next, jsonB);
        await process.shouldExit();
      });

      test('errors if the summary is not none', () async {
        var process =
            await runCommandOnDir(['--output=json', '--summary=line']);
        await process.shouldExit(64);
      });
    });

    group('none', () {
      test('with --show=all prints only names', () async {
        await d.dir('code', [
          d.file('a.dart', unformattedSource),
          d.file('b.dart', formattedSource)
        ]).create();

        var process = await runCommandOnDir(['--output=none', '--show=all']);
        expect(
            await process.stdout.next, 'Changed ${p.join('code', 'a.dart')}');
        expect(
            await process.stdout.next, 'Unchanged ${p.join('code', 'b.dart')}');
        expect(await process.stdout.next,
            startsWith(r'Formatted 2 files (1 changed)'));
        await process.shouldExit(0);

        // Does not overwrite files.
        await d.dir('code', [d.file('a.dart', unformattedSource)]).validate();
      });

      test('with --show=changed prints only changed names', () async {
        await d.dir('code', [
          d.file('a.dart', unformattedSource),
          d.file('b.dart', formattedSource)
        ]).create();

        var process =
            await runCommandOnDir(['--output=none', '--show=changed']);
        expect(
            await process.stdout.next, 'Changed ${p.join('code', 'a.dart')}');
        expect(await process.stdout.next,
            startsWith(r'Formatted 2 files (1 changed)'));
        await process.shouldExit(0);

        // Does not overwrite files.
        await d.dir('code', [d.file('a.dart', unformattedSource)]).validate();
      });
    });
  });

  group('--summary', () {
    test('line', () async {
      await d.dir('code', [
        d.file('a.dart', unformattedSource),
        d.file('b.dart', formattedSource)
      ]).create();

      var process = await runCommandOnDir(['--summary=line']);
      expect(
          await process.stdout.next, 'Formatted ${p.join('code', 'a.dart')}');
      expect(await process.stdout.next,
          matches(r'Formatted 2 files \(1 changed\) in \d+\.\d+ seconds.'));
      await process.shouldExit(0);
    });
  });

  test('--version prints the version number', () async {
    var process = await runCommand(['--version']);

    // Match something roughly semver-like.
    expect(await process.stdout.next, matches(RegExp(r'\d+\.\d+\.\d+.*')));
    await process.shouldExit(0);
  });

  group('--help', () {
    test('non-verbose shows description and common options', () async {
      var process = await runCommand(['--help']);
      expect(
          await process.stdout.next, 'Idiomatically format Dart source code.');
      await expectLater(process.stdout, emitsThrough(contains('-o, --output')));
      await expectLater(process.stdout, emitsThrough(contains('--fix')));
      await expectLater(process.stdout, neverEmits(contains('--summary')));
      await process.shouldExit(0);
    });

    test('verbose shows description and all options', () async {
      var process = await runCommand(['--help', '--verbose']);
      expect(
          await process.stdout.next, 'Idiomatically format Dart source code.');
      await expectLater(process.stdout, emitsThrough(contains('-o, --output')));
      await expectLater(process.stdout, emitsThrough(contains('--show')));
      await expectLater(process.stdout, emitsThrough(contains('--summary')));
      await expectLater(process.stdout, emitsThrough(contains('--fix')));
      await process.shouldExit(0);
    });
  });

  test('--verbose errors if not used with --help', () async {
    var process = await runCommandOnDir(['--verbose']);
    expect(await process.stderr.next, 'Can only use --verbose with --help.');
    await process.shouldExit(64);
  });

  group('fix', () {
    test('--fix applies all fixes', () async {
      var process = await runCommand(['--fix', '--output=show']);
      process.stdin.writeln('foo({a:1}) {');
      process.stdin.writeln('  new Bar(const Baz(const []));}');
      await process.stdin.close();

      expect(await process.stdout.next, 'foo({a = 1}) {');
      expect(await process.stdout.next, '  Bar(const Baz([]));');
      expect(await process.stdout.next, '}');
      await process.shouldExit(0);
    });

    test('--fix-named-default-separator', () async {
      var process =
          await runCommand(['--fix-named-default-separator', '--output=show']);
      process.stdin.writeln('foo({a:1}) {');
      process.stdin.writeln('  new Bar();}');
      await process.stdin.close();

      expect(await process.stdout.next, 'foo({a = 1}) {');
      expect(await process.stdout.next, '  new Bar();');
      expect(await process.stdout.next, '}');
      await process.shouldExit(0);
    });

    test('--fix-optional-const', () async {
      var process = await runCommand(['--fix-optional-const', '--output=show']);
      process.stdin.writeln('foo({a:1}) {');
      process.stdin.writeln('  const Bar(const Baz());}');
      await process.stdin.close();

      expect(await process.stdout.next, 'foo({a: 1}) {');
      expect(await process.stdout.next, '  const Bar(Baz());');
      expect(await process.stdout.next, '}');
      await process.shouldExit(0);
    });

    test('--fix-optional-new', () async {
      var process = await runCommand(['--fix-optional-new', '--output=show']);
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
          await runCommand(['--fix', '--fix-named-default-separator']);
      await process.shouldExit(64);
    });
  });

  group('--indent', () {
    test('sets the leading indentation of the output', () async {
      var process = await runCommand(['--indent=3']);
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
      var process = await runCommand(['--indent=notanum']);
      await process.shouldExit(64);

      process = await runCommand(['--indent=-4']);
      await process.shouldExit(64);
    });
  });

  group('--set-exit-if-changed', () {
    test('gives exit code 0 if there are no changes', () async {
      await d.dir('code', [d.file('a.dart', formattedSource)]).create();

      var process = await runCommandOnDir(['--set-exit-if-changed']);
      await process.shouldExit(0);
    });

    test('gives exit code 1 if there are changes', () async {
      await d.dir('code', [d.file('a.dart', unformattedSource)]).create();

      var process = await runCommandOnDir(['--set-exit-if-changed']);
      await process.shouldExit(1);
    });

    test('gives exit code 1 if there are changes when not writing', () async {
      await d.dir('code', [d.file('a.dart', unformattedSource)]).create();

      var process =
          await runCommandOnDir(['--set-exit-if-changed', '--show=none']);
      await process.shouldExit(1);
    });
  });

  group('--selection', () {
    test('errors if given path', () async {
      var process = await runCommand(['--selection', 'path']);
      await process.shouldExit(64);
    });

    test('errors on wrong number of components', () async {
      var process = await runCommand(['--selection', '1']);
      await process.shouldExit(64);

      process = await runCommand(['--selection', '1:2:3']);
      await process.shouldExit(64);
    });

    test('errors on non-integer component', () async {
      var process = await runCommand(['--selection', '1:2.3']);
      await process.shouldExit(64);
    });

    test('updates selection', () async {
      var process = await runCommand(['--output=json', '--selection=6:10']);
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

  group('--stdin-name', () {
    test('errors if given path', () async {
      var process = await runCommand(['--stdin-name=name', 'path']);
      await process.shouldExit(64);
    });
  });

  group('with no paths', () {
    test('errors on --output=write', () async {
      var process = await runCommand(['--output=write']);
      await process.shouldExit(64);
    });

    test('exits with 65 on parse error', () async {
      var process = await runCommand();
      process.stdin.writeln('herp derp i are a dart');
      await process.stdin.close();
      await process.shouldExit(65);
    });

    test('reads from stdin', () async {
      var process = await runCommand();
      process.stdin.writeln(unformattedSource);
      await process.stdin.close();

      // No trailing newline at the end.
      expect(await process.stdout.next, formattedOutput);
      await process.shouldExit(0);
    });

    test('allows specifying stdin path name', () async {
      var path = p.join('some', 'path.dart');
      var process = await runCommand(['--stdin-name=$path']);
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
