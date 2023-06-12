// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:io/io.dart';
import 'package:test/test.dart';

void main() {
  group('shellSplit()', () {
    group('returns an empty list for', () {
      test('an empty string', () {
        expect(shellSplit(''), isEmpty);
      });

      test('spaces', () {
        expect(shellSplit('    '), isEmpty);
      });

      test('tabs', () {
        expect(shellSplit('\t\t\t'), isEmpty);
      });

      test('newlines', () {
        expect(shellSplit('\n\n\n'), isEmpty);
      });

      test('a comment', () {
        expect(shellSplit('#foo bar baz'), isEmpty);
      });

      test('a mix', () {
        expect(shellSplit(' \t\n# foo'), isEmpty);
      });
    });

    group('parses unquoted', () {
      test('a single token', () {
        expect(shellSplit('foo'), equals(['foo']));
      });

      test('multiple tokens', () {
        expect(shellSplit('foo bar baz'), equals(['foo', 'bar', 'baz']));
      });

      test('tokens separated by tabs', () {
        expect(shellSplit('foo\tbar\tbaz'), equals(['foo', 'bar', 'baz']));
      });

      test('tokens separated by newlines', () {
        expect(shellSplit('foo\nbar\nbaz'), equals(['foo', 'bar', 'baz']));
      });

      test('a token after whitespace', () {
        expect(shellSplit(' \t\nfoo'), equals(['foo']));
      });

      test('a token before whitespace', () {
        expect(shellSplit('foo \t\n'), equals(['foo']));
      });

      test('a token with a hash', () {
        expect(shellSplit('foo#bar'), equals(['foo#bar']));
      });

      test('a token before a comment', () {
        expect(shellSplit('foo #bar'), equals(['foo']));
      });

      test('dynamic shell features', () {
        expect(
            shellSplit(r'foo $(bar baz)'), equals(['foo', r'$(bar', 'baz)']));
        expect(shellSplit('foo `bar baz`'), equals(['foo', '`bar', 'baz`']));
        expect(shellSplit(r'foo $bar | baz'),
            equals(['foo', r'$bar', '|', 'baz']));
      });
    });

    group('parses a backslash', () {
      test('before a normal character', () {
        expect(shellSplit(r'foo\bar'), equals(['foobar']));
      });

      test('before a dynamic shell feature', () {
        expect(shellSplit(r'foo\$bar'), equals([r'foo$bar']));
      });

      test('before a single quote', () {
        expect(shellSplit(r"foo\'bar"), equals(["foo'bar"]));
      });

      test('before a double quote', () {
        expect(shellSplit(r'foo\"bar'), equals(['foo"bar']));
      });

      test('before a space', () {
        expect(shellSplit(r'foo\ bar'), equals(['foo bar']));
      });

      test('at the beginning of a token', () {
        expect(shellSplit(r'\ foo'), equals([' foo']));
      });

      test('before whitespace followed by a hash', () {
        expect(shellSplit(r'\ #foo'), equals([' #foo']));
      });

      test('before a newline in a token', () {
        expect(shellSplit('foo\\\nbar'), equals(['foobar']));
      });

      test('before a newline outside a token', () {
        expect(shellSplit('foo \\\n bar'), equals(['foo', 'bar']));
      });

      test('before a backslash', () {
        expect(shellSplit(r'foo\\bar'), equals([r'foo\bar']));
      });
    });

    group('parses single quotes', () {
      test('that are empty', () {
        expect(shellSplit("''"), equals(['']));
      });

      test('that contain normal characters', () {
        expect(shellSplit("'foo'"), equals(['foo']));
      });

      test('that contain active characters', () {
        expect(shellSplit("'\" \\#'"), equals([r'" \#']));
      });

      test('before a hash', () {
        expect(shellSplit("''#foo"), equals([r'#foo']));
      });

      test('inside a token', () {
        expect(shellSplit("foo'bar baz'qux"), equals([r'foobar bazqux']));
      });

      test('without a closing quote', () {
        expect(() => shellSplit("'foo bar"), throwsFormatException);
      });
    });

    group('parses double quotes', () {
      test('that are empty', () {
        expect(shellSplit('""'), equals(['']));
      });

      test('that contain normal characters', () {
        expect(shellSplit('"foo"'), equals(['foo']));
      });

      test('that contain otherwise-active characters', () {
        expect(shellSplit('"\' #"'), equals(["' #"]));
      });

      test('that contain escaped characters', () {
        expect(shellSplit(r'"\$\`\"\\"'), equals(['\$`"\\']));
      });

      test('that contain an escaped newline', () {
        expect(shellSplit('"\\\n"'), equals(['']));
      });

      test("that contain a backslash that's not an escape", () {
        expect(shellSplit(r'"f\oo"'), equals([r'f\oo']));
      });

      test('before a hash', () {
        expect(shellSplit('""#foo'), equals([r'#foo']));
      });

      test('inside a token', () {
        expect(shellSplit('foo"bar baz"qux'), equals([r'foobar bazqux']));
      });

      test('without a closing quote', () {
        expect(() => shellSplit('"foo bar'), throwsFormatException);
        expect(() => shellSplit('"foo bar\\'), throwsFormatException);
      });
    });
  });
}
