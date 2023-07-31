// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/src/path_set.dart';

Matcher containsPath(String path) => predicate(
    (paths) => paths is PathSet && paths.contains(path),
    'set contains "$path"');

Matcher containsDir(String path) => predicate(
    (paths) => paths is PathSet && paths.containsDir(path),
    'set contains directory "$path"');

void main() {
  late PathSet paths;
  setUp(() => paths = PathSet('root'));

  group('adding a path', () {
    test('stores the path in the set', () {
      paths.add('root/path/to/file');
      expect(paths, containsPath('root/path/to/file'));
    });

    test("that's a subdir of another path keeps both in the set", () {
      paths.add('root/path');
      paths.add('root/path/to/file');
      expect(paths, containsPath('root/path'));
      expect(paths, containsPath('root/path/to/file'));
    });

    test("that's not normalized normalizes the path before storing it", () {
      paths.add('root/../root/path/to/../to/././file');
      expect(paths, containsPath('root/path/to/file'));
    });

    test("that's absolute normalizes the path before storing it", () {
      paths.add(p.absolute('root/path/to/file'));
      expect(paths, containsPath('root/path/to/file'));
    });
  });

  group('removing a path', () {
    test("that's in the set removes and returns that path", () {
      paths.add('root/path/to/file');
      expect(paths.remove('root/path/to/file'),
          unorderedEquals([p.normalize('root/path/to/file')]));
      expect(paths, isNot(containsPath('root/path/to/file')));
    });

    test("that's not in the set returns an empty set", () {
      paths.add('root/path/to/file');
      expect(paths.remove('root/path/to/nothing'), isEmpty);
    });

    test("that's a directory removes and returns all files beneath it", () {
      paths.add('root/outside');
      paths.add('root/path/to/one');
      paths.add('root/path/to/two');
      paths.add('root/path/to/sub/three');

      expect(
          paths.remove('root/path'),
          unorderedEquals([
            'root/path/to/one',
            'root/path/to/two',
            'root/path/to/sub/three'
          ].map(p.normalize)));

      expect(paths, containsPath('root/outside'));
      expect(paths, isNot(containsPath('root/path/to/one')));
      expect(paths, isNot(containsPath('root/path/to/two')));
      expect(paths, isNot(containsPath('root/path/to/sub/three')));
    });

    test(
        "that's a directory in the set removes and returns it and all files "
        'beneath it', () {
      paths.add('root/path');
      paths.add('root/path/to/one');
      paths.add('root/path/to/two');
      paths.add('root/path/to/sub/three');

      expect(
          paths.remove('root/path'),
          unorderedEquals([
            'root/path',
            'root/path/to/one',
            'root/path/to/two',
            'root/path/to/sub/three'
          ].map(p.normalize)));

      expect(paths, isNot(containsPath('root/path')));
      expect(paths, isNot(containsPath('root/path/to/one')));
      expect(paths, isNot(containsPath('root/path/to/two')));
      expect(paths, isNot(containsPath('root/path/to/sub/three')));
    });

    test("that's not normalized removes and returns the normalized path", () {
      paths.add('root/path/to/file');
      expect(paths.remove('root/../root/path/to/../to/./file'),
          unorderedEquals([p.normalize('root/path/to/file')]));
    });

    test("that's absolute removes and returns the normalized path", () {
      paths.add('root/path/to/file');
      expect(paths.remove(p.absolute('root/path/to/file')),
          unorderedEquals([p.normalize('root/path/to/file')]));
    });
  });

  group('containsPath()', () {
    test('returns false for a non-existent path', () {
      paths.add('root/path/to/file');
      expect(paths, isNot(containsPath('root/path/to/nothing')));
    });

    test("returns false for a directory that wasn't added explicitly", () {
      paths.add('root/path/to/file');
      expect(paths, isNot(containsPath('root/path')));
    });

    test('returns true for a directory that was added explicitly', () {
      paths.add('root/path');
      paths.add('root/path/to/file');
      expect(paths, containsPath('root/path'));
    });

    test('with a non-normalized path normalizes the path before looking it up',
        () {
      paths.add('root/path/to/file');
      expect(paths, containsPath('root/../root/path/to/../to/././file'));
    });

    test('with an absolute path normalizes the path before looking it up', () {
      paths.add('root/path/to/file');
      expect(paths, containsPath(p.absolute('root/path/to/file')));
    });
  });

  group('containsDir()', () {
    test('returns true for a directory that was added implicitly', () {
      paths.add('root/path/to/file');
      expect(paths, containsDir('root/path'));
      expect(paths, containsDir('root/path/to'));
    });

    test('returns true for a directory that was added explicitly', () {
      paths.add('root/path');
      paths.add('root/path/to/file');
      expect(paths, containsDir('root/path'));
    });

    test("returns false for a directory that wasn't added", () {
      expect(paths, isNot(containsDir('root/nothing')));
    });

    test('returns false for a non-directory path that was added', () {
      paths.add('root/path/to/file');
      expect(paths, isNot(containsDir('root/path/to/file')));
    });

    test(
        'returns false for a directory that was added implicitly and then '
        'removed implicitly', () {
      paths.add('root/path/to/file');
      paths.remove('root/path/to/file');
      expect(paths, isNot(containsDir('root/path')));
    });

    test(
        'returns false for a directory that was added explicitly whose '
        'children were then removed', () {
      paths.add('root/path');
      paths.add('root/path/to/file');
      paths.remove('root/path/to/file');
      expect(paths, isNot(containsDir('root/path')));
    });

    test('with a non-normalized path normalizes the path before looking it up',
        () {
      paths.add('root/path/to/file');
      expect(paths, containsDir('root/../root/path/to/../to/.'));
    });

    test('with an absolute path normalizes the path before looking it up', () {
      paths.add('root/path/to/file');
      expect(paths, containsDir(p.absolute('root/path')));
    });
  });

  group('paths', () {
    test('returns paths added to the set', () {
      paths.add('root/path');
      paths.add('root/path/to/one');
      paths.add('root/path/to/two');

      expect(
          paths.paths,
          unorderedEquals([
            'root/path',
            'root/path/to/one',
            'root/path/to/two',
          ].map(p.normalize)));
    });

    test("doesn't return paths removed from the set", () {
      paths.add('root/path/to/one');
      paths.add('root/path/to/two');
      paths.remove('root/path/to/two');

      expect(paths.paths, unorderedEquals([p.normalize('root/path/to/one')]));
    });
  });

  group('clear', () {
    test('removes all paths from the set', () {
      paths.add('root/path');
      paths.add('root/path/to/one');
      paths.add('root/path/to/two');

      paths.clear();
      expect(paths.paths, isEmpty);
    });
  });
}
