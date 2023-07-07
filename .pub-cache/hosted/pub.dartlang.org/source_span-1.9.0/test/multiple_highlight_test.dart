// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';
import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:test/test.dart';

void main() {
  late bool oldAscii;
  setUpAll(() {
    oldAscii = glyph.ascii;
    glyph.ascii = true;
  });

  tearDownAll(() {
    glyph.ascii = oldAscii;
  });

  late SourceFile file;
  setUp(() {
    file = SourceFile.fromString('''
foo bar baz
whiz bang boom
zip zap zop
fwee fwoo fwip
argle bargle boo
gibble bibble bop
''', url: 'file1.txt');
  });

  test('highlights spans on separate lines', () {
    expect(
        file.span(17, 21).highlightMultiple(
            'one', {file.span(31, 34): 'two', file.span(4, 7): 'three'}),
        equals("""
  ,
1 | foo bar baz
  |     === three
2 | whiz bang boom
  |      ^^^^ one
3 | zip zap zop
  |     === two
  '"""));
  });

  test('highlights spans on the same line', () {
    expect(
        file.span(17, 21).highlightMultiple(
            'one', {file.span(22, 26): 'two', file.span(12, 16): 'three'}),
        equals("""
  ,
2 | whiz bang boom
  |      ^^^^ one
  | ==== three
  |           ==== two
  '"""));
  });

  test('highlights overlapping spans on the same line', () {
    expect(
        file.span(17, 21).highlightMultiple(
            'one', {file.span(20, 26): 'two', file.span(12, 18): 'three'}),
        equals("""
  ,
2 | whiz bang boom
  |      ^^^^ one
  | ====== three
  |         ====== two
  '"""));
  });

  test('highlights multiple multiline spans', () {
    expect(
        file.span(27, 54).highlightMultiple(
            'one', {file.span(54, 89): 'two', file.span(0, 27): 'three'}),
        equals("""
  ,
1 | / foo bar baz
2 | | whiz bang boom
  | '--- three
3 | / zip zap zop
4 | | fwee fwoo fwip
  | '--- one
5 | / argle bargle boo
6 | | gibble bibble bop
  | '--- two
  '"""));
  });

  test('highlights multiple overlapping multiline spans', () {
    expect(
        file.span(12, 70).highlightMultiple(
            'one', {file.span(54, 89): 'two', file.span(0, 27): 'three'}),
        equals("""
  ,
1 | /- foo bar baz
2 | |/ whiz bang boom
  | '+--- three
3 |  | zip zap zop
4 |  | fwee fwoo fwip
5 | /+ argle bargle boo
  | |'--- one
6 | |  gibble bibble bop
  | '---- two
  '"""));
  });

  test('highlights many layers of overlaps', () {
    expect(
        file.span(0, 54).highlightMultiple('one', {
          file.span(12, 77): 'two',
          file.span(27, 84): 'three',
          file.span(39, 88): 'four'
        }),
        equals("""
  ,
1 | /--- foo bar baz
2 | |/-- whiz bang boom
3 | ||/- zip zap zop
4 | |||/ fwee fwoo fwip
  | '+++--- one
5 |  ||| argle bargle boo
6 |  ||| gibble bibble bop
  |  '++------^ two
  |   '+-------------^ three
  |    '--- four
  '"""));
  });

  group("highlights a multiline span that's a subset", () {
    test('with no first or last line overlap', () {
      expect(
          file
              .span(27, 53)
              .highlightMultiple('inner', {file.span(12, 70): 'outer'}),
          equals("""
  ,
2 | /- whiz bang boom
3 | |/ zip zap zop
4 | || fwee fwoo fwip
  | |'--- inner
5 | |  argle bargle boo
  | '---- outer
  '"""));
    });

    test('overlapping the whole first line', () {
      expect(
          file
              .span(12, 53)
              .highlightMultiple('inner', {file.span(12, 70): 'outer'}),
          equals("""
  ,
2 | // whiz bang boom
3 | || zip zap zop
4 | || fwee fwoo fwip
  | |'--- inner
5 | |  argle bargle boo
  | '---- outer
  '"""));
    });

    test('overlapping part of first line', () {
      expect(
          file
              .span(17, 53)
              .highlightMultiple('inner', {file.span(12, 70): 'outer'}),
          equals("""
  ,
2 | /- whiz bang boom
  | |,------^
3 | || zip zap zop
4 | || fwee fwoo fwip
  | |'--- inner
5 | |  argle bargle boo
  | '---- outer
  '"""));
    });

    test('overlapping the whole last line', () {
      expect(
          file
              .span(27, 70)
              .highlightMultiple('inner', {file.span(12, 70): 'outer'}),
          equals("""
  ,
2 | /- whiz bang boom
3 | |/ zip zap zop
4 | || fwee fwoo fwip
5 | || argle bargle boo
  | |'--- inner
  | '---- outer
  '"""));
    });

    test('overlapping part of the last line', () {
      expect(
          file
              .span(27, 66)
              .highlightMultiple('inner', {file.span(12, 70): 'outer'}),
          equals("""
  ,
2 | /- whiz bang boom
3 | |/ zip zap zop
4 | || fwee fwoo fwip
5 | || argle bargle boo
  | |'------------^ inner
  | '---- outer
  '"""));
    });
  });

  group('a single-line span in a multiline span', () {
    test('on the first line', () {
      expect(
          file
              .span(17, 21)
              .highlightMultiple('inner', {file.span(12, 70): 'outer'}),
          equals("""
  ,
2 | / whiz bang boom
  | |      ^^^^ inner
3 | | zip zap zop
4 | | fwee fwoo fwip
5 | | argle bargle boo
  | '--- outer
  '"""));
    });

    test('in the middle', () {
      expect(
          file
              .span(31, 34)
              .highlightMultiple('inner', {file.span(12, 70): 'outer'}),
          equals("""
  ,
2 | / whiz bang boom
3 | | zip zap zop
  | |     ^^^ inner
4 | | fwee fwoo fwip
5 | | argle bargle boo
  | '--- outer
  '"""));
    });

    test('on the last line', () {
      expect(
          file
              .span(60, 66)
              .highlightMultiple('inner', {file.span(12, 70): 'outer'}),
          equals("""
  ,
2 | / whiz bang boom
3 | | zip zap zop
4 | | fwee fwoo fwip
5 | | argle bargle boo
  | |       ^^^^^^ inner
  | '--- outer
  '"""));
    });
  });

  group('writes headers when highlighting multiple files', () {
    test('writes all file URLs', () {
      final span2 = SourceFile.fromString('''
quibble bibble boop
''', url: 'file2.txt').span(8, 14);

      expect(
          file.span(31, 34).highlightMultiple('one', {span2: 'two'}), equals("""
  ,--> file1.txt
3 | zip zap zop
  |     ^^^ one
  '
  ,--> file2.txt
1 | quibble bibble boop
  |         ====== two
  '"""));
    });

    test('allows secondary spans to have null URL', () {
      final span2 = SourceSpan(SourceLocation(1, sourceUrl: null),
          SourceLocation(4, sourceUrl: null), 'foo');

      expect(
          file.span(31, 34).highlightMultiple('one', {span2: 'two'}), equals("""
  ,--> file1.txt
3 | zip zap zop
  |     ^^^ one
  '
  ,
1 | foo
  | === two
  '"""));
    });

    test('allows primary span to have null URL', () {
      final span1 = SourceSpan(SourceLocation(1, sourceUrl: null),
          SourceLocation(4, sourceUrl: null), 'foo');

      expect(
          span1.highlightMultiple('one', {file.span(31, 34): 'two'}), equals("""
  ,
1 | foo
  | ^^^ one
  '
  ,--> file1.txt
3 | zip zap zop
  |     === two
  '"""));
    });
  });

  test('highlights multiple null URLs as separate files', () {
    final span1 = SourceSpan(SourceLocation(1, sourceUrl: null),
        SourceLocation(4, sourceUrl: null), 'foo');
    final span2 = SourceSpan(SourceLocation(1, sourceUrl: null),
        SourceLocation(4, sourceUrl: null), 'bar');

    expect(span1.highlightMultiple('one', {span2: 'two'}), equals("""
  ,
1 | foo
  | ^^^ one
  '
  ,
1 | bar
  | === two
  '"""));
  });
}
