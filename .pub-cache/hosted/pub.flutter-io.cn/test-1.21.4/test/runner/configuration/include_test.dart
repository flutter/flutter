// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_core/src/runner/configuration.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  test('should merge with a base configuration', () async {
    await d.dir('repo', [
      d.file('dart_test_base.yaml', 'filename: "test_*.dart"'),
      d.dir('pkg', [
        d.file('dart_test.yaml', '''
          include: ../dart_test_base.yaml
          concurrency: 3
        '''),
      ]),
    ]).create();

    var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
    var config = Configuration.load(path);
    expect(config.filename.pattern, equals('test_*.dart'));
    expect(config.concurrency, equals(3));
  });

  test('should merge fields with a base configuration', () async {
    await d.dir('repo', [
      d.file('dart_test_base.yaml', '''
        tags:
          hello:
      '''),
      d.dir('pkg', [
        d.file('dart_test.yaml', '''
          include: ../dart_test_base.yaml
          tags:
            world:
        '''),
      ]),
    ]).create();

    var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
    var config = Configuration.load(path);
    expect(config.knownTags, unorderedEquals(['hello', 'world']));
  });

  test('should allow an included file to include a file', () async {
    await d.dir('repo', [
      d.file('dart_test_base_base.yaml', '''
        tags:
          tag:
      '''),
      d.file('dart_test_base.yaml', '''
        include: dart_test_base_base.yaml
        filename: "test_*.dart"
      '''),
      d.dir('pkg', [
        d.file('dart_test.yaml', '''
          include: ../dart_test_base.yaml
          concurrency: 3
        '''),
      ]),
    ]).create();

    var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
    var config = Configuration.load(path);
    expect(config.knownTags, ['tag']);
    expect(config.filename.pattern, 'test_*.dart');
    expect(config.concurrency, 3);
  });

  test('should not allow an include field in a test config context', () async {
    await d.dir('repo', [
      d.dir('pkg', [
        d.file('dart_test.yaml', r'''
          tags:
            foo:
              include: ../dart_test.yaml
        '''),
      ]),
    ]).create();

    var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
    expect(
        () => Configuration.load(path),
        throwsA(allOf(
            isFormatException,
            predicate((error) =>
                error.toString().contains("include isn't supported here")))));
  });

  test('should allow an include field in a runner config context', () async {
    await d.dir('repo', [
      d.dir('pkg', [
        d.file('dart_test.yaml', '''
          presets:
            bar:
              include: other_dart_test.yaml
              pause_after_load: true
        '''),
        d.file('other_dart_test.yaml', 'reporter: expanded'),
      ]),
    ]).create();

    var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
    var config = Configuration.load(path);
    var presetBar = config.presets['bar']!;
    expect(presetBar.pauseAfterLoad, isTrue);
    expect(presetBar.reporter, 'expanded');
  });

  test('local configuration should take precedence after merging', () async {
    await d.dir('repo', [
      d.dir('pkg', [
        d.file('dart_test.yaml', '''
          include: other_dart_test.yaml
          concurrency: 5
        '''),
        d.file('other_dart_test.yaml', 'concurrency: 10'),
      ]),
    ]).create();

    var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
    var config = Configuration.load(path);
    expect(config.concurrency, 5);
  });

  group('gracefully handles', () {
    test('a non-string include field', () async {
      await d.dir('repo', [
        d.dir('pkg', [
          d.file('dart_test.yaml', 'include: 3'),
        ]),
      ]).create();

      var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
      expect(() => Configuration.load(path), throwsFormatException);
    });

    test('a non-existent included file', () async {
      await d.dir('repo', [
        d.dir('pkg', [
          d.file('dart_test.yaml', 'include: other_test.yaml'),
        ]),
      ]).create();

      var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
      expect(() => Configuration.load(path), throwsFormatException);
    });

    test('an include field in a test config context', () async {
      await d.dir('repo', [
        d.dir('pkg', [
          d.file('dart_test.yaml', '''
            tags:
              foo:
                include: ../dart_test.yaml
          '''),
        ]),
      ]).create();

      var path = p.join(d.sandbox, 'repo', 'pkg', 'dart_test.yaml');
      expect(() => Configuration.load(path), throwsFormatException);
    });
  });
}
