// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  final context = path.Context(
      style: path.Style.url, current: 'https://dart.dev/root/path');

  test('separator', () {
    expect(context.separator, '/');
  });

  test('extension', () {
    expect(context.extension(''), '');
    expect(context.extension('foo.dart'), '.dart');
    expect(context.extension('foo.dart.js'), '.js');
    expect(context.extension('a.b/c'), '');
    expect(context.extension('a.b/c.d'), '.d');
    expect(context.extension(r'a.b\c'), r'.b\c');
    expect(context.extension('foo.dart/'), '.dart');
    expect(context.extension('foo.dart//'), '.dart');
  });

  test('rootPrefix', () {
    expect(context.rootPrefix(''), '');
    expect(context.rootPrefix('a'), '');
    expect(context.rootPrefix('a/b'), '');
    expect(context.rootPrefix('https://dart.dev/a/c'), 'https://dart.dev');
    expect(context.rootPrefix('file:///a/c'), 'file://');
    expect(context.rootPrefix('/a/c'), '/');
    expect(context.rootPrefix('https://dart.dev/'), 'https://dart.dev');
    expect(context.rootPrefix('file:///'), 'file://');
    expect(context.rootPrefix('https://dart.dev'), 'https://dart.dev');
    expect(context.rootPrefix('file://'), 'file://');
    expect(context.rootPrefix('/'), '/');
    expect(context.rootPrefix('foo/bar://'), '');
    expect(context.rootPrefix('package:foo/bar.dart'), 'package:foo');
    expect(context.rootPrefix('foo/bar:baz/qux'), '');
  });

  test('dirname', () {
    expect(context.dirname(''), '.');
    expect(context.dirname('a'), '.');
    expect(context.dirname('a/b'), 'a');
    expect(context.dirname('a/b/c'), 'a/b');
    expect(context.dirname('a/b.c'), 'a');
    expect(context.dirname('a/'), '.');
    expect(context.dirname('a/.'), 'a');
    expect(context.dirname(r'a\b/c'), r'a\b');
    expect(context.dirname('https://dart.dev/a'), 'https://dart.dev');
    expect(context.dirname('file:///a'), 'file://');
    expect(context.dirname('/a'), '/');
    expect(context.dirname('https://dart.dev///a'), 'https://dart.dev');
    expect(context.dirname('file://///a'), 'file://');
    expect(context.dirname('///a'), '/');
    expect(context.dirname('https://dart.dev/'), 'https://dart.dev');
    expect(context.dirname('https://dart.dev'), 'https://dart.dev');
    expect(context.dirname('file:///'), 'file://');
    expect(context.dirname('file://'), 'file://');
    expect(context.dirname('/'), '/');
    expect(context.dirname('https://dart.dev///'), 'https://dart.dev');
    expect(context.dirname('file://///'), 'file://');
    expect(context.dirname('///'), '/');
    expect(context.dirname('a/b/'), 'a');
    expect(context.dirname(r'a/b\c'), 'a');
    expect(context.dirname('a//'), '.');
    expect(context.dirname('a/b//'), 'a');
    expect(context.dirname('a//b'), 'a');
  });

  test('basename', () {
    expect(context.basename(''), '');
    expect(context.basename('a'), 'a');
    expect(context.basename('a/b'), 'b');
    expect(context.basename('a/b/c'), 'c');
    expect(context.basename('a/b.c'), 'b.c');
    expect(context.basename('a/'), 'a');
    expect(context.basename('a/.'), '.');
    expect(context.basename(r'a\b/c'), 'c');
    expect(context.basename('https://dart.dev/a'), 'a');
    expect(context.basename('file:///a'), 'a');
    expect(context.basename('/a'), 'a');
    expect(context.basename('https://dart.dev/'), 'https://dart.dev');
    expect(context.basename('https://dart.dev'), 'https://dart.dev');
    expect(context.basename('file:///'), 'file://');
    expect(context.basename('file://'), 'file://');
    expect(context.basename('/'), '/');
    expect(context.basename('a/b/'), 'b');
    expect(context.basename(r'a/b\c'), r'b\c');
    expect(context.basename('a//'), 'a');
    expect(context.basename('a/b//'), 'b');
    expect(context.basename('a//b'), 'b');
    expect(context.basename('a b/c d.e f'), 'c d.e f');
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
    expect(context.basenameWithoutExtension('a/b c.d e.f g'), 'b c.d e');
  });

  test('isAbsolute', () {
    expect(context.isAbsolute(''), false);
    expect(context.isAbsolute('a'), false);
    expect(context.isAbsolute('a/b'), false);
    expect(context.isAbsolute('https://dart.dev/a'), true);
    expect(context.isAbsolute('file:///a'), true);
    expect(context.isAbsolute('/a'), true);
    expect(context.isAbsolute('https://dart.dev/a/b'), true);
    expect(context.isAbsolute('file:///a/b'), true);
    expect(context.isAbsolute('/a/b'), true);
    expect(context.isAbsolute('https://dart.dev/'), true);
    expect(context.isAbsolute('file:///'), true);
    expect(context.isAbsolute('https://dart.dev'), true);
    expect(context.isAbsolute('file://'), true);
    expect(context.isAbsolute('/'), true);
    expect(context.isAbsolute('~'), false);
    expect(context.isAbsolute('.'), false);
    expect(context.isAbsolute('../a'), false);
    expect(context.isAbsolute('C:/a'), true);
    expect(context.isAbsolute(r'C:\a'), true);
    expect(context.isAbsolute('package:foo/bar.dart'), true);
    expect(context.isAbsolute('foo/bar:baz/qux'), false);
    expect(context.isAbsolute(r'\\a'), false);
  });

  test('isRelative', () {
    expect(context.isRelative(''), true);
    expect(context.isRelative('a'), true);
    expect(context.isRelative('a/b'), true);
    expect(context.isRelative('https://dart.dev/a'), false);
    expect(context.isRelative('file:///a'), false);
    expect(context.isRelative('/a'), false);
    expect(context.isRelative('https://dart.dev/a/b'), false);
    expect(context.isRelative('file:///a/b'), false);
    expect(context.isRelative('/a/b'), false);
    expect(context.isRelative('https://dart.dev/'), false);
    expect(context.isRelative('file:///'), false);
    expect(context.isRelative('https://dart.dev'), false);
    expect(context.isRelative('file://'), false);
    expect(context.isRelative('/'), false);
    expect(context.isRelative('~'), true);
    expect(context.isRelative('.'), true);
    expect(context.isRelative('../a'), true);
    expect(context.isRelative('C:/a'), false);
    expect(context.isRelative(r'C:\a'), false);
    expect(context.isRelative(r'package:foo/bar.dart'), false);
    expect(context.isRelative('foo/bar:baz/qux'), true);
    expect(context.isRelative(r'\\a'), true);
  });

  test('isRootRelative', () {
    expect(context.isRootRelative(''), false);
    expect(context.isRootRelative('a'), false);
    expect(context.isRootRelative('a/b'), false);
    expect(context.isRootRelative('https://dart.dev/a'), false);
    expect(context.isRootRelative('file:///a'), false);
    expect(context.isRootRelative('/a'), true);
    expect(context.isRootRelative('https://dart.dev/a/b'), false);
    expect(context.isRootRelative('file:///a/b'), false);
    expect(context.isRootRelative('/a/b'), true);
    expect(context.isRootRelative('https://dart.dev/'), false);
    expect(context.isRootRelative('file:///'), false);
    expect(context.isRootRelative('https://dart.dev'), false);
    expect(context.isRootRelative('file://'), false);
    expect(context.isRootRelative('/'), true);
    expect(context.isRootRelative('~'), false);
    expect(context.isRootRelative('.'), false);
    expect(context.isRootRelative('../a'), false);
    expect(context.isRootRelative('C:/a'), false);
    expect(context.isRootRelative(r'C:\a'), false);
    expect(context.isRootRelative(r'package:foo/bar.dart'), false);
    expect(context.isRootRelative('foo/bar:baz/qux'), false);
    expect(context.isRootRelative(r'\\a'), false);
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
      expect(context.join('a', 'https://dart.dev', 'b', 'c'),
          'https://dart.dev/b/c');
      expect(context.join('a', 'file://', 'b', 'c'), 'file:///b/c');
      expect(context.join('a', '/', 'b', 'c'), '/b/c');
      expect(context.join('a', '/b', 'https://dart.dev/c', 'd'),
          'https://dart.dev/c/d');
      expect(
          context.join('a', 'http://google.com/b', 'https://dart.dev/c', 'd'),
          'https://dart.dev/c/d');
      expect(context.join('a', '/b', '/c', 'd'), '/c/d');
      expect(context.join('a', r'c:\b', 'c', 'd'), r'c:\b/c/d');
      expect(context.join('a', 'package:foo/bar', 'c', 'd'),
          r'package:foo/bar/c/d');
      expect(context.join('a', r'\\b', 'c', 'd'), r'a/\\b/c/d');
    });

    test('preserves roots before a root-relative path', () {
      expect(context.join('https://dart.dev', 'a', '/b', 'c'),
          'https://dart.dev/b/c');
      expect(context.join('file://', 'a', '/b', 'c'), 'file:///b/c');
      expect(context.join('file://', 'a', '/b', 'c', '/d'), 'file:///d');
      expect(context.join('package:foo/bar.dart', '/baz.dart'),
          'package:foo/baz.dart');
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

    test('does not modify internal ., .., or trailing separators', () {
      expect(context.join('a/', 'b/c/'), 'a/b/c/');
      expect(context.join('a/b/./c/..//', 'd/.././..//e/f//'),
          'a/b/./c/..//d/.././..//e/f//');
      expect(context.join('a/b', 'c/../../../..'), 'a/b/c/../../../..');
      expect(context.join('a', 'b${context.separator}'), 'a/b/');
    });

    test('treats drive letters as part of the root for file: URLs', () {
      expect(
          context.join('file:///c:/foo/bar', '/baz/qux'), 'file:///c:/baz/qux');
      expect(
          context.join('file:///D:/foo/bar', '/baz/qux'), 'file:///D:/baz/qux');
      expect(context.join('file:///c:/', '/baz/qux'), 'file:///c:/baz/qux');
      expect(context.join('file:///c:', '/baz/qux'), 'file:///c:/baz/qux');
      expect(context.join('file://host/c:/foo/bar', '/baz/qux'),
          'file://host/c:/baz/qux');
    });

    test('treats drive letters as normal components for non-file: URLs', () {
      expect(context.join('http://foo.com/c:/foo/bar', '/baz/qux'),
          'http://foo.com/baz/qux');
      expect(context.join('misfile:///c:/foo/bar', '/baz/qux'),
          'misfile:///baz/qux');
      expect(
          context.join('filer:///c:/foo/bar', '/baz/qux'), 'filer:///baz/qux');
    });
  });

  group('joinAll', () {
    test('allows more than eight parts', () {
      expect(context.joinAll(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i']),
          'a/b/c/d/e/f/g/h/i');
    });

    test('ignores parts before an absolute path', () {
      expect(context.joinAll(['a', 'https://dart.dev', 'b', 'c']),
          'https://dart.dev/b/c');
      expect(context.joinAll(['a', 'file://', 'b', 'c']), 'file:///b/c');
      expect(context.joinAll(['a', '/', 'b', 'c']), '/b/c');
      expect(context.joinAll(['a', '/b', 'https://dart.dev/c', 'd']),
          'https://dart.dev/c/d');
      expect(
          context
              .joinAll(['a', 'http://google.com/b', 'https://dart.dev/c', 'd']),
          'https://dart.dev/c/d');
      expect(context.joinAll(['a', '/b', '/c', 'd']), '/c/d');
      expect(context.joinAll(['a', r'c:\b', 'c', 'd']), r'c:\b/c/d');
      expect(context.joinAll(['a', 'package:foo/bar', 'c', 'd']),
          r'package:foo/bar/c/d');
      expect(context.joinAll(['a', r'\\b', 'c', 'd']), r'a/\\b/c/d');
    });

    test('preserves roots before a root-relative path', () {
      expect(context.joinAll(['https://dart.dev', 'a', '/b', 'c']),
          'https://dart.dev/b/c');
      expect(context.joinAll(['file://', 'a', '/b', 'c']), 'file:///b/c');
      expect(context.joinAll(['file://', 'a', '/b', 'c', '/d']), 'file:///d');
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
      expect(context.split('https://dart.dev//'), equals(['https://dart.dev']));
      expect(context.split('file:////'), equals(['file://']));
      expect(context.split('//'), equals(['/']));
    });

    test('includes the root for absolute paths', () {
      expect(context.split('https://dart.dev/foo/bar/baz'),
          equals(['https://dart.dev', 'foo', 'bar', 'baz']));
      expect(context.split('file:///foo/bar/baz'),
          equals(['file://', 'foo', 'bar', 'baz']));
      expect(context.split('/foo/bar/baz'), equals(['/', 'foo', 'bar', 'baz']));
      expect(context.split('https://dart.dev/'), equals(['https://dart.dev']));
      expect(context.split('https://dart.dev'), equals(['https://dart.dev']));
      expect(context.split('file:///'), equals(['file://']));
      expect(context.split('file://'), equals(['file://']));
      expect(context.split('/'), equals(['/']));
    });
  });

  group('normalize', () {
    test('simple cases', () {
      expect(context.normalize(''), '.');
      expect(context.normalize('.'), '.');
      expect(context.normalize('..'), '..');
      expect(context.normalize('a'), 'a');
      expect(context.normalize('https://dart.dev/'), 'https://dart.dev');
      expect(context.normalize('https://dart.dev'), 'https://dart.dev');
      expect(context.normalize('file://'), 'file://');
      expect(context.normalize('file:///'), 'file://');
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
      expect(context.normalize('https://dart.dev/.'), 'https://dart.dev');
      expect(context.normalize('file:///.'), 'file://');
      expect(context.normalize('/.'), '/');
      expect(context.normalize('https://dart.dev/./'), 'https://dart.dev');
      expect(context.normalize('file:///./'), 'file://');
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
      expect(context.normalize('https://dart.dev/..'), 'https://dart.dev');
      expect(context.normalize('file:///..'), 'file://');
      expect(context.normalize('/..'), '/');
      expect(
          context.normalize('https://dart.dev/../../..'), 'https://dart.dev');
      expect(context.normalize('file:///../../..'), 'file://');
      expect(context.normalize('/../../..'), '/');
      expect(context.normalize('https://dart.dev/../../../a'),
          'https://dart.dev/a');
      expect(context.normalize('file:///../../../a'), 'file:///a');
      expect(context.normalize('/../../../a'), '/a');
      expect(context.normalize('c:/..'), 'c:');
      expect(context.normalize('package:foo/..'), 'package:foo');
      expect(context.normalize('A:/../../..'), 'A:');
      expect(context.normalize('a/..'), '.');
      expect(context.normalize('a/b/..'), 'a');
      expect(context.normalize('a/../b'), 'b');
      expect(context.normalize('a/./../b'), 'b');
      expect(context.normalize('a/b/c/../../d/e/..'), 'a/d');
      expect(context.normalize('a/b/../../../../c'), '../../c');
      expect(context.normalize('z/a/b/../../..../c'), 'z/..../c');
      expect(context.normalize('a/bc/../d'), 'a/d');
    });

    test('does not walk before root on absolute paths', () {
      expect(context.normalize('..'), '..');
      expect(context.normalize('../'), '..');
      expect(context.normalize('https://dart.dev/..'), 'https://dart.dev');
      expect(context.normalize('https://dart.dev/../a'), 'https://dart.dev/a');
      expect(context.normalize('file:///..'), 'file://');
      expect(context.normalize('file:///../a'), 'file:///a');
      expect(context.normalize('/..'), '/');
      expect(context.normalize('a/..'), '.');
      expect(context.normalize('../a'), '../a');
      expect(context.normalize('/../a'), '/a');
      expect(context.normalize('c:/../a'), 'c:/a');
      expect(context.normalize('package:foo/../a'), 'package:foo/a');
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
      expect(context.canonicalize('.'), 'https://dart.dev/root/path');
      expect(context.canonicalize('foo/bar'),
          'https://dart.dev/root/path/foo/bar');
      expect(context.canonicalize('FoO'), 'https://dart.dev/root/path/FoO');
      expect(context.canonicalize('/foo'), 'https://dart.dev/foo');
      expect(context.canonicalize('http://google.com/foo'),
          'http://google.com/foo');
    });
  });

  group('relative', () {
    group('from absolute root', () {
      test('given absolute path in root', () {
        expect(context.relative('https://dart.dev'), '../..');
        expect(context.relative('https://dart.dev/'), '../..');
        expect(context.relative('/'), '../..');
        expect(context.relative('https://dart.dev/root'), '..');
        expect(context.relative('/root'), '..');
        expect(context.relative('https://dart.dev/root/path'), '.');
        expect(context.relative('/root/path'), '.');
        expect(context.relative('https://dart.dev/root/path/a'), 'a');
        expect(context.relative('/root/path/a'), 'a');
        expect(
            context.relative('https://dart.dev/root/path/a/b.txt'), 'a/b.txt');
        expect(context.relative('/root/path/a/b.txt'), 'a/b.txt');
        expect(context.relative('https://dart.dev/root/a/b.txt'), '../a/b.txt');
        expect(context.relative('/root/a/b.txt'), '../a/b.txt');
      });

      test('given absolute path outside of root', () {
        expect(context.relative('https://dart.dev/a/b'), '../../a/b');
        expect(context.relative('/a/b'), '../../a/b');
        expect(context.relative('https://dart.dev/root/path/a'), 'a');
        expect(context.relative('/root/path/a'), 'a');
        expect(
            context.relative('https://dart.dev/root/path/a/b.txt'), 'a/b.txt');
        expect(
            context.relative('https://dart.dev/root/path/a/b.txt'), 'a/b.txt');
        expect(context.relative('https://dart.dev/root/a/b.txt'), '../a/b.txt');
      });

      test('given absolute path with different hostname/protocol', () {
        expect(context.relative(r'http://google.com/a/b'),
            r'http://google.com/a/b');
        expect(context.relative(r'file:///a/b'), r'file:///a/b');
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
        expect(
            context.relative('HtTps://dart.dev/root'), 'HtTps://dart.dev/root');
        expect(
            context.relative('https://DaRt.DeV/root'), 'https://DaRt.DeV/root');
        expect(context.relative('/RoOt'), '../../RoOt');
        expect(context.relative('/rOoT/pAtH/a'), '../../rOoT/pAtH/a');
      });

      // Regression
      test('from root-only path', () {
        expect(context.relative('https://dart.dev', from: 'https://dart.dev'),
            '.');
        expect(
            context.relative('https://dart.dev/root/path',
                from: 'https://dart.dev'),
            'root/path');
      });
    });

    group('from relative root', () {
      final r = path.Context(style: path.Style.url, current: 'foo/bar');

      test('given absolute path', () {
        expect(r.relative('http://google.com/'), equals('http://google.com'));
        expect(r.relative('http://google.com'), equals('http://google.com'));
        expect(r.relative('file:///'), equals('file://'));
        expect(r.relative('file://'), equals('file://'));
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

    group('from root-relative root', () {
      final r = path.Context(style: path.Style.url, current: '/foo/bar');

      test('given absolute path', () {
        expect(r.relative('http://google.com/'), equals('http://google.com'));
        expect(r.relative('http://google.com'), equals('http://google.com'));
        expect(r.relative('file:///'), equals('file://'));
        expect(r.relative('file://'), equals('file://'));
        expect(r.relative('/'), equals('../..'));
        expect(r.relative('/a/b'), equals('../../a/b'));
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
      final r = path.Context(style: path.Style.url, current: '/dir.ext');
      expect(r.relative('/dir.ext/file'), 'file');
    });

    test('with a root parameter', () {
      expect(context.relative('/foo/bar/baz', from: '/foo/bar'), equals('baz'));
      expect(context.relative('/foo/bar/baz', from: 'https://dart.dev/foo/bar'),
          equals('baz'));
      expect(context.relative('https://dart.dev/foo/bar/baz', from: '/foo/bar'),
          equals('baz'));
      expect(
          context.relative('https://dart.dev/foo/bar/baz',
              from: 'file:///foo/bar'),
          equals('https://dart.dev/foo/bar/baz'));
      expect(
          context.relative('https://dart.dev/foo/bar/baz',
              from: 'https://dart.dev/foo/bar'),
          equals('baz'));
      expect(context.relative('/foo/bar/baz', from: 'file:///foo/bar'),
          equals('https://dart.dev/foo/bar/baz'));
      expect(context.relative('file:///foo/bar/baz', from: '/foo/bar'),
          equals('file:///foo/bar/baz'));

      expect(context.relative('..', from: '/foo/bar'), equals('../../root'));
      expect(context.relative('..', from: 'https://dart.dev/foo/bar'),
          equals('../../root'));
      expect(context.relative('..', from: 'file:///foo/bar'),
          equals('https://dart.dev/root'));
      expect(context.relative('..', from: '/foo/bar'), equals('../../root'));

      expect(context.relative('https://dart.dev/foo/bar/baz', from: 'foo/bar'),
          equals('../../../../foo/bar/baz'));
      expect(context.relative('file:///foo/bar/baz', from: 'foo/bar'),
          equals('file:///foo/bar/baz'));
      expect(context.relative('/foo/bar/baz', from: 'foo/bar'),
          equals('../../../../foo/bar/baz'));

      expect(context.relative('..', from: 'foo/bar'), equals('../../..'));
    });

    test('with a root parameter and a relative root', () {
      final r = path.Context(style: path.Style.url, current: 'relative/root');
      expect(r.relative('/foo/bar/baz', from: '/foo/bar'), equals('baz'));
      expect(r.relative('/foo/bar/baz', from: 'https://dart.dev/foo/bar'),
          equals('/foo/bar/baz'));
      expect(r.relative('https://dart.dev/foo/bar/baz', from: '/foo/bar'),
          equals('https://dart.dev/foo/bar/baz'));
      expect(
          r.relative('https://dart.dev/foo/bar/baz', from: 'file:///foo/bar'),
          equals('https://dart.dev/foo/bar/baz'));
      expect(
          r.relative('https://dart.dev/foo/bar/baz',
              from: 'https://dart.dev/foo/bar'),
          equals('baz'));

      expect(r.relative('https://dart.dev/foo/bar/baz', from: 'foo/bar'),
          equals('https://dart.dev/foo/bar/baz'));
      expect(r.relative('file:///foo/bar/baz', from: 'foo/bar'),
          equals('file:///foo/bar/baz'));
      expect(
          r.relative('/foo/bar/baz', from: 'foo/bar'), equals('/foo/bar/baz'));

      expect(r.relative('..', from: 'foo/bar'), equals('../../..'));
    });

    test('from a . root', () {
      final r = path.Context(style: path.Style.url, current: '.');
      expect(r.relative('https://dart.dev/foo/bar/baz'),
          equals('https://dart.dev/foo/bar/baz'));
      expect(r.relative('file:///foo/bar/baz'), equals('file:///foo/bar/baz'));
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
      expect(context.isWithin('https://dart.dev', 'https://dart.dev/foo/bar'),
          isTrue);
      expect(
          context.isWithin('https://dart.dev', 'http://psub.dart.dev/foo/bar'),
          isFalse);
      expect(context.isWithin('https://dart.dev', '/foo/bar'), isTrue);
      expect(context.isWithin('https://dart.dev/foo', '/foo/bar'), isTrue);
      expect(context.isWithin('https://dart.dev/foo', '/bar/baz'), isFalse);
      expect(context.isWithin('baz', 'https://dart.dev/root/path/baz/bang'),
          isTrue);
      expect(context.isWithin('baz', 'https://dart.dev/root/path/bang/baz'),
          isFalse);
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
      expect(context.isWithin('http://example.org/', 'http://example.com/foo'),
          isFalse);
      expect(context.isWithin('http://example.org/', 'https://dart.dev/foo'),
          isFalse);
    });

    test('with root-relative paths', () {
      expect(context.isWithin('/foo', 'https://dart.dev/foo/bar'), isTrue);
      expect(context.isWithin('https://dart.dev/foo', '/foo/bar'), isTrue);
      expect(context.isWithin('/root', 'foo/bar'), isTrue);
      expect(context.isWithin('foo', '/root/path/foo/bar'), isTrue);
      expect(context.isWithin('/foo', '/foo/bar'), isTrue);
    });

    test('from a relative root', () {
      final r = path.Context(style: path.Style.url, current: 'foo/bar');
      expect(r.isWithin('.', 'a/b/c'), isTrue);
      expect(r.isWithin('.', '../a/b/c'), isFalse);
      expect(r.isWithin('.', '../../a/foo/b/c'), isFalse);
      expect(
          r.isWithin('https://dart.dev/', 'https://dart.dev/baz/bang'), isTrue);
      expect(r.isWithin('.', 'https://dart.dev/baz/bang'), isFalse);
    });
  });

  group('equals and hash', () {
    test('simple cases', () {
      expectEquals(context, 'foo/bar', 'foo/bar');
      expectNotEquals(context, 'foo/bar', 'foo/bar/baz');
      expectNotEquals(context, 'foo/bar', 'foo');
      expectNotEquals(context, 'foo/bar', 'foo/baz');
      expectEquals(context, 'foo/bar', '../path/foo/bar');
      expectEquals(context, 'http://google.com', 'http://google.com');
      expectEquals(context, 'https://dart.dev', '../..');
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
      expectEquals(context, 'http://google.com', 'http://google.com/');
      expectEquals(context, 'https://dart.dev/root', '..');
    });

    test('with root-relative paths', () {
      expectEquals(context, '/foo', 'https://dart.dev/foo');
      expectNotEquals(context, '/foo', 'http://google.com/foo');
      expectEquals(context, '/root/path/foo/bar', 'foo/bar');
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
      expect(context.absolute('a'), 'https://dart.dev/root/path/a');
      expect(context.absolute('a', 'b'), 'https://dart.dev/root/path/a/b');
      expect(
          context.absolute('a', 'b', 'c'), 'https://dart.dev/root/path/a/b/c');
      expect(context.absolute('a', 'b', 'c', 'd'),
          'https://dart.dev/root/path/a/b/c/d');
      expect(context.absolute('a', 'b', 'c', 'd', 'e'),
          'https://dart.dev/root/path/a/b/c/d/e');
      expect(context.absolute('a', 'b', 'c', 'd', 'e', 'f'),
          'https://dart.dev/root/path/a/b/c/d/e/f');
      expect(context.absolute('a', 'b', 'c', 'd', 'e', 'f', 'g'),
          'https://dart.dev/root/path/a/b/c/d/e/f/g');
    });

    test('does not add separator if a part ends in one', () {
      expect(context.absolute('a/', 'b', 'c/', 'd'),
          'https://dart.dev/root/path/a/b/c/d');
      expect(context.absolute(r'a\', 'b'), r'https://dart.dev/root/path/a\/b');
    });

    test('ignores parts before an absolute path', () {
      expect(context.absolute('a', '/b', '/c', 'd'), 'https://dart.dev/c/d');
      expect(context.absolute('a', '/b', 'file:///c', 'd'), 'file:///c/d');
      expect(context.absolute('a', r'c:\b', 'c', 'd'), r'c:\b/c/d');
      expect(context.absolute('a', r'\\b', 'c', 'd'),
          r'https://dart.dev/root/path/a/\\b/c/d');
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

  test('withoutExtension', () {
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
      expect(context.fromUri(Uri.parse('https://dart.dev/path/to/foo')),
          'https://dart.dev/path/to/foo');
      expect(context.fromUri(Uri.parse('https://dart.dev/path/to/foo/')),
          'https://dart.dev/path/to/foo/');
      expect(context.fromUri(Uri.parse('file:///path/to/foo')),
          'file:///path/to/foo');
      expect(context.fromUri(Uri.parse('foo/bar')), 'foo/bar');
      expect(context.fromUri(Uri.parse('https://dart.dev/path/to/foo%23bar')),
          'https://dart.dev/path/to/foo%23bar');
      // Since the resulting "path" is also a URL, special characters should
      // remain percent-encoded in the result.
      expect(context.fromUri(Uri.parse('_%7B_%7D_%60_%5E_%20_%22_%25_')),
          r'_%7B_%7D_%60_%5E_%20_%22_%25_');
    });

    test('with a string', () {
      expect(context.fromUri('https://dart.dev/path/to/foo'),
          'https://dart.dev/path/to/foo');
    });
  });

  test('toUri', () {
    expect(context.toUri('https://dart.dev/path/to/foo'),
        Uri.parse('https://dart.dev/path/to/foo'));
    expect(context.toUri('https://dart.dev/path/to/foo/'),
        Uri.parse('https://dart.dev/path/to/foo/'));
    expect(context.toUri('path/to/foo/'), Uri.parse('path/to/foo/'));
    expect(
        context.toUri('file:///path/to/foo'), Uri.parse('file:///path/to/foo'));
    expect(context.toUri('foo/bar'), Uri.parse('foo/bar'));
    expect(context.toUri('https://dart.dev/path/to/foo%23bar'),
        Uri.parse('https://dart.dev/path/to/foo%23bar'));
    // Since the input path is also a URI, special characters should already
    // be percent encoded there too.
    expect(context.toUri(r'http://foo.com/_%7B_%7D_%60_%5E_%20_%22_%25_'),
        Uri.parse('http://foo.com/_%7B_%7D_%60_%5E_%20_%22_%25_'));
    expect(context.toUri(r'_%7B_%7D_%60_%5E_%20_%22_%25_'),
        Uri.parse('_%7B_%7D_%60_%5E_%20_%22_%25_'));
    expect(context.toUri(''), Uri.parse(''));
  });

  group('prettyUri', () {
    test('with a file: URI', () {
      expect(context.prettyUri(Uri.parse('file:///root/path/a/b')),
          'file:///root/path/a/b');
    });

    test('with an http: URI', () {
      expect(context.prettyUri('https://dart.dev/root/path/a/b'), 'a/b');
      expect(context.prettyUri('https://dart.dev/root/path/a/../b'), 'b');
      expect(context.prettyUri('https://dart.dev/other/path/a/b'),
          'https://dart.dev/other/path/a/b');
      expect(context.prettyUri('http://psub.dart.dev/root/path'),
          'http://psub.dart.dev/root/path');
      expect(context.prettyUri('https://dart.dev/root/other'), '../other');
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
