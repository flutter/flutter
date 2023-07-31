// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  final context = path.Context(style: path.Style.posix, current: '/root/path');

  test('separator', () {
    expect(context.separator, '/');
  });

  test('extension', () {
    expect(context.extension(''), '');
    expect(context.extension('.'), '');
    expect(context.extension('..'), '');
    expect(context.extension('foo.dart'), '.dart');
    expect(context.extension('foo.dart.js'), '.js');
    expect(context.extension('a.b/c'), '');
    expect(context.extension('a.b/c.d'), '.d');
    expect(context.extension('~/.bashrc'), '');
    expect(context.extension(r'a.b\c'), r'.b\c');
    expect(context.extension('foo.dart/'), '.dart');
    expect(context.extension('foo.dart//'), '.dart');
    expect(context.extension('foo.bar.dart.js', 2), '.dart.js');
    expect(context.extension(r'foo.bar.dart.js', 3), '.bar.dart.js');
    expect(context.extension(r'foo.bar.dart.js', 10), '.bar.dart.js');
    expect(context.extension('a.b/c.d', 2), '.d');
    expect(() => context.extension(r'foo.bar.dart.js', 0), throwsRangeError);
    expect(() => context.extension(r'foo.bar.dart.js', -1), throwsRangeError);
  });

  test('rootPrefix', () {
    expect(context.rootPrefix(''), '');
    expect(context.rootPrefix('a'), '');
    expect(context.rootPrefix('a/b'), '');
    expect(context.rootPrefix('/a/c'), '/');
    expect(context.rootPrefix('/'), '/');
  });

  test('dirname', () {
    expect(context.dirname(''), '.');
    expect(context.dirname('.'), '.');
    expect(context.dirname('..'), '.');
    expect(context.dirname('../..'), '..');
    expect(context.dirname('a'), '.');
    expect(context.dirname('a/b'), 'a');
    expect(context.dirname('a/b/c'), 'a/b');
    expect(context.dirname('a/b.c'), 'a');
    expect(context.dirname('a/'), '.');
    expect(context.dirname('a/.'), 'a');
    expect(context.dirname('a/..'), 'a');
    expect(context.dirname(r'a\b/c'), r'a\b');
    expect(context.dirname('/a'), '/');
    expect(context.dirname('///a'), '/');
    expect(context.dirname('/'), '/');
    expect(context.dirname('///'), '/');
    expect(context.dirname('a/b/'), 'a');
    expect(context.dirname(r'a/b\c'), 'a');
    expect(context.dirname('a//'), '.');
    expect(context.dirname('a/b//'), 'a');
    expect(context.dirname('a//b'), 'a');
  });

  test('basename', () {
    expect(context.basename(''), '');
    expect(context.basename('.'), '.');
    expect(context.basename('..'), '..');
    expect(context.basename('.foo'), '.foo');
    expect(context.basename('a'), 'a');
    expect(context.basename('a/b'), 'b');
    expect(context.basename('a/b/c'), 'c');
    expect(context.basename('a/b.c'), 'b.c');
    expect(context.basename('a/'), 'a');
    expect(context.basename('a/.'), '.');
    expect(context.basename('a/..'), '..');
    expect(context.basename(r'a\b/c'), 'c');
    expect(context.basename('/a'), 'a');
    expect(context.basename('/'), '/');
    expect(context.basename('a/b/'), 'b');
    expect(context.basename(r'a/b\c'), r'b\c');
    expect(context.basename('a//'), 'a');
    expect(context.basename('a/b//'), 'b');
    expect(context.basename('a//b'), 'b');
  });

  test('basenameWithoutExtension', () {
    expect(context.basenameWithoutExtension(''), '');
    expect(context.basenameWithoutExtension('.'), '.');
    expect(context.basenameWithoutExtension('..'), '..');
    expect(context.basenameWithoutExtension('a'), 'a');
    expect(context.basenameWithoutExtension('a/b'), 'b');
    expect(context.basenameWithoutExtension('a/b/c'), 'c');
    expect(context.basenameWithoutExtension('a/b.c'), 'b');
    expect(context.basenameWithoutExtension('a/'), 'a');
    expect(context.basenameWithoutExtension('a/.'), '.');
    expect(context.basenameWithoutExtension(r'a/b\c'), r'b\c');
    expect(context.basenameWithoutExtension('a/.bashrc'), '.bashrc');
    expect(context.basenameWithoutExtension('a/b/c.d.e'), 'c.d');
    expect(context.basenameWithoutExtension('a//'), 'a');
    expect(context.basenameWithoutExtension('a/b//'), 'b');
    expect(context.basenameWithoutExtension('a//b'), 'b');
    expect(context.basenameWithoutExtension('a/b.c/'), 'b');
    expect(context.basenameWithoutExtension('a/b.c//'), 'b');
    expect(context.basenameWithoutExtension('a/b c.d e'), 'b c');
  });

  test('isAbsolute', () {
    expect(context.isAbsolute(''), false);
    expect(context.isAbsolute('a'), false);
    expect(context.isAbsolute('a/b'), false);
    expect(context.isAbsolute('/a'), true);
    expect(context.isAbsolute('/a/b'), true);
    expect(context.isAbsolute('~'), false);
    expect(context.isAbsolute('.'), false);
    expect(context.isAbsolute('..'), false);
    expect(context.isAbsolute('.foo'), false);
    expect(context.isAbsolute('../a'), false);
    expect(context.isAbsolute('C:/a'), false);
    expect(context.isAbsolute(r'C:\a'), false);
    expect(context.isAbsolute(r'\\a'), false);
  });

  test('isRelative', () {
    expect(context.isRelative(''), true);
    expect(context.isRelative('a'), true);
    expect(context.isRelative('a/b'), true);
    expect(context.isRelative('/a'), false);
    expect(context.isRelative('/a/b'), false);
    expect(context.isRelative('~'), true);
    expect(context.isRelative('.'), true);
    expect(context.isRelative('..'), true);
    expect(context.isRelative('.foo'), true);
    expect(context.isRelative('../a'), true);
    expect(context.isRelative('C:/a'), true);
    expect(context.isRelative(r'C:\a'), true);
    expect(context.isRelative(r'\\a'), true);
  });

  group('join', () {
    test('allows up to eight parts', () {
      expect(context.join('a'), 'a');
      expect(context.join('a', 'b'), 'a/b');
      expect(context.join('a', 'b', 'c'), 'a/b/c');
      expect(context.join('a', 'b', 'c', 'd'), 'a/b/c/d');
      expect(context.join('a', 'b', 'c', 'd', 'e'), 'a/b/c/d/e');
      expect(context.join('a', 'b', 'c', 'd', 'e', 'f'), 'a/b/c/d/e/f');
      expect(context.join('a', 'b', 'c', 'd', 'e', 'f', 'g'), 'a/b/c/d/e/f/g');
      expect(context.join('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'),
          'a/b/c/d/e/f/g/h');
    });

    test('does not add separator if a part ends in one', () {
      expect(context.join('a/', 'b', 'c/', 'd'), 'a/b/c/d');
      expect(context.join('a\\', 'b'), r'a\/b');
    });

    test('ignores parts before an absolute path', () {
      expect(context.join('a', '/', 'b', 'c'), '/b/c');
      expect(context.join('a', '/b', '/c', 'd'), '/c/d');
      expect(context.join('a', r'c:\b', 'c', 'd'), r'a/c:\b/c/d');
      expect(context.join('a', r'\\b', 'c', 'd'), r'a/\\b/c/d');
    });

    test('ignores trailing nulls', () {
      expect(context.join('a', null), equals('a'));
      expect(context.join('a', 'b', 'c', null, null), equals('a/b/c'));
    });

    test('ignores empty strings', () {
      expect(context.join(''), '');
      expect(context.join('', ''), '');
      expect(context.join('', 'a'), 'a');
      expect(context.join('a', '', 'b', '', '', '', 'c'), 'a/b/c');
      expect(context.join('a', 'b', ''), 'a/b');
    });

    test('disallows intermediate nulls', () {
      expect(() => context.join('a', null, 'b'), throwsArgumentError);
    });

    test('join does not modify internal ., .., or trailing separators', () {
      expect(context.join('a/', 'b/c/'), 'a/b/c/');
      expect(context.join('a/b/./c/..//', 'd/.././..//e/f//'),
          'a/b/./c/..//d/.././..//e/f//');
      expect(context.join('a/b', 'c/../../../..'), 'a/b/c/../../../..');
      expect(context.join('a', 'b${context.separator}'), 'a/b/');
    });
  });

  group('joinAll', () {
    test('allows more than eight parts', () {
      expect(context.joinAll(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i']),
          'a/b/c/d/e/f/g/h/i');
    });

    test('does not add separator if a part ends in one', () {
      expect(context.joinAll(['a/', 'b', 'c/', 'd']), 'a/b/c/d');
      expect(context.joinAll(['a\\', 'b']), r'a\/b');
    });

    test('ignores parts before an absolute path', () {
      expect(context.joinAll(['a', '/', 'b', 'c']), '/b/c');
      expect(context.joinAll(['a', '/b', '/c', 'd']), '/c/d');
      expect(context.joinAll(['a', r'c:\b', 'c', 'd']), r'a/c:\b/c/d');
      expect(context.joinAll(['a', r'\\b', 'c', 'd']), r'a/\\b/c/d');
    });
  });

  group('split', () {
    test('simple cases', () {
      expect(context.split(''), []);
      expect(context.split('.'), ['.']);
      expect(context.split('..'), ['..']);
      expect(context.split('foo'), equals(['foo']));
      expect(context.split('foo/bar.txt'), equals(['foo', 'bar.txt']));
      expect(context.split('foo/bar/baz'), equals(['foo', 'bar', 'baz']));
      expect(context.split('foo/../bar/./baz'),
          equals(['foo', '..', 'bar', '.', 'baz']));
      expect(context.split('foo//bar///baz'), equals(['foo', 'bar', 'baz']));
      expect(context.split('foo/\\/baz'), equals(['foo', '\\', 'baz']));
      expect(context.split('.'), equals(['.']));
      expect(context.split(''), equals([]));
      expect(context.split('foo/'), equals(['foo']));
      expect(context.split('//'), equals(['/']));
    });

    test('includes the root for absolute paths', () {
      expect(context.split('/foo/bar/baz'), equals(['/', 'foo', 'bar', 'baz']));
      expect(context.split('/'), equals(['/']));
    });
  });

  group('normalize', () {
    test('simple cases', () {
      expect(context.normalize(''), '.');
      expect(context.normalize('.'), '.');
      expect(context.normalize('..'), '..');
      expect(context.normalize('a'), 'a');
      expect(context.normalize('/'), '/');
      expect(context.normalize(r'\'), r'\');
      expect(context.normalize('C:/'), 'C:');
      expect(context.normalize(r'C:\'), r'C:\');
      expect(context.normalize(r'\\'), r'\\');
      expect(context.normalize('a/./\xc5\u0bf8-;\u{1f085}\u{00}/c/d/../'),
          'a/\xc5\u0bf8-;\u{1f085}\u{00}/c');
    });

    test('collapses redundant separators', () {
      expect(context.normalize(r'a/b/c'), r'a/b/c');
      expect(context.normalize(r'a//b///c////d'), r'a/b/c/d');
    });

    test('does not collapse separators for other platform', () {
      expect(context.normalize(r'a\\b\\\c'), r'a\\b\\\c');
    });

    test('eliminates "." parts', () {
      expect(context.normalize('./'), '.');
      expect(context.normalize('/.'), '/');
      expect(context.normalize('/./'), '/');
      expect(context.normalize('./.'), '.');
      expect(context.normalize('a/./b'), 'a/b');
      expect(context.normalize('a/.b/c'), 'a/.b/c');
      expect(context.normalize('a/././b/./c'), 'a/b/c');
      expect(context.normalize('././a'), 'a');
      expect(context.normalize('a/./.'), 'a');
    });

    test('eliminates ".." parts', () {
      expect(context.normalize('..'), '..');
      expect(context.normalize('../'), '..');
      expect(context.normalize('../../..'), '../../..');
      expect(context.normalize('../../../'), '../../..');
      expect(context.normalize('/..'), '/');
      expect(context.normalize('/../../..'), '/');
      expect(context.normalize('/../../../a'), '/a');
      expect(context.normalize('c:/..'), '.');
      expect(context.normalize('A:/../../..'), '../..');
      expect(context.normalize('a/..'), '.');
      expect(context.normalize('a/b/..'), 'a');
      expect(context.normalize('a/../b'), 'b');
      expect(context.normalize('a/./../b'), 'b');
      expect(context.normalize('a/b/c/../../d/e/..'), 'a/d');
      expect(context.normalize('a/b/../../../../c'), '../../c');
      expect(context.normalize(r'z/a/b/../../..\../c'), r'z/..\../c');
      expect(context.normalize(r'a/b\c/../d'), 'a/d');
    });

    test('does not walk before root on absolute paths', () {
      expect(context.normalize('..'), '..');
      expect(context.normalize('../'), '..');
      expect(context.normalize('https://dart.dev/..'), 'https:');
      expect(context.normalize('https://dart.dev/../../a'), 'a');
      expect(context.normalize('file:///..'), '.');
      expect(context.normalize('file:///../../a'), '../a');
      expect(context.normalize('/..'), '/');
      expect(context.normalize('a/..'), '.');
      expect(context.normalize('../a'), '../a');
      expect(context.normalize('/../a'), '/a');
      expect(context.normalize('c:/../a'), 'a');
      expect(context.normalize('/../a'), '/a');
      expect(context.normalize('a/b/..'), 'a');
      expect(context.normalize('../a/b/..'), '../a');
      expect(context.normalize('a/../b'), 'b');
      expect(context.normalize('a/./../b'), 'b');
      expect(context.normalize('a/b/c/../../d/e/..'), 'a/d');
      expect(context.normalize('a/b/../../../../c'), '../../c');
      expect(context.normalize('a/b/c/../../..d/./.e/f././'), 'a/..d/.e/f.');
    });

    test('removes trailing separators', () {
      expect(context.normalize('./'), '.');
      expect(context.normalize('.//'), '.');
      expect(context.normalize('a/'), 'a');
      expect(context.normalize('a/b/'), 'a/b');
      expect(context.normalize(r'a/b\'), r'a/b\');
      expect(context.normalize('a/b///'), 'a/b');
    });

    test('when canonicalizing', () {
      expect(context.canonicalize('.'), '/root/path');
      expect(context.canonicalize('foo/bar'), '/root/path/foo/bar');
      expect(context.canonicalize('FoO'), '/root/path/FoO');
    });
  });

  group('relative', () {
    group('from absolute root', () {
      test('given absolute path in root', () {
        expect(context.relative('/'), '../..');
        expect(context.relative('/root'), '..');
        expect(context.relative('/root/path'), '.');
        expect(context.relative('/root/path/a'), 'a');
        expect(context.relative('/root/path/a/b.txt'), 'a/b.txt');
        expect(context.relative('/root/a/b.txt'), '../a/b.txt');
      });

      test('given absolute path outside of root', () {
        expect(context.relative('/a/b'), '../../a/b');
        expect(context.relative('/root/path/a'), 'a');
        expect(context.relative('/root/path/a/b.txt'), 'a/b.txt');
        expect(context.relative('/root/a/b.txt'), '../a/b.txt');
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(context.relative(''), '.');
        expect(context.relative('.'), '.');
        expect(context.relative('a'), 'a');
        expect(context.relative('a/b.txt'), 'a/b.txt');
        expect(context.relative('../a/b.txt'), '../a/b.txt');
        expect(context.relative('a/./b/../c.txt'), 'a/c.txt');
      });

      test('is case-sensitive', () {
        expect(context.relative('/RoOt'), '../../RoOt');
        expect(context.relative('/rOoT/pAtH/a'), '../../rOoT/pAtH/a');
      });

      // Regression
      test('from root-only path', () {
        expect(context.relative('/', from: '/'), '.');
        expect(context.relative('/root/path', from: '/'), 'root/path');
      });
    });

    group('from relative root', () {
      final r = path.Context(style: path.Style.posix, current: 'foo/bar');

      test('given absolute path', () {
        expect(r.relative('/'), equals('/'));
        expect(r.relative('/a/b'), equals('/a/b'));
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(r.relative(''), '.');
        expect(r.relative('.'), '.');
        expect(r.relative('..'), '..');
        expect(r.relative('a'), 'a');
        expect(r.relative('a/b.txt'), 'a/b.txt');
        expect(r.relative('../a/b.txt'), '../a/b.txt');
        expect(r.relative('a/./b/../c.txt'), 'a/c.txt');
      });
    });

    test('from a root with extension', () {
      final r = path.Context(style: path.Style.posix, current: '/dir.ext');
      expect(r.relative('/dir.ext/file'), 'file');
    });

    test('with a root parameter', () {
      expect(context.relative('/foo/bar/baz', from: '/foo/bar'), equals('baz'));
      expect(context.relative('..', from: '/foo/bar'), equals('../../root'));
      expect(context.relative('/foo/bar/baz', from: 'foo/bar'),
          equals('../../../../foo/bar/baz'));
      expect(context.relative('..', from: 'foo/bar'), equals('../../..'));
    });

    test('with a root parameter and a relative root', () {
      final r = path.Context(style: path.Style.posix, current: 'relative/root');
      expect(r.relative('/foo/bar/baz', from: '/foo/bar'), equals('baz'));
      expect(() => r.relative('..', from: '/foo/bar'), throwsPathException);
      expect(
          r.relative('/foo/bar/baz', from: 'foo/bar'), equals('/foo/bar/baz'));
      expect(r.relative('..', from: 'foo/bar'), equals('../../..'));
    });

    test('from a . root', () {
      final r = path.Context(style: path.Style.posix, current: '.');
      expect(r.relative('/foo/bar/baz'), equals('/foo/bar/baz'));
      expect(r.relative('foo/bar/baz'), equals('foo/bar/baz'));
    });
  });

  group('isWithin', () {
    test('simple cases', () {
      expect(context.isWithin('foo/bar', 'foo/bar'), isFalse);
      expect(context.isWithin('foo/bar', 'foo/bar/baz'), isTrue);
      expect(context.isWithin('foo/bar', 'foo/baz'), isFalse);
      expect(context.isWithin('foo/bar', '../path/foo/bar/baz'), isTrue);
      expect(context.isWithin('/', '/foo/bar'), isTrue);
      expect(context.isWithin('baz', '/root/path/baz/bang'), isTrue);
      expect(context.isWithin('baz', '/root/path/bang/baz'), isFalse);
    });

    test('complex cases', () {
      expect(context.isWithin('foo/./bar', 'foo/bar/baz'), isTrue);
      expect(context.isWithin('foo//bar', 'foo/bar/baz'), isTrue);
      expect(context.isWithin('foo/qux/../bar', 'foo/bar/baz'), isTrue);
      expect(context.isWithin('foo/bar', 'foo/bar/baz/../..'), isFalse);
      expect(context.isWithin('foo/bar', 'foo/bar///'), isFalse);
      expect(context.isWithin('foo/.bar', 'foo/.bar/baz'), isTrue);
      expect(context.isWithin('foo/./bar', 'foo/.bar/baz'), isFalse);
      expect(context.isWithin('foo/..bar', 'foo/..bar/baz'), isTrue);
      expect(context.isWithin('foo/bar', 'foo/bar/baz/..'), isFalse);
      expect(context.isWithin('foo/bar', 'foo/bar/baz/../qux'), isTrue);
    });

    test('from a relative root', () {
      final r = path.Context(style: path.Style.posix, current: 'foo/bar');
      expect(r.isWithin('.', 'a/b/c'), isTrue);
      expect(r.isWithin('.', '../a/b/c'), isFalse);
      expect(r.isWithin('.', '../../a/foo/b/c'), isFalse);
      expect(r.isWithin('/', '/baz/bang'), isTrue);
      expect(r.isWithin('.', '/baz/bang'), isFalse);
    });
  });

  group('equals and hash', () {
    test('simple cases', () {
      expectEquals(context, 'foo/bar', 'foo/bar');
      expectNotEquals(context, 'foo/bar', 'foo/bar/baz');
      expectNotEquals(context, 'foo/bar', 'foo');
      expectNotEquals(context, 'foo/bar', 'foo/baz');
      expectEquals(context, 'foo/bar', '../path/foo/bar');
      expectEquals(context, '/', '/');
      expectEquals(context, '/', '../..');
      expectEquals(context, 'baz', '/root/path/baz');
    });

    test('complex cases', () {
      expectEquals(context, 'foo/./bar', 'foo/bar');
      expectEquals(context, 'foo//bar', 'foo/bar');
      expectEquals(context, 'foo/qux/../bar', 'foo/bar');
      expectNotEquals(context, 'foo/qux/../bar', 'foo/qux');
      expectNotEquals(context, 'foo/bar', 'foo/bar/baz/../..');
      expectEquals(context, 'foo/bar', 'foo/bar///');
      expectEquals(context, 'foo/.bar', 'foo/.bar');
      expectNotEquals(context, 'foo/./bar', 'foo/.bar');
      expectEquals(context, 'foo/..bar', 'foo/..bar');
      expectNotEquals(context, 'foo/../bar', 'foo/..bar');
      expectEquals(context, 'foo/bar', 'foo/bar/baz/..');
      expectNotEquals(context, 'FoO/bAr', 'foo/bar');
    });

    test('from a relative root', () {
      final r = path.Context(style: path.Style.posix, current: 'foo/bar');
      expectEquals(r, 'a/b', 'a/b');
      expectNotEquals(r, '.', 'foo/bar');
      expectNotEquals(r, '.', '../a/b');
      expectEquals(r, '.', '../bar');
      expectEquals(r, '/baz/bang', '/baz/bang');
      expectNotEquals(r, 'baz/bang', '/baz/bang');
    });
  });

  group('absolute', () {
    test('allows up to seven parts', () {
      expect(context.absolute('a'), '/root/path/a');
      expect(context.absolute('a', 'b'), '/root/path/a/b');
      expect(context.absolute('a', 'b', 'c'), '/root/path/a/b/c');
      expect(context.absolute('a', 'b', 'c', 'd'), '/root/path/a/b/c/d');
      expect(context.absolute('a', 'b', 'c', 'd', 'e'), '/root/path/a/b/c/d/e');
      expect(context.absolute('a', 'b', 'c', 'd', 'e', 'f'),
          '/root/path/a/b/c/d/e/f');
      expect(context.absolute('a', 'b', 'c', 'd', 'e', 'f', 'g'),
          '/root/path/a/b/c/d/e/f/g');
    });

    test('does not add separator if a part ends in one', () {
      expect(context.absolute('a/', 'b', 'c/', 'd'), '/root/path/a/b/c/d');
      expect(context.absolute(r'a\', 'b'), r'/root/path/a\/b');
    });

    test('ignores parts before an absolute path', () {
      expect(context.absolute('a', '/b', '/c', 'd'), '/c/d');
      expect(
          context.absolute('a', r'c:\b', 'c', 'd'), r'/root/path/a/c:\b/c/d');
      expect(context.absolute('a', r'\\b', 'c', 'd'), r'/root/path/a/\\b/c/d');
    });
  });

  test('withoutExtension', () {
    expect(context.withoutExtension(''), '');
    expect(context.withoutExtension('a'), 'a');
    expect(context.withoutExtension('.a'), '.a');
    expect(context.withoutExtension('a.b'), 'a');
    expect(context.withoutExtension('a/b.c'), 'a/b');
    expect(context.withoutExtension('a/b.c.d'), 'a/b.c');
    expect(context.withoutExtension('a/'), 'a/');
    expect(context.withoutExtension('a/b/'), 'a/b/');
    expect(context.withoutExtension('a/.'), 'a/.');
    expect(context.withoutExtension('a/.b'), 'a/.b');
    expect(context.withoutExtension('a.b/c'), 'a.b/c');
    expect(context.withoutExtension(r'a.b\c'), r'a');
    expect(context.withoutExtension(r'a/b\c'), r'a/b\c');
    expect(context.withoutExtension(r'a/b\c.d'), r'a/b\c');
    expect(context.withoutExtension('a/b.c/'), 'a/b/');
    expect(context.withoutExtension('a/b.c//'), 'a/b//');
  });

  test('setExtension', () {
    expect(context.setExtension('', '.x'), '.x');
    expect(context.setExtension('a', '.x'), 'a.x');
    expect(context.setExtension('.a', '.x'), '.a.x');
    expect(context.setExtension('a.b', '.x'), 'a.x');
    expect(context.setExtension('a/b.c', '.x'), 'a/b.x');
    expect(context.setExtension('a/b.c.d', '.x'), 'a/b.c.x');
    expect(context.setExtension('a/', '.x'), 'a/.x');
    expect(context.setExtension('a/b/', '.x'), 'a/b/.x');
    expect(context.setExtension('a/.', '.x'), 'a/..x');
    expect(context.setExtension('a/.b', '.x'), 'a/.b.x');
    expect(context.setExtension('a.b/c', '.x'), 'a.b/c.x');
    expect(context.setExtension(r'a.b\c', '.x'), r'a.x');
    expect(context.setExtension(r'a/b\c', '.x'), r'a/b\c.x');
    expect(context.setExtension(r'a/b\c.d', '.x'), r'a/b\c.x');
    expect(context.setExtension('a/b.c/', '.x'), 'a/b/.x');
    expect(context.setExtension('a/b.c//', '.x'), 'a/b//.x');
  });

  group('fromUri', () {
    test('with a URI', () {
      expect(context.fromUri(Uri.parse('file:///path/to/foo')), '/path/to/foo');
      expect(
          context.fromUri(Uri.parse('file:///path/to/foo/')), '/path/to/foo/');
      expect(context.fromUri(Uri.parse('file:///')), '/');
      expect(context.fromUri(Uri.parse('foo/bar')), 'foo/bar');
      expect(context.fromUri(Uri.parse('/path/to/foo')), '/path/to/foo');
      expect(context.fromUri(Uri.parse('///path/to/foo')), '/path/to/foo');
      expect(context.fromUri(Uri.parse('file:///path/to/foo%23bar')),
          '/path/to/foo#bar');
      expect(context.fromUri(Uri.parse('_%7B_%7D_%60_%5E_%20_%22_%25_')),
          r'_{_}_`_^_ _"_%_');
      expect(() => context.fromUri(Uri.parse('https://dart.dev')),
          throwsArgumentError);
    });

    test('with a string', () {
      expect(context.fromUri('file:///path/to/foo'), '/path/to/foo');
    });
  });

  test('toUri', () {
    expect(context.toUri('/path/to/foo'), Uri.parse('file:///path/to/foo'));
    expect(context.toUri('/path/to/foo/'), Uri.parse('file:///path/to/foo/'));
    expect(context.toUri('path/to/foo/'), Uri.parse('path/to/foo/'));
    expect(context.toUri('/'), Uri.parse('file:///'));
    expect(context.toUri('foo/bar'), Uri.parse('foo/bar'));
    expect(context.toUri('/path/to/foo#bar'),
        Uri.parse('file:///path/to/foo%23bar'));
    expect(context.toUri(r'/_{_}_`_^_ _"_%_'),
        Uri.parse('file:///_%7B_%7D_%60_%5E_%20_%22_%25_'));
    expect(context.toUri(r'_{_}_`_^_ _"_%_'),
        Uri.parse('_%7B_%7D_%60_%5E_%20_%22_%25_'));
    expect(context.toUri(''), Uri.parse(''));
  });

  group('prettyUri', () {
    test('with a file: URI', () {
      expect(context.prettyUri('file:///root/path/a/b'), 'a/b');
      expect(context.prettyUri('file:///root/path/a/../b'), 'b');
      expect(context.prettyUri('file:///other/path/a/b'), '/other/path/a/b');
      expect(context.prettyUri('file:///root/other'), '../other');
    });

    test('with an http: URI', () {
      expect(context.prettyUri('https://dart.dev/a/b'), 'https://dart.dev/a/b');
    });

    test('with a relative URI', () {
      expect(context.prettyUri('a/b'), 'a/b');
    });

    test('with a root-relative URI', () {
      expect(context.prettyUri('/a/b'), '/a/b');
    });

    test('with a Uri object', () {
      expect(context.prettyUri(Uri.parse('a/b')), 'a/b');
    });
  });
}
