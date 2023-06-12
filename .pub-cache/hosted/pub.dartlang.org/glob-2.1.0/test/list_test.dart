// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:glob/src/utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  setUp(() async {
    await d.dir('foo', [
      d.file('bar'),
      d.dir('baz', [d.file('bang'), d.file('qux')])
    ]).create();
  });

  group('list()', () {
    test("fails if the context doesn't match the system context", () {
      expect(Glob('*', context: p.url).list, throwsStateError);
    });

    test('returns empty list for non-existent case-sensitive directories',
        () async {
      expect(await Glob('non/existent/**', caseSensitive: true).list().toList(),
          []);
    });

    test('returns empty list for non-existent case-insensitive directories',
        () async {
      expect(
          await Glob('non/existent/**', caseSensitive: false).list().toList(),
          []);
    });
  });

  group('listSync()', () {
    test("fails if the context doesn't match the system context", () {
      expect(Glob('*', context: p.url).listSync, throwsStateError);
    });

    test('returns empty list for non-existent case-sensitive directories', () {
      expect(Glob('non/existent/**', caseSensitive: true).listSync(), []);
    });

    test('returns empty list for non-existent case-insensitive directories',
        () {
      expect(Glob('non/existent/**', caseSensitive: false).listSync(), []);
    });
  });

  group('when case-sensitive', () {
    test('lists literals case-sensitively', () {
      expect(Glob('foo/BAZ/qux', caseSensitive: true).listSync(), []);
    });

    test('lists ranges case-sensitively', () {
      expect(Glob('foo/[BX][A-Z]z/qux', caseSensitive: true).listSync(), []);
    });

    test('options preserve case-sensitivity', () {
      expect(Glob('foo/{BAZ,ZAP}/qux', caseSensitive: true).listSync(), []);
    });
  });

  syncAndAsync((ListFn list) {
    group('literals', () {
      test('lists a single literal', () async {
        expect(
            await list('foo/baz/qux'), equals([p.join('foo', 'baz', 'qux')]));
      });

      test('lists a non-matching literal', () async {
        expect(await list('foo/baz/nothing'), isEmpty);
      });
    });

    group('star', () {
      test('lists within filenames but not across directories', () async {
        expect(await list('foo/b*'),
            unorderedEquals([p.join('foo', 'bar'), p.join('foo', 'baz')]));
      });

      test('lists the empy string', () async {
        expect(await list('foo/bar*'), equals([p.join('foo', 'bar')]));
      });
    });

    group('double star', () {
      test('lists within filenames', () async {
        expect(
            await list('foo/baz/**'),
            unorderedEquals(
                [p.join('foo', 'baz', 'qux'), p.join('foo', 'baz', 'bang')]));
      });

      test('lists the empty string', () async {
        expect(await list('foo/bar**'), equals([p.join('foo', 'bar')]));
      });

      test('lists recursively', () async {
        expect(
            await list('foo/**'),
            unorderedEquals([
              p.join('foo', 'bar'),
              p.join('foo', 'baz'),
              p.join('foo', 'baz', 'qux'),
              p.join('foo', 'baz', 'bang')
            ]));
      });

      test('combines with literals', () async {
        expect(
            await list('foo/ba**'),
            unorderedEquals([
              p.join('foo', 'bar'),
              p.join('foo', 'baz'),
              p.join('foo', 'baz', 'qux'),
              p.join('foo', 'baz', 'bang')
            ]));
      });

      test('lists recursively in the middle of a glob', () async {
        await d.dir('deep', [
          d.dir('a', [
            d.dir('b', [
              d.dir('c', [d.file('d'), d.file('long-file')]),
              d.dir('long-dir', [d.file('x')])
            ])
          ])
        ]).create();

        expect(
            await list('deep/**/?/?'),
            unorderedEquals([
              p.join('deep', 'a', 'b', 'c'),
              p.join('deep', 'a', 'b', 'c', 'd')
            ]));
      });
    });

    group('any char', () {
      test('matches a character', () async {
        expect(await list('foo/ba?'),
            unorderedEquals([p.join('foo', 'bar'), p.join('foo', 'baz')]));
      });

      test("doesn't match a separator", () async {
        expect(await list('foo?bar'), isEmpty);
      });
    });

    group('range', () {
      test('matches a range of characters', () async {
        expect(await list('foo/ba[a-z]'),
            unorderedEquals([p.join('foo', 'bar'), p.join('foo', 'baz')]));
      });

      test('matches a specific list of characters', () async {
        expect(await list('foo/ba[rz]'),
            unorderedEquals([p.join('foo', 'bar'), p.join('foo', 'baz')]));
      });

      test("doesn't match outside its range", () async {
        expect(
            await list('foo/ba[a-x]'), unorderedEquals([p.join('foo', 'bar')]));
      });

      test("doesn't match outside its specific list", () async {
        expect(
            await list('foo/ba[rx]'), unorderedEquals([p.join('foo', 'bar')]));
      });
    });

    test("the same file shouldn't be non-recursively listed multiple times",
        () async {
      await d.dir('multi', [
        d.dir('start-end', [d.file('file')])
      ]).create();

      expect(await list('multi/{start-*/f*,*-end/*e}'),
          equals([p.join('multi', 'start-end', 'file')]));
    });

    test("the same file shouldn't be recursively listed multiple times",
        () async {
      await d.dir('multi', [
        d.dir('a', [
          d.dir('b', [
            d.file('file'),
            d.dir('c', [d.file('file')])
          ]),
          d.dir('x', [
            d.dir('y', [d.file('file')])
          ])
        ])
      ]).create();

      expect(
          await list('multi/{*/*/*/file,a/**/file}'),
          unorderedEquals([
            p.join('multi', 'a', 'b', 'file'),
            p.join('multi', 'a', 'b', 'c', 'file'),
            p.join('multi', 'a', 'x', 'y', 'file')
          ]));
    });

    group('with symlinks', () {
      setUp(() async {
        await Link(p.join(d.sandbox, 'dir', 'link'))
            .create(p.join(d.sandbox, 'foo', 'baz'), recursive: true);
      });

      test('follows symlinks by default', () async {
        expect(
            await list('dir/**'),
            unorderedEquals([
              p.join('dir', 'link'),
              p.join('dir', 'link', 'bang'),
              p.join('dir', 'link', 'qux')
            ]));
      });

      test("doesn't follow symlinks with followLinks: false", () async {
        expect(await list('dir/**', followLinks: false),
            equals([p.join('dir', 'link')]));
      });

      test("shouldn't crash on broken symlinks", () async {
        await Directory(p.join(d.sandbox, 'foo')).delete(recursive: true);

        expect(await list('dir/**'), equals([p.join('dir', 'link')]));
      });
    });

    test('always lists recursively with recursive: true', () async {
      expect(
          await list('foo', recursive: true),
          unorderedEquals([
            'foo',
            p.join('foo', 'bar'),
            p.join('foo', 'baz'),
            p.join('foo', 'baz', 'qux'),
            p.join('foo', 'baz', 'bang')
          ]));
    });

    test('lists an absolute glob', () async {
      var pattern =
          separatorToForwardSlash(p.absolute(p.join(d.sandbox, 'foo/baz/**')));

      var result = await list(pattern);

      expect(
          result,
          unorderedEquals(
              [p.join('foo', 'baz', 'bang'), p.join('foo', 'baz', 'qux')]));
    });

    // Regression test for #4.
    test('lists an absolute case-insensitive glob', () async {
      var pattern =
          separatorToForwardSlash(p.absolute(p.join(d.sandbox, 'foo/Baz/**')));

      expect(
          await list(pattern, caseSensitive: false),
          unorderedEquals(
              [p.join('foo', 'baz', 'bang'), p.join('foo', 'baz', 'qux')]));
    });

    test('lists a subdirectory that sometimes exists', () async {
      await d.dir('top', [
        d.dir('dir1', [
          d.dir('subdir', [d.file('file')])
        ]),
        d.dir('dir2', [])
      ]).create();

      expect(await list('top/*/subdir/**'),
          equals([p.join('top', 'dir1', 'subdir', 'file')]));
    });

    group('when case-insensitive', () {
      test('lists literals case-insensitively', () async {
        expect(await list('foo/baz/qux', caseSensitive: false),
            equals([p.join('foo', 'baz', 'qux')]));
        expect(await list('foo/BAZ/qux', caseSensitive: false),
            equals([p.join('foo', 'baz', 'qux')]));
      });

      test('lists ranges case-insensitively', () async {
        expect(await list('foo/[bx][a-z]z/qux', caseSensitive: false),
            equals([p.join('foo', 'baz', 'qux')]));
        expect(await list('foo/[BX][A-Z]z/qux', caseSensitive: false),
            equals([p.join('foo', 'baz', 'qux')]));
      });

      test('options preserve case-insensitivity', () async {
        expect(await list('foo/{bar,baz}/qux', caseSensitive: false),
            equals([p.join('foo', 'baz', 'qux')]));
        expect(await list('foo/{BAR,BAZ}/qux', caseSensitive: false),
            equals([p.join('foo', 'baz', 'qux')]));
      });
    });
  });
}

typedef ListFn = FutureOr<List<String>> Function(String glob,
    {bool recursive, bool followLinks, bool? caseSensitive});

/// Runs [callback] in two groups with two values of [listFn]: one that uses
/// [Glob.list], one that uses [Glob.listSync].
void syncAndAsync(FutureOr Function(ListFn) callback) {
  group('async', () {
    callback((pattern, {recursive = false, followLinks = true, caseSensitive}) {
      var glob =
          Glob(pattern, recursive: recursive, caseSensitive: caseSensitive);

      return glob
          .list(root: d.sandbox, followLinks: followLinks)
          .map((entity) => p.relative(entity.path, from: d.sandbox))
          .toList();
    });
  });

  group('sync', () {
    callback((pattern, {recursive = false, followLinks = true, caseSensitive}) {
      var glob =
          Glob(pattern, recursive: recursive, caseSensitive: caseSensitive);

      return glob
          .listSync(root: d.sandbox, followLinks: followLinks)
          .map((entity) => p.relative(entity.path, from: d.sandbox))
          .toList();
    });
  });
}
