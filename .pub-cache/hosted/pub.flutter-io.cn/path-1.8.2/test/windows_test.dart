// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  final context =
      path.Context(style: path.Style.windows, current: r'C:\root\path');

  test('separator', () {
    expect(context.separator, '\\');
  });

  test('extension', () {
    expect(context.extension(''), '');
    expect(context.extension('.'), '');
    expect(context.extension('..'), '');
    expect(context.extension('a/..'), '');
    expect(context.extension('foo.dart'), '.dart');
    expect(context.extension('foo.dart.js'), '.js');
    expect(context.extension('foo bargule fisk.dart.js'), '.js');
    expect(context.extension(r'a.b\c'), '');
    expect(context.extension('a.b/c.d'), '.d');
    expect(context.extension(r'~\.bashrc'), '');
    expect(context.extension(r'a.b/c'), r'');
    expect(context.extension(r'foo.dart\'), '.dart');
    expect(context.extension(r'foo.dart\\'), '.dart');
    expect(context.extension('a.b/..', 2), '');
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
    expect(context.rootPrefix(r'a\b'), '');
    expect(context.rootPrefix(r'C:\a\c'), r'C:\');
    expect(context.rootPrefix('C:\\'), r'C:\');
    expect(context.rootPrefix('C:/'), 'C:/');
    expect(context.rootPrefix(r'\\server\share\a\b'), r'\\server\share');
    expect(context.rootPrefix(r'\\server\share'), r'\\server\share');
    expect(context.rootPrefix(r'\\server\'), r'\\server\');
    expect(context.rootPrefix(r'\\server'), r'\\server');
    expect(context.rootPrefix(r'\a\b'), r'\');
    expect(context.rootPrefix(r'/a/b'), r'/');
    expect(context.rootPrefix(r'\'), r'\');
    expect(context.rootPrefix(r'/'), r'/');
  });

  test('dirname', () {
    expect(context.dirname(r''), '.');
    expect(context.dirname(r'a'), '.');
    expect(context.dirname(r'a\b'), 'a');
    expect(context.dirname(r'a\b\c'), r'a\b');
    expect(context.dirname(r'a\b.c'), 'a');
    expect(context.dirname(r'a\'), '.');
    expect(context.dirname('a/'), '.');
    expect(context.dirname(r'a\.'), 'a');
    expect(context.dirname(r'a\b/c'), r'a\b');
    expect(context.dirname(r'C:\a'), r'C:\');
    expect(context.dirname(r'C:\\\a'), r'C:\');
    expect(context.dirname(r'C:\'), r'C:\');
    expect(context.dirname(r'C:\\\'), r'C:\');
    expect(context.dirname(r'a\b\'), r'a');
    expect(context.dirname(r'a/b\c'), 'a/b');
    expect(context.dirname(r'a\\'), r'.');
    expect(context.dirname(r'a\b\\'), 'a');
    expect(context.dirname(r'a\\b'), 'a');
    expect(context.dirname(r'foo bar\gule fisk'), 'foo bar');
    expect(context.dirname(r'\\server\share'), r'\\server\share');
    expect(context.dirname(r'\\server\share\dir'), r'\\server\share');
    expect(context.dirname(r'\a'), r'\');
    expect(context.dirname(r'/a'), r'/');
    expect(context.dirname(r'\'), r'\');
    expect(context.dirname(r'/'), r'/');
  });

  test('basename', () {
    expect(context.basename(r''), '');
    expect(context.basename(r'.'), '.');
    expect(context.basename(r'..'), '..');
    expect(context.basename(r'.hest'), '.hest');
    expect(context.basename(r'a'), 'a');
    expect(context.basename(r'a\b'), 'b');
    expect(context.basename(r'a\b\c'), 'c');
    expect(context.basename(r'a\b.c'), 'b.c');
    expect(context.basename(r'a\'), 'a');
    expect(context.basename(r'a/'), 'a');
    expect(context.basename(r'a\.'), '.');
    expect(context.basename(r'a\b/c'), r'c');
    expect(context.basename(r'C:\a'), 'a');
    expect(context.basename(r'C:\'), r'C:\');
    expect(context.basename(r'a\b\'), 'b');
    expect(context.basename(r'a/b\c'), 'c');
    expect(context.basename(r'a\\'), 'a');
    expect(context.basename(r'a\b\\'), 'b');
    expect(context.basename(r'a\\b'), 'b');
    expect(context.basename(r'a\\b'), 'b');
    expect(context.basename(r'a\fisk hest.ma pa'), 'fisk hest.ma pa');
    expect(context.basename(r'\\server\share'), r'\\server\share');
    expect(context.basename(r'\\server\share\dir'), r'dir');
    expect(context.basename(r'\a'), r'a');
    expect(context.basename(r'/a'), r'a');
    expect(context.basename(r'\'), r'\');
    expect(context.basename(r'/'), r'/');
  });

  test('basenameWithoutExtension', () {
    expect(context.basenameWithoutExtension(''), '');
    expect(context.basenameWithoutExtension('.'), '.');
    expect(context.basenameWithoutExtension('..'), '..');
    expect(context.basenameWithoutExtension('.hest'), '.hest');
    expect(context.basenameWithoutExtension('a'), 'a');
    expect(context.basenameWithoutExtension(r'a\b'), 'b');
    expect(context.basenameWithoutExtension(r'a\b\c'), 'c');
    expect(context.basenameWithoutExtension(r'a\b.c'), 'b');
    expect(context.basenameWithoutExtension(r'a\'), 'a');
    expect(context.basenameWithoutExtension(r'a\.'), '.');
    expect(context.basenameWithoutExtension(r'a\b/c'), r'c');
    expect(context.basenameWithoutExtension(r'a\.bashrc'), '.bashrc');
    expect(context.basenameWithoutExtension(r'a\b\c.d.e'), 'c.d');
    expect(context.basenameWithoutExtension(r'a\\'), 'a');
    expect(context.basenameWithoutExtension(r'a\b\\'), 'b');
    expect(context.basenameWithoutExtension(r'a\\b'), 'b');
    expect(context.basenameWithoutExtension(r'a\b.c\'), 'b');
    expect(context.basenameWithoutExtension(r'a\b.c\\'), 'b');
    expect(context.basenameWithoutExtension(r'C:\f h.ma pa.f s'), 'f h.ma pa');
  });

  test('isAbsolute', () {
    expect(context.isAbsolute(''), false);
    expect(context.isAbsolute('.'), false);
    expect(context.isAbsolute('..'), false);
    expect(context.isAbsolute('a'), false);
    expect(context.isAbsolute(r'a\b'), false);
    expect(context.isAbsolute(r'\a\b'), true);
    expect(context.isAbsolute(r'\'), true);
    expect(context.isAbsolute(r'/a/b'), true);
    expect(context.isAbsolute(r'/'), true);
    expect(context.isAbsolute('~'), false);
    expect(context.isAbsolute('.'), false);
    expect(context.isAbsolute(r'..\a'), false);
    expect(context.isAbsolute(r'a:/a\b'), true);
    expect(context.isAbsolute(r'D:/a/b'), true);
    expect(context.isAbsolute(r'c:\'), true);
    expect(context.isAbsolute(r'B:\'), true);
    expect(context.isAbsolute(r'c:\a'), true);
    expect(context.isAbsolute(r'C:\a'), true);
    expect(context.isAbsolute(r'\\server\share'), true);
    expect(context.isAbsolute(r'\\server\share\path'), true);
  });

  test('isRelative', () {
    expect(context.isRelative(''), true);
    expect(context.isRelative('.'), true);
    expect(context.isRelative('..'), true);
    expect(context.isRelative('a'), true);
    expect(context.isRelative(r'a\b'), true);
    expect(context.isRelative(r'\a\b'), false);
    expect(context.isRelative(r'\'), false);
    expect(context.isRelative(r'/a/b'), false);
    expect(context.isRelative(r'/'), false);
    expect(context.isRelative('~'), true);
    expect(context.isRelative('.'), true);
    expect(context.isRelative(r'..\a'), true);
    expect(context.isRelative(r'a:/a\b'), false);
    expect(context.isRelative(r'D:/a/b'), false);
    expect(context.isRelative(r'c:\'), false);
    expect(context.isRelative(r'B:\'), false);
    expect(context.isRelative(r'c:\a'), false);
    expect(context.isRelative(r'C:\a'), false);
    expect(context.isRelative(r'\\server\share'), false);
    expect(context.isRelative(r'\\server\share\path'), false);
  });

  test('isRootRelative', () {
    expect(context.isRootRelative(''), false);
    expect(context.isRootRelative('.'), false);
    expect(context.isRootRelative('..'), false);
    expect(context.isRootRelative('a'), false);
    expect(context.isRootRelative(r'a\b'), false);
    expect(context.isRootRelative(r'\a\b'), true);
    expect(context.isRootRelative(r'\'), true);
    expect(context.isRootRelative(r'/a/b'), true);
    expect(context.isRootRelative(r'/'), true);
    expect(context.isRootRelative('~'), false);
    expect(context.isRootRelative('.'), false);
    expect(context.isRootRelative(r'..\a'), false);
    expect(context.isRootRelative(r'a:/a\b'), false);
    expect(context.isRootRelative(r'D:/a/b'), false);
    expect(context.isRootRelative(r'c:\'), false);
    expect(context.isRootRelative(r'B:\'), false);
    expect(context.isRootRelative(r'c:\a'), false);
    expect(context.isRootRelative(r'C:\a'), false);
    expect(context.isRootRelative(r'\\server\share'), false);
    expect(context.isRootRelative(r'\\server\share\path'), false);
  });

  group('join', () {
    test('allows up to eight parts', () {
      expect(context.join('a'), 'a');
      expect(context.join('a', 'b'), r'a\b');
      expect(context.join('a', 'b', 'c'), r'a\b\c');
      expect(context.join('a', 'b', 'c', 'd'), r'a\b\c\d');
      expect(context.join('a', 'b', 'c', 'd', 'e'), r'a\b\c\d\e');
      expect(context.join('a', 'b', 'c', 'd', 'e', 'f'), r'a\b\c\d\e\f');
      expect(context.join('a', 'b', 'c', 'd', 'e', 'f', 'g'), r'a\b\c\d\e\f\g');
      expect(context.join('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'),
          r'a\b\c\d\e\f\g\h');
    });

    test('does not add separator if a part ends or begins in one', () {
      expect(context.join(r'a\', 'b', r'c\', 'd'), r'a\b\c\d');
      expect(context.join('a/', 'b'), r'a/b');
    });

    test('ignores parts before an absolute path', () {
      expect(context.join('a', r'\b', r'\c', 'd'), r'\c\d');
      expect(context.join('a', '/b', '/c', 'd'), r'/c\d');
      expect(context.join('a', r'c:\b', 'c', 'd'), r'c:\b\c\d');
      expect(context.join('a', r'\\b\c', r'\\d\e', 'f'), r'\\d\e\f');
      expect(context.join('a', r'c:\b', r'\c', 'd'), r'c:\c\d');
      expect(context.join('a', r'\\b\c\d', r'\e', 'f'), r'\\b\c\e\f');
    });

    test('ignores trailing nulls', () {
      expect(context.join('a', null), equals('a'));
      expect(context.join('a', 'b', 'c', null, null), equals(r'a\b\c'));
    });

    test('ignores empty strings', () {
      expect(context.join(''), '');
      expect(context.join('', ''), '');
      expect(context.join('', 'a'), 'a');
      expect(context.join('a', '', 'b', '', '', '', 'c'), r'a\b\c');
      expect(context.join('a', 'b', ''), r'a\b');
    });

    test('disallows intermediate nulls', () {
      expect(() => context.join('a', null, 'b'), throwsArgumentError);
    });

    test('join does not modify internal ., .., or trailing separators', () {
      expect(context.join('a/', 'b/c/'), 'a/b/c/');
      expect(context.join(r'a\b\./c\..\\', r'd\..\.\..\\e\f\\'),
          r'a\b\./c\..\\d\..\.\..\\e\f\\');
      expect(context.join(r'a\b', r'c\..\..\..\..'), r'a\b\c\..\..\..\..');
      expect(context.join(r'a', 'b${context.separator}'), r'a\b\');
    });
  });

  group('joinAll', () {
    test('allows more than eight parts', () {
      expect(context.joinAll(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i']),
          r'a\b\c\d\e\f\g\h\i');
    });

    test('does not add separator if a part ends or begins in one', () {
      expect(context.joinAll([r'a\', 'b', r'c\', 'd']), r'a\b\c\d');
      expect(context.joinAll(['a/', 'b']), r'a/b');
    });

    test('ignores parts before an absolute path', () {
      expect(context.joinAll(['a', r'\b', r'\c', 'd']), r'\c\d');
      expect(context.joinAll(['a', '/b', '/c', 'd']), r'/c\d');
      expect(context.joinAll(['a', r'c:\b', 'c', 'd']), r'c:\b\c\d');
      expect(context.joinAll(['a', r'\\b\c', r'\\d\e', 'f']), r'\\d\e\f');
      expect(context.joinAll(['a', r'c:\b', r'\c', 'd']), r'c:\c\d');
      expect(context.joinAll(['a', r'\\b\c\d', r'\e', 'f']), r'\\b\c\e\f');
    });
  });

  group('split', () {
    test('simple cases', () {
      expect(context.split(''), []);
      expect(context.split('.'), ['.']);
      expect(context.split('..'), ['..']);
      expect(context.split('foo'), equals(['foo']));
      expect(context.split(r'foo\bar.txt'), equals(['foo', 'bar.txt']));
      expect(context.split(r'foo\bar/baz'), equals(['foo', 'bar', 'baz']));
      expect(context.split(r'foo\..\bar\.\baz'),
          equals(['foo', '..', 'bar', '.', 'baz']));
      expect(context.split(r'foo\\bar\\\baz'), equals(['foo', 'bar', 'baz']));
      expect(context.split(r'foo\/\baz'), equals(['foo', 'baz']));
      expect(context.split('.'), equals(['.']));
      expect(context.split(''), equals([]));
      expect(context.split('foo/'), equals(['foo']));
      expect(context.split(r'C:\'), equals([r'C:\']));
    });

    test('includes the root for absolute paths', () {
      expect(context.split(r'C:\foo\bar\baz'),
          equals([r'C:\', 'foo', 'bar', 'baz']));
      expect(context.split(r'C:\\'), equals([r'C:\']));

      expect(context.split(r'\\server\share\foo\bar\baz'),
          equals([r'\\server\share', 'foo', 'bar', 'baz']));
      expect(context.split(r'\\server\share'), equals([r'\\server\share']));

      expect(
          context.split(r'\foo\bar\baz'), equals([r'\', 'foo', 'bar', 'baz']));
      expect(context.split(r'\'), equals([r'\']));
    });
  });

  group('normalize', () {
    test('simple cases', () {
      expect(context.normalize(''), '.');
      expect(context.normalize('.'), '.');
      expect(context.normalize('..'), '..');
      expect(context.normalize('a'), 'a');
      expect(context.normalize('/a/b'), r'\a\b');
      expect(context.normalize(r'\'), r'\');
      expect(context.normalize(r'\a\b'), r'\a\b');
      expect(context.normalize('/'), r'\');
      expect(context.normalize('C:/'), r'C:\');
      expect(context.normalize(r'C:\'), r'C:\');
      expect(context.normalize(r'\\server\share'), r'\\server\share');
      expect(context.normalize('a\\.\\\xc5\u0bf8-;\u{1f085}\u{00}\\c\\d\\..\\'),
          'a\\\xc5\u0bf8-;\u{1f085}\u{00}\x5cc');
    });

    test('collapses redundant separators', () {
      expect(context.normalize(r'a\b\c'), r'a\b\c');
      expect(context.normalize(r'a\\b\\\c\\\\d'), r'a\b\c\d');
    });

    test('eliminates "." parts', () {
      expect(context.normalize(r'.\'), '.');
      expect(context.normalize(r'c:\.'), r'c:\');
      expect(context.normalize(r'c:\foo\.'), r'c:\foo');
      expect(context.normalize(r'B:\.\'), r'B:\');
      expect(context.normalize(r'\\server\share\.'), r'\\server\share');
      expect(context.normalize(r'.\.'), '.');
      expect(context.normalize(r'a\.\b'), r'a\b');
      expect(context.normalize(r'a\.b\c'), r'a\.b\c');
      expect(context.normalize(r'a\./.\b\.\c'), r'a\b\c');
      expect(context.normalize(r'.\./a'), 'a');
      expect(context.normalize(r'a/.\.'), 'a');
      expect(context.normalize(r'\.'), r'\');
      expect(context.normalize('/.'), r'\');
    });

    test('eliminates ".." parts', () {
      expect(context.normalize('..'), '..');
      expect(context.normalize(r'..\'), '..');
      expect(context.normalize(r'..\..\..'), r'..\..\..');
      expect(context.normalize(r'../..\..\'), r'..\..\..');
      expect(context.normalize(r'\\server\share\..'), r'\\server\share');
      expect(
          context.normalize(r'\\server\share\..\../..\a'), r'\\server\share\a');
      expect(context.normalize(r'c:\..'), r'c:\');
      expect(context.normalize(r'c:\foo\..'), r'c:\');
      expect(context.normalize(r'A:/..\..\..'), r'A:\');
      expect(context.normalize(r'b:\..\..\..\a'), r'b:\a');
      expect(context.normalize(r'b:\r\..\..\..\a\c\.\..'), r'b:\a');
      expect(context.normalize(r'a\..'), '.');
      expect(context.normalize(r'..\a'), r'..\a');
      expect(context.normalize(r'c:\..\a'), r'c:\a');
      expect(context.normalize(r'\..\a'), r'\a');
      expect(context.normalize(r'a\b\..'), 'a');
      expect(context.normalize(r'..\a\b\..'), r'..\a');
      expect(context.normalize(r'a\..\b'), 'b');
      expect(context.normalize(r'a\.\..\b'), 'b');
      expect(context.normalize(r'a\b\c\..\..\d\e\..'), r'a\d');
      expect(context.normalize(r'a\b\..\..\..\..\c'), r'..\..\c');
      expect(context.normalize(r'a/b/c/../../..d/./.e/f././'), r'a\..d\.e\f.');
    });

    test('removes trailing separators', () {
      expect(context.normalize(r'.\'), '.');
      expect(context.normalize(r'.\\'), '.');
      expect(context.normalize(r'a/'), 'a');
      expect(context.normalize(r'a\b\'), r'a\b');
      expect(context.normalize(r'a\b\\\'), r'a\b');
    });

    test('normalizes separators', () {
      expect(context.normalize(r'a/b\c'), r'a\b\c');
    });

    test('when canonicalizing', () {
      expect(context.canonicalize('.'), r'c:\root\path');
      expect(context.canonicalize('foo/bar'), r'c:\root\path\foo\bar');
      expect(context.canonicalize('FoO'), r'c:\root\path\foo');
      expect(context.canonicalize('/foo'), r'c:\foo');
      expect(context.canonicalize('D:/foo'), r'd:\foo');
    });
  });

  group('relative', () {
    group('from absolute root', () {
      test('given absolute path in root', () {
        expect(context.relative(r'C:\'), r'..\..');
        expect(context.relative(r'C:\root'), '..');
        expect(context.relative(r'\root'), '..');
        expect(context.relative(r'C:\root\path'), '.');
        expect(context.relative(r'\root\path'), '.');
        expect(context.relative(r'C:\root\path\a'), 'a');
        expect(context.relative(r'\root\path\a'), 'a');
        expect(context.relative(r'C:\root\path\a\b.txt'), r'a\b.txt');
        expect(context.relative(r'C:\root\a\b.txt'), r'..\a\b.txt');
        expect(context.relative(r'C:/'), r'..\..');
        expect(context.relative(r'C:/root'), '..');
        expect(context.relative(r'c:\'), r'..\..');
        expect(context.relative(r'c:\root'), '..');
      });

      test('given absolute path outside of root', () {
        expect(context.relative(r'C:\a\b'), r'..\..\a\b');
        expect(context.relative(r'\a\b'), r'..\..\a\b');
        expect(context.relative(r'C:\root\path\a'), 'a');
        expect(context.relative(r'C:\root\path\a\b.txt'), r'a\b.txt');
        expect(context.relative(r'C:\root\a\b.txt'), r'..\a\b.txt');
        expect(context.relative(r'C:/a/b'), r'..\..\a\b');
        expect(context.relative(r'C:/root/path/a'), 'a');
        expect(context.relative(r'c:\a\b'), r'..\..\a\b');
        expect(context.relative(r'c:\root\path\a'), 'a');
      });

      test('given absolute path on different drive', () {
        expect(context.relative(r'D:\a\b'), r'D:\a\b');
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(context.relative(''), '.');
        expect(context.relative('.'), '.');
        expect(context.relative('a'), 'a');
        expect(context.relative(r'a\b.txt'), r'a\b.txt');
        expect(context.relative(r'..\a\b.txt'), r'..\a\b.txt');
        expect(context.relative(r'a\.\b\..\c.txt'), r'a\c.txt');
      });

      test('is case-insensitive', () {
        expect(context.relative(r'c:\'), r'..\..');
        expect(context.relative(r'c:\RoOt'), r'..');
        expect(context.relative(r'c:\rOoT\pAtH\a'), r'a');
      });

      // Regression
      test('from root-only path', () {
        expect(context.relative(r'C:\', from: r'C:\'), '.');
        expect(context.relative(r'C:\root\path', from: r'C:\'), r'root\path');
      });
    });

    group('from relative root', () {
      final r = path.Context(style: path.Style.windows, current: r'foo\bar');

      test('given absolute path', () {
        expect(r.relative(r'C:\'), equals(r'C:\'));
        expect(r.relative(r'C:\a\b'), equals(r'C:\a\b'));
        expect(r.relative(r'\'), equals(r'\'));
        expect(r.relative(r'\a\b'), equals(r'\a\b'));
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(r.relative(''), '.');
        expect(r.relative('.'), '.');
        expect(r.relative('..'), '..');
        expect(r.relative('a'), 'a');
        expect(r.relative(r'a\b.txt'), r'a\b.txt');
        expect(r.relative(r'..\a/b.txt'), r'..\a\b.txt');
        expect(r.relative(r'a\./b\../c.txt'), r'a\c.txt');
      });
    });

    group('from root-relative root', () {
      final r = path.Context(style: path.Style.windows, current: r'\foo\bar');

      test('given absolute path', () {
        expect(r.relative(r'C:\'), equals(r'C:\'));
        expect(r.relative(r'C:\a\b'), equals(r'C:\a\b'));
        expect(r.relative(r'\'), equals(r'..\..'));
        expect(r.relative(r'\a\b'), equals(r'..\..\a\b'));
        expect(r.relative('/'), equals(r'..\..'));
        expect(r.relative('/a/b'), equals(r'..\..\a\b'));
      });

      test('given relative path', () {
        // The path is considered relative to the root, so it basically just
        // normalizes.
        expect(r.relative(''), '.');
        expect(r.relative('.'), '.');
        expect(r.relative('..'), '..');
        expect(r.relative('a'), 'a');
        expect(r.relative(r'a\b.txt'), r'a\b.txt');
        expect(r.relative(r'..\a/b.txt'), r'..\a\b.txt');
        expect(r.relative(r'a\./b\../c.txt'), r'a\c.txt');
      });
    });

    test('from a root with extension', () {
      final r = path.Context(style: path.Style.windows, current: r'C:\dir.ext');
      expect(r.relative(r'C:\dir.ext\file'), 'file');
    });

    test('with a root parameter', () {
      expect(context.relative(r'C:\foo\bar\baz', from: r'C:\foo\bar'),
          equals('baz'));
      expect(
          context.relative('..', from: r'C:\foo\bar'), equals(r'..\..\root'));
      expect(context.relative('..', from: r'D:\foo\bar'), equals(r'C:\root'));
      expect(context.relative(r'C:\foo\bar\baz', from: r'foo\bar'),
          equals(r'..\..\..\..\foo\bar\baz'));
      expect(context.relative('..', from: r'foo\bar'), equals(r'..\..\..'));
    });

    test('with a root parameter and a relative root', () {
      final r =
          path.Context(style: path.Style.windows, current: r'relative\root');
      expect(r.relative(r'C:\foo\bar\baz', from: r'C:\foo\bar'), equals('baz'));
      expect(() => r.relative('..', from: r'C:\foo\bar'), throwsPathException);
      expect(r.relative(r'C:\foo\bar\baz', from: r'foo\bar'),
          equals(r'C:\foo\bar\baz'));
      expect(r.relative('..', from: r'foo\bar'), equals(r'..\..\..'));
    });

    test('given absolute with different root prefix', () {
      expect(context.relative(r'D:\a\b'), r'D:\a\b');
      expect(context.relative(r'\\server\share\a\b'), r'\\server\share\a\b');
    });

    test('from a . root', () {
      final r = path.Context(style: path.Style.windows, current: '.');
      expect(r.relative(r'C:\foo\bar\baz'), equals(r'C:\foo\bar\baz'));
      expect(r.relative(r'foo\bar\baz'), equals(r'foo\bar\baz'));
      expect(r.relative(r'\foo\bar\baz'), equals(r'\foo\bar\baz'));
    });
  });

  group('isWithin', () {
    test('simple cases', () {
      expect(context.isWithin(r'foo\bar', r'foo\bar'), isFalse);
      expect(context.isWithin(r'foo\bar', r'foo\bar\baz'), isTrue);
      expect(context.isWithin(r'foo\bar', r'foo\baz'), isFalse);
      expect(context.isWithin(r'foo\bar', r'..\path\foo\bar\baz'), isTrue);
      expect(context.isWithin(r'C:\', r'C:\foo\bar'), isTrue);
      expect(context.isWithin(r'C:\', r'D:\foo\bar'), isFalse);
      expect(context.isWithin(r'C:\', r'\foo\bar'), isTrue);
      expect(context.isWithin(r'C:\foo', r'\foo\bar'), isTrue);
      expect(context.isWithin(r'C:\foo', r'\bar\baz'), isFalse);
      expect(context.isWithin(r'baz', r'C:\root\path\baz\bang'), isTrue);
      expect(context.isWithin(r'baz', r'C:\root\path\bang\baz'), isFalse);
    });

    test('complex cases', () {
      expect(context.isWithin(r'foo\.\bar', r'foo\bar\baz'), isTrue);
      expect(context.isWithin(r'foo\\bar', r'foo\bar\baz'), isTrue);
      expect(context.isWithin(r'foo\qux\..\bar', r'foo\bar\baz'), isTrue);
      expect(context.isWithin(r'foo\bar', r'foo\bar\baz\..\..'), isFalse);
      expect(context.isWithin(r'foo\bar', r'foo\bar\\\'), isFalse);
      expect(context.isWithin(r'foo\.bar', r'foo\.bar\baz'), isTrue);
      expect(context.isWithin(r'foo\.\bar', r'foo\.bar\baz'), isFalse);
      expect(context.isWithin(r'foo\..bar', r'foo\..bar\baz'), isTrue);
      expect(context.isWithin(r'foo\bar', r'foo\bar\baz\..'), isFalse);
      expect(context.isWithin(r'foo\bar', r'foo\bar\baz\..\qux'), isTrue);
      expect(context.isWithin(r'C:\', 'C:/foo'), isTrue);
      expect(context.isWithin(r'C:\', r'D:\foo'), isFalse);
      expect(context.isWithin(r'C:\', r'\\foo\bar'), isFalse);
    });

    test('with root-relative paths', () {
      expect(context.isWithin(r'\foo', r'C:\foo\bar'), isTrue);
      expect(context.isWithin(r'C:\foo', r'\foo\bar'), isTrue);
      expect(context.isWithin(r'\root', r'foo\bar'), isTrue);
      expect(context.isWithin(r'foo', r'\root\path\foo\bar'), isTrue);
      expect(context.isWithin(r'\foo', r'\foo\bar'), isTrue);
    });

    test('from a relative root', () {
      final r = path.Context(style: path.Style.windows, current: r'foo\bar');
      expect(r.isWithin('.', r'a\b\c'), isTrue);
      expect(r.isWithin('.', r'..\a\b\c'), isFalse);
      expect(r.isWithin('.', r'..\..\a\foo\b\c'), isFalse);
      expect(r.isWithin(r'C:\', r'C:\baz\bang'), isTrue);
      expect(r.isWithin('.', r'C:\baz\bang'), isFalse);
    });

    test('is case-insensitive', () {
      expect(context.isWithin(r'FoO', r'fOo\bar'), isTrue);
      expect(context.isWithin(r'C:\', r'c:\foo'), isTrue);
      expect(context.isWithin(r'fOo\qux\..\BaR', r'FoO\bAr\baz'), isTrue);
    });
  });

  group('equals and hash', () {
    test('simple cases', () {
      expectEquals(context, r'foo\bar', r'foo\bar');
      expectNotEquals(context, r'foo\bar', r'foo\bar\baz');
      expectNotEquals(context, r'foo\bar', r'foo');
      expectNotEquals(context, r'foo\bar', r'foo\baz');
      expectEquals(context, r'foo\bar', r'..\path\foo\bar');
      expectEquals(context, r'D:\', r'D:\');
      expectEquals(context, r'C:\', r'..\..');
      expectEquals(context, r'baz', r'C:\root\path\baz');
    });

    test('complex cases', () {
      expectEquals(context, r'foo\.\bar', r'foo\bar');
      expectEquals(context, r'foo\\bar', r'foo\bar');
      expectEquals(context, r'foo\qux\..\bar', r'foo\bar');
      expectNotEquals(context, r'foo\qux\..\bar', r'foo\qux');
      expectNotEquals(context, r'foo\bar', r'foo\bar\baz\..\..');
      expectEquals(context, r'foo\bar', r'foo\bar\\\');
      expectEquals(context, r'foo\.bar', r'foo\.bar');
      expectNotEquals(context, r'foo\.\bar', r'foo\.bar');
      expectEquals(context, r'foo\..bar', r'foo\..bar');
      expectNotEquals(context, r'foo\..\bar', r'foo\..bar');
      expectEquals(context, r'foo\bar', r'foo\bar\baz\..');
      expectEquals(context, r'FoO\bAr', r'foo\bar');
      expectEquals(context, r'foo/\bar', r'foo\/bar');
      expectEquals(context, r'c:\', r'C:\');
      expectEquals(context, r'C:\root', r'..');
    });

    test('with root-relative paths', () {
      expectEquals(context, r'\foo', r'C:\foo');
      expectNotEquals(context, r'\foo', 'http://google.com/foo');
      expectEquals(context, r'C:\root\path\foo\bar', r'foo\bar');
    });

    test('from a relative root', () {
      final r = path.Context(style: path.Style.windows, current: r'foo\bar');
      expectEquals(r, r'a\b', r'a\b');
      expectNotEquals(r, '.', r'foo\bar');
      expectNotEquals(r, '.', r'..\a\b');
      expectEquals(r, '.', r'..\bar');
      expectEquals(r, r'C:\baz\bang', r'C:\baz\bang');
      expectNotEquals(r, r'baz\bang', r'C:\baz\bang');
    });
  });

  group('absolute', () {
    test('allows up to seven parts', () {
      expect(context.absolute('a'), r'C:\root\path\a');
      expect(context.absolute('a', 'b'), r'C:\root\path\a\b');
      expect(context.absolute('a', 'b', 'c'), r'C:\root\path\a\b\c');
      expect(context.absolute('a', 'b', 'c', 'd'), r'C:\root\path\a\b\c\d');
      expect(
          context.absolute('a', 'b', 'c', 'd', 'e'), r'C:\root\path\a\b\c\d\e');
      expect(context.absolute('a', 'b', 'c', 'd', 'e', 'f'),
          r'C:\root\path\a\b\c\d\e\f');
      expect(context.absolute('a', 'b', 'c', 'd', 'e', 'f', 'g'),
          r'C:\root\path\a\b\c\d\e\f\g');
    });

    test('does not add separator if a part ends in one', () {
      expect(context.absolute(r'a\', 'b', r'c\', 'd'), r'C:\root\path\a\b\c\d');
      expect(context.absolute('a/', 'b'), r'C:\root\path\a/b');
    });

    test('ignores parts before an absolute path', () {
      expect(context.absolute('a', '/b', '/c', 'd'), r'C:\c\d');
      expect(context.absolute('a', r'\b', r'\c', 'd'), r'C:\c\d');
      expect(context.absolute('a', r'c:\b', 'c', 'd'), r'c:\b\c\d');
      expect(context.absolute('a', r'\\b\c', r'\\d\e', 'f'), r'\\d\e\f');
    });
  });

  test('withoutExtension', () {
    expect(context.withoutExtension(''), '');
    expect(context.withoutExtension('a'), 'a');
    expect(context.withoutExtension('.a'), '.a');
    expect(context.withoutExtension('a.b'), 'a');
    expect(context.withoutExtension(r'a\b.c'), r'a\b');
    expect(context.withoutExtension(r'a\b.c.d'), r'a\b.c');
    expect(context.withoutExtension(r'a\'), r'a\');
    expect(context.withoutExtension(r'a\b\'), r'a\b\');
    expect(context.withoutExtension(r'a\.'), r'a\.');
    expect(context.withoutExtension(r'a\.b'), r'a\.b');
    expect(context.withoutExtension(r'a.b\c'), r'a.b\c');
    expect(context.withoutExtension(r'a/b.c/d'), r'a/b.c/d');
    expect(context.withoutExtension(r'a\b/c'), r'a\b/c');
    expect(context.withoutExtension(r'a\b/c.d'), r'a\b/c');
    expect(context.withoutExtension(r'a.b/c'), r'a.b/c');
    expect(context.withoutExtension(r'a\b.c\'), r'a\b\');
  });

  test('withoutExtension', () {
    expect(context.setExtension('', '.x'), '.x');
    expect(context.setExtension('a', '.x'), 'a.x');
    expect(context.setExtension('.a', '.x'), '.a.x');
    expect(context.setExtension('a.b', '.x'), 'a.x');
    expect(context.setExtension(r'a\b.c', '.x'), r'a\b.x');
    expect(context.setExtension(r'a\b.c.d', '.x'), r'a\b.c.x');
    expect(context.setExtension(r'a\', '.x'), r'a\.x');
    expect(context.setExtension(r'a\b\', '.x'), r'a\b\.x');
    expect(context.setExtension(r'a\.', '.x'), r'a\..x');
    expect(context.setExtension(r'a\.b', '.x'), r'a\.b.x');
    expect(context.setExtension(r'a.b\c', '.x'), r'a.b\c.x');
    expect(context.setExtension(r'a/b.c/d', '.x'), r'a/b.c/d.x');
    expect(context.setExtension(r'a\b/c', '.x'), r'a\b/c.x');
    expect(context.setExtension(r'a\b/c.d', '.x'), r'a\b/c.x');
    expect(context.setExtension(r'a.b/c', '.x'), r'a.b/c.x');
    expect(context.setExtension(r'a\b.c\', '.x'), r'a\b\.x');
  });

  group('fromUri', () {
    test('with a URI', () {
      expect(context.fromUri(Uri.parse('file:///C:/path/to/foo')),
          r'C:\path\to\foo');
      expect(context.fromUri(Uri.parse('file://server/share/path/to/foo')),
          r'\\server\share\path\to\foo');
      expect(context.fromUri(Uri.parse('file:///C:/')), r'C:\');
      expect(
          context.fromUri(Uri.parse('file://server/share')), r'\\server\share');
      expect(context.fromUri(Uri.parse('foo/bar')), r'foo\bar');
      expect(context.fromUri(Uri.parse('/C:/path/to/foo')), r'C:\path\to\foo');
      expect(
          context.fromUri(Uri.parse('///C:/path/to/foo')), r'C:\path\to\foo');
      expect(context.fromUri(Uri.parse('//server/share/path/to/foo')),
          r'\\server\share\path\to\foo');
      expect(context.fromUri(Uri.parse('file:///C:/path/to/foo%23bar')),
          r'C:\path\to\foo#bar');
      expect(
          context.fromUri(Uri.parse('file://server/share/path/to/foo%23bar')),
          r'\\server\share\path\to\foo#bar');
      expect(context.fromUri(Uri.parse('_%7B_%7D_%60_%5E_%20_%22_%25_')),
          r'_{_}_`_^_ _"_%_');
      expect(context.fromUri(Uri.parse('/foo')), r'\foo');
      expect(() => context.fromUri(Uri.parse('https://dart.dev')),
          throwsArgumentError);
    });

    test('with a string', () {
      expect(context.fromUri('file:///C:/path/to/foo'), r'C:\path\to\foo');
    });
  });

  test('toUri', () {
    expect(
        context.toUri(r'C:\path\to\foo'), Uri.parse('file:///C:/path/to/foo'));
    expect(context.toUri(r'C:\path\to\foo\'),
        Uri.parse('file:///C:/path/to/foo/'));
    expect(context.toUri(r'path\to\foo\'), Uri.parse('path/to/foo/'));
    expect(context.toUri(r'C:\'), Uri.parse('file:///C:/'));
    expect(context.toUri(r'\\server\share'), Uri.parse('file://server/share'));
    expect(
        context.toUri(r'\\server\share\'), Uri.parse('file://server/share/'));
    expect(context.toUri(r'foo\bar'), Uri.parse('foo/bar'));
    expect(context.toUri(r'C:\path\to\foo#bar'),
        Uri.parse('file:///C:/path/to/foo%23bar'));
    expect(context.toUri(r'\\server\share\path\to\foo#bar'),
        Uri.parse('file://server/share/path/to/foo%23bar'));
    expect(context.toUri(r'C:\_{_}_`_^_ _"_%_'),
        Uri.parse('file:///C:/_%7B_%7D_%60_%5E_%20_%22_%25_'));
    expect(context.toUri(r'_{_}_`_^_ _"_%_'),
        Uri.parse('_%7B_%7D_%60_%5E_%20_%22_%25_'));
    expect(context.toUri(''), Uri.parse(''));
  });

  group('prettyUri', () {
    test('with a file: URI', () {
      expect(context.prettyUri('file:///C:/root/path/a/b'), r'a\b');
      expect(context.prettyUri('file:///C:/root/path/a/../b'), r'b');
      expect(
          context.prettyUri('file:///C:/other/path/a/b'), r'C:\other\path\a\b');
      expect(
          context.prettyUri('file:///D:/root/path/a/b'), r'D:\root\path\a\b');
      expect(context.prettyUri('file:///C:/root/other'), r'..\other');
    });

    test('with an http: URI', () {
      expect(context.prettyUri('https://dart.dev/a/b'), 'https://dart.dev/a/b');
    });

    test('with a relative URI', () {
      expect(context.prettyUri('a/b'), r'a\b');
    });

    test('with a root-relative URI', () {
      expect(context.prettyUri('/D:/a/b'), r'D:\a\b');
    });

    test('with a Uri object', () {
      expect(context.prettyUri(Uri.parse('a/b')), r'a\b');
    });
  });
}
