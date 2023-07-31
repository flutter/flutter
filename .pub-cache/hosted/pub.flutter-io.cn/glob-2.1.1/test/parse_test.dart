// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('supports backslash-escaped characters', () {
    expect(r'*[]{,}?()', contains(Glob(r'\*\[\]\{\,\}\?\(\)')));
    if (p.style != p.Style.windows) {
      expect(r'foo\bar', contains(Glob(r'foo\\bar')));
    }
  });

  test('disallows an empty glob', () {
    expect(() => Glob(''), throwsFormatException);
  });

  group('range', () {
    test('supports either ^ or ! for negated ranges', () {
      var bang = Glob('fo[!a-z]');
      expect('foo', isNot(contains(bang)));
      expect('fo2', contains(bang));

      var caret = Glob('fo[^a-z]');
      expect('foo', isNot(contains(caret)));
      expect('fo2', contains(caret));
    });

    test('supports backslash-escaped characters', () {
      var glob = Glob(r'fo[\*\--\]]');
      expect('fo]', contains(glob));
      expect('fo-', contains(glob));
      expect('fo*', contains(glob));
    });

    test('disallows inverted ranges', () {
      expect(() => Glob(r'[z-a]'), throwsFormatException);
    });

    test('disallows empty ranges', () {
      expect(() => Glob(r'[]'), throwsFormatException);
    });

    test('disallows unclosed ranges', () {
      expect(() => Glob(r'[abc'), throwsFormatException);
      expect(() => Glob(r'[-'), throwsFormatException);
    });

    test('disallows dangling ]', () {
      expect(() => Glob(r'abc]'), throwsFormatException);
    });

    test('disallows explicit /', () {
      expect(() => Glob(r'[/]'), throwsFormatException);
      expect(() => Glob(r'[ -/]'), throwsFormatException);
      expect(() => Glob(r'[/-~]'), throwsFormatException);
    });
  });

  group('options', () {
    test('allows empty branches', () {
      var glob = Glob('foo{,bar}');
      expect('foo', contains(glob));
      expect('foobar', contains(glob));
    });

    test('disallows empty options', () {
      expect(() => Glob('{}'), throwsFormatException);
    });

    test('disallows single options', () {
      expect(() => Glob('{foo}'), throwsFormatException);
    });

    test('disallows unclosed options', () {
      expect(() => Glob('{foo,bar'), throwsFormatException);
      expect(() => Glob('{foo,'), throwsFormatException);
    });

    test('disallows dangling }', () {
      expect(() => Glob('foo}'), throwsFormatException);
    });

    test('disallows dangling ] in options', () {
      expect(() => Glob(r'{abc]}'), throwsFormatException);
    });
  });

  test('disallows unescaped parens', () {
    expect(() => Glob('foo(bar'), throwsFormatException);
    expect(() => Glob('foo)bar'), throwsFormatException);
  });
}
