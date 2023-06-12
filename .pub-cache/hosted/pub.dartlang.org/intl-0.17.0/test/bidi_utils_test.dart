// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library bidi_utils_test;

import 'package:intl/intl.dart';
import 'package:test/test.dart';

// ignore_for_file: non_constant_identifier_names

/// Tests the bidi utilities library.
void main() {
  var LRE = '\u202A';
  var RLE = '\u202B';
  var PDF = '\u202C';

  test('isRtlLang', () {
    expect(Bidi.isRtlLanguage('en'), isFalse);
    expect(Bidi.isRtlLanguage('fr'), isFalse);
    expect(Bidi.isRtlLanguage('zh-CN'), isFalse);
    expect(Bidi.isRtlLanguage('fil'), isFalse);
    expect(Bidi.isRtlLanguage('az'), isFalse);
    expect(Bidi.isRtlLanguage('iw-Latn'), isFalse);
    expect(Bidi.isRtlLanguage('iw-LATN'), isFalse);
    expect(Bidi.isRtlLanguage('iw_latn'), isFalse);
    expect(Bidi.isRtlLanguage('ar'), isTrue);
    expect(Bidi.isRtlLanguage('AR'), isTrue);
    expect(Bidi.isRtlLanguage('iw'), isTrue);
    expect(Bidi.isRtlLanguage('he'), isTrue);
    expect(Bidi.isRtlLanguage('fa'), isTrue);
    expect(Bidi.isRtlLanguage('ar-EG'), isTrue);
    expect(Bidi.isRtlLanguage('az-Arab'), isTrue);
    expect(Bidi.isRtlLanguage('az-ARAB-IR'), isTrue);
    expect(Bidi.isRtlLanguage('az_arab_IR'), isTrue);
    Intl.withLocale('en_US', () {
      expect(Bidi.isRtlLanguage(), isFalse);
    });
    Intl.withLocale('ar', () {
      expect(Bidi.isRtlLanguage(), isTrue);
    });
    Intl.withLocale(null, () {
      expect(Bidi.isRtlLanguage(), Bidi.isRtlLanguage(Intl.systemLocale));
    });
  });

  test('hasAnyLtr', () {
    expect(Bidi.hasAnyLtr(''), isFalse);
    expect(Bidi.hasAnyLtr('\u05e0\u05e1\u05e2'), isFalse);
    expect(Bidi.hasAnyLtr('\u05e0\u05e1z\u05e2'), isTrue);
    expect(Bidi.hasAnyLtr('123\t...  \n'), isFalse);
    expect(Bidi.hasAnyLtr('<br>123&lt;', false), isTrue);
    expect(Bidi.hasAnyLtr('<br>123&lt;', true), isFalse);
  });

  test('hasAnyRtl', () {
    expect(Bidi.hasAnyRtl(''), isFalse);
    expect(Bidi.hasAnyRtl('abc'), isFalse);
    expect(Bidi.hasAnyRtl('ab\u05e0c'), isTrue);
    expect(Bidi.hasAnyRtl('123\t...  \n'), isFalse);
    expect(Bidi.hasAnyRtl('<input value=\u05e0>123', false), isTrue);
    expect(Bidi.hasAnyRtl('<input value=\u05e0>123', true), isFalse);
  });

  test('endsWithLtr', () {
    expect(Bidi.endsWithLtr('a'), isTrue);
    expect(Bidi.endsWithLtr('abc'), isTrue);
    expect(Bidi.endsWithLtr('a (!)'), isTrue);
    expect(Bidi.endsWithLtr('a.1'), isTrue);
    expect(Bidi.endsWithLtr('http://www.google.com '), isTrue);
    expect(Bidi.endsWithLtr('\u05e0a'), isTrue);
    expect(Bidi.endsWithLtr(' \u05e0\u05e1a\u05e2\u05e3 a (!)'), isTrue);
    expect(Bidi.endsWithLtr(''), isFalse);
    expect(Bidi.endsWithLtr(' '), isFalse);
    expect(Bidi.endsWithLtr('1'), isFalse);
    expect(Bidi.endsWithLtr('\u05e0'), isFalse);
    expect(Bidi.endsWithLtr('\u05e0 1(!)'), isFalse);
    expect(Bidi.endsWithLtr('a\u05e0'), isFalse);
    expect(Bidi.endsWithLtr('a abc\u05e0\u05e1def\u05e2. 1'), isFalse);
    expect(Bidi.endsWithLtr(' \u05e0\u05e1a\u05e2 &lt;', true), isFalse);
    expect(Bidi.endsWithLtr(' \u05e0\u05e1a\u05e2 &lt;', false), isTrue);
  });

  test('endsWithRtl', () {
    expect(Bidi.endsWithRtl('\u05e0'), isTrue);
    expect(Bidi.endsWithRtl('\u05e0\u05e1\u05e2'), isTrue);
    expect(Bidi.endsWithRtl('\u05e0 (!)'), isTrue);
    expect(Bidi.endsWithRtl('\u05e0.1'), isTrue);
    expect(Bidi.endsWithRtl('http://www.google.com/\u05e0 '), isTrue);
    expect(Bidi.endsWithRtl('a\u05e0'), isTrue);
    expect(Bidi.endsWithRtl(' a abc\u05e0def\u05e3. 1'), isTrue);
    expect(Bidi.endsWithRtl(''), isFalse);
    expect(Bidi.endsWithRtl(' '), isFalse);
    expect(Bidi.endsWithRtl('1'), isFalse);
    expect(Bidi.endsWithRtl('a'), isFalse);
    expect(Bidi.endsWithRtl('a 1(!)'), isFalse);
    expect(Bidi.endsWithRtl('\u05e0a'), isFalse);
    expect(Bidi.endsWithRtl('\u05e0 \u05e0\u05e1ab\u05e2 a (!)'), isFalse);
    expect(Bidi.endsWithRtl(' \u05e0\u05e1a\u05e2 &lt;', true), isTrue);
    expect(Bidi.endsWithRtl(' \u05e0\u05e1a\u05e2 &lt;', false), isFalse);
  });

  test('guardBracketInHtml', () {
    var strWithRtl = 'asc \u05d0 (\u05d0\u05d0\u05d0)';
    expect(Bidi.guardBracketInHtml(strWithRtl),
        equals('asc \u05d0 <span dir=rtl>(\u05d0\u05d0\u05d0)</span>'));
    expect(Bidi.guardBracketInHtml(strWithRtl, true),
        equals('asc \u05d0 <span dir=rtl>(\u05d0\u05d0\u05d0)</span>'));
    expect(Bidi.guardBracketInHtml(strWithRtl, false),
        equals('asc \u05d0 <span dir=ltr>(\u05d0\u05d0\u05d0)</span>'));

    var strWithRtl2 = '\u05d0 a (asc:))';
    expect(Bidi.guardBracketInHtml(strWithRtl2),
        equals('\u05d0 a <span dir=rtl>(asc:))</span>'));
    expect(Bidi.guardBracketInHtml(strWithRtl2, true),
        equals('\u05d0 a <span dir=rtl>(asc:))</span>'));
    expect(Bidi.guardBracketInHtml(strWithRtl2, false),
        equals('\u05d0 a <span dir=ltr>(asc:))</span>'));

    var strWithoutRtl = 'a (asc) {{123}}';
    expect(Bidi.guardBracketInHtml(strWithoutRtl),
        equals('a <span dir=ltr>(asc)</span> <span dir=ltr>{{123}}</span>'));
    expect(Bidi.guardBracketInHtml(strWithoutRtl, true),
        equals('a <span dir=rtl>(asc)</span> <span dir=rtl>{{123}}</span>'));
    expect(Bidi.guardBracketInHtml(strWithoutRtl, false),
        equals('a <span dir=ltr>(asc)</span> <span dir=ltr>{{123}}</span>'));
  });

  test('guardBracketInText', () {
    var strWithRtl = 'asc \u05d0 (\u05d0\u05d0\u05d0)';
    expect(Bidi.guardBracketInText(strWithRtl),
        equals('asc \u05d0 \u200f(\u05d0\u05d0\u05d0)\u200f'));
    expect(Bidi.guardBracketInText(strWithRtl, true),
        equals('asc \u05d0 \u200f(\u05d0\u05d0\u05d0)\u200f'));
    expect(Bidi.guardBracketInText(strWithRtl, false),
        equals('asc \u05d0 \u200e(\u05d0\u05d0\u05d0)\u200e'));

    var strWithRtl2 = '\u05d0 a (asc:))';
    expect(Bidi.guardBracketInText(strWithRtl2),
        equals('\u05d0 a \u200f(asc:))\u200f'));
    expect(Bidi.guardBracketInText(strWithRtl2, true),
        equals('\u05d0 a \u200f(asc:))\u200f'));
    expect(Bidi.guardBracketInText(strWithRtl2, false),
        equals('\u05d0 a \u200e(asc:))\u200e'));

    var strWithoutRtl = 'a (asc) {{123}}';
    expect(Bidi.guardBracketInText(strWithoutRtl),
        equals('a \u200e(asc)\u200e \u200e{{123}}\u200e'));
    expect(Bidi.guardBracketInText(strWithoutRtl, true),
        equals('a \u200f(asc)\u200f \u200f{{123}}\u200f'));
    expect(Bidi.guardBracketInText(strWithoutRtl, false),
        equals('a \u200e(asc)\u200e \u200e{{123}}\u200e'));
  });

  test('enforceRtlInHtml', () {
    var str = '<div> first <br> second </div>';
    expect(Bidi.enforceRtlInHtml(str),
        equals('<div dir=rtl> first <br> second </div>'));
    str = 'first second';
    expect(Bidi.enforceRtlInHtml(str),
        equals('\n<span dir=rtl>first second</span>'));
  });

  test('enforceRtlInText', () {
    var str = 'first second';
    expect(Bidi.enforceRtlInText(str), equals('${RLE}first second$PDF'));
  });

  test('enforceLtrInHtml', () {
    var str = '<div> first <br> second </div>';
    expect(Bidi.enforceLtrInHtml(str),
        equals('<div dir=ltr> first <br> second </div>'));
    str = 'first second';
    expect(Bidi.enforceLtrInHtml(str),
        equals('\n<span dir=ltr>first second</span>'));
  });

  test('enforceLtrInText', () {
    var str = 'first second';
    expect(Bidi.enforceLtrInText(str), equals('${LRE}first second$PDF'));
  });

  test('normalizeHebrewQuote', () {
    expect(Bidi.normalizeHebrewQuote('\u05d0"'), equals('\u05d0\u05f4'));
    expect(Bidi.normalizeHebrewQuote('\u05d0\''), equals('\u05d0\u05f3'));
    expect(Bidi.normalizeHebrewQuote('\u05d0"\u05d0\''),
        equals('\u05d0\u05f4\u05d0\u05f3'));
  });

  test('estimateDirectionOfText', () {
    expect(Bidi.estimateDirectionOfText('', isHtml: false).value,
        equals(TextDirection.UNKNOWN.value));
    expect(Bidi.estimateDirectionOfText(' ', isHtml: false).value,
        equals(TextDirection.UNKNOWN.value));
    expect(Bidi.estimateDirectionOfText('! (...)', isHtml: false).value,
        equals(TextDirection.UNKNOWN.value));
    expect(
        Bidi.estimateDirectionOfText('All-Ascii content', isHtml: false).value,
        equals(TextDirection.LTR.value));
    expect(Bidi.estimateDirectionOfText('-17.0%', isHtml: false).value,
        equals(TextDirection.LTR.value));
    expect(Bidi.estimateDirectionOfText('http://foo/bar/', isHtml: false).value,
        equals(TextDirection.LTR.value));
    expect(
        Bidi.estimateDirectionOfText(
                'http://foo/bar/?s=\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0'
                '\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0'
                '\u05d0\u05d0\u05d0\u05d0\u05d0')
            .value,
        equals(TextDirection.LTR.value));
    expect(Bidi.estimateDirectionOfText('\u05d0', isHtml: false).value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText('9 \u05d0 -> 17.5, 23, 45, 19',
                isHtml: false)
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                'http://foo/bar/ \u05d0 http://foo2/bar2/ http://foo3/bar3/')
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                '\u05d0\u05d9\u05df \u05de\u05de\u05e9 \u05de\u05d4 \u05dc\u05e8\u05d0'
                '\u05d5\u05ea: \u05dc\u05d0 \u05e6\u05d9\u05dc\u05de\u05ea\u05d9 \u05d4'
                '\u05e8\u05d1\u05d4 \u05d5\u05d2\u05dd \u05d0\u05dd \u05d4\u05d9\u05d9'
                '\u05ea\u05d9 \u05de\u05e6\u05dc\u05dd, \u05d4\u05d9\u05d4 \u05e9'
                '\u05dd')
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                '\u05db\u05d0 - http://geek.co.il/gallery/v/2007-06 - \u05d0\u05d9'
                '\u05df \u05de\u05de\u05e9 \u05de\u05d4 \u05dc\u05e8\u05d0\u05d5\u05ea:'
                ' \u05dc\u05d0 \u05e6\u05d9\u05dc\u05de\u05ea\u05d9 \u05d4\u05e8\u05d1 '
                '\u05d5\u05d2\u05dd \u05d0\u05dd \u05d4\u05d9\u05d9\u05d9 \u05de\u05e6'
                '\u05dc\u05dd, \u05d4\u05d9\u05d4 \u05e9\u05dd \u05d1\u05e2\u05d9\u05e7'
                ' \u05d4\u05e8\u05d1\u05d4 \u05d0\u05e0\u05e9\u05d9\u05dd. \u05de\u05d4'
                ' \u05e9\u05db\u05df - \u05d0\u05e4\u05e9\u05e8 \u05dc\u05e0\u05e6'
                '\u05dc \u05d0\u05ea \u05d4\u05d4 \u05d3\u05d6\u05de\u05e0\u05d5 '
                '\u05dc\u05d4\u05e1\u05ea\u05db\u05dc \u05e2\u05dc \u05db\u05de\u05d4 '
                '\u05ea\u05de\u05d5\u05e0\u05d5\u05ea \u05de\u05e9\u05e9\u05e2\u05d5'
                '\u05ea \u05d9\u05e9\u05e0\u05d5 \u05d9\u05d5\u05ea\u05e8 \u05e9\u05d9'
                '\u05e9 \u05dc\u05d9 \u05d1\u05d0\u05ea\u05e8',
                isHtml: false)
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                'CAPTCHA \u05de\u05e9\u05d5\u05db\u05dc\u05dc '
                '\u05de\u05d3\u05d9?')
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                'Yes Prime Minister \u05e2\u05d3\u05db\u05d5\u05df. \u05e9\u05d0\u05dc'
                '\u05d5 \u05d0\u05d5\u05ea\u05d9 \u05de\u05d4 \u05d0\u05e0\u05d9 '
                '\u05e8\u05d5\u05e6\u05d4 \u05de\u05ea\u05e0\u05d4 \u05dc\u05d7'
                '\u05d2')
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                '17.4.02 \u05e9\u05e2\u05d4:13-20 .15-00 .\u05dc\u05d0 \u05d4\u05d9'
                '\u05d9\u05ea\u05d9 \u05db\u05d0\u05df.')
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                '5710 5720 5730. \u05d4\u05d3\u05dc\u05ea. \u05d4\u05e0\u05e9\u05d9'
                '\u05e7\u05d4',
                isHtml: false)
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                '\u05d4\u05d3\u05dc\u05ea http://www.google.com '
                'http://www.gmail.com')
            .value,
        equals(TextDirection.RTL.value));
    expect(
        Bidi.estimateDirectionOfText(
                '\u05d4\u05d3\u05dc <some quite nasty html mark up>')
            .value,
        equals(TextDirection.LTR.value));
    expect(
        Bidi.estimateDirectionOfText(
                '\u05d4\u05d3\u05dc <some quite nasty html mark up>')
            .value,
        equals(TextDirection.LTR.value));
    expect(
        Bidi.estimateDirectionOfText('\u05d4\u05d3\u05dc\u05ea &amp; &lt; &gt;')
            .value,
        equals(TextDirection.LTR.value));
    expect(
        Bidi.estimateDirectionOfText('\u05d4\u05d3\u05dc\u05ea &amp; &lt; &gt;',
                isHtml: true)
            .value,
        equals(TextDirection.RTL.value));
  });

  test('detectRtlDirectionality', () {
    var bidiText = [];
    var item = SampleItem('Pure Ascii content');
    bidiText.add(item);

    item = SampleItem(
        '\u05d0\u05d9\u05df \u05de\u05de\u05e9 \u05de\u05d4'
        ' \u05dc\u05e8\u05d0\u05d5\u05ea: \u05dc\u05d0 \u05e6\u05d9\u05dc'
        '\u05de\u05ea\u05d9 \u05d4\u05e8\u05d1\u05d4 \u05d5\u05d2\u05dd '
        '\u05d0\u05dd \u05d4\u05d9\u05d9\u05ea\u05d9 \u05de\u05e6\u05dc\u05dd, '
        '\u05d4\u05d9\u05d4 \u05e9\u05dd',
        true);
    bidiText.add(item);

    item = SampleItem(
        '\u05db\u05d0\u05df - http://geek.co.il/gallery/v/'
        '2007-06 - \u05d0\u05d9\u05df \u05de\u05de\u05e9 \u05de\u05d4 \u05dc'
        '\u05e8\u05d0\u05d5\u05ea: \u05dc\u05d0 \u05e6\u05d9\u05dc\u05de\u05ea'
        '\u05d9 \u05d4\u05e8\u05d1\u05d4 \u05d5\u05d2\u05dd \u05d0\u05dd \u05d4'
        '\u05d9\u05d9\u05ea\u05d9 \u05de\u05e6\u05dc\u05dd, \u05d4\u05d9\u05d4 '
        '\u05e9\u05dd \u05d1\u05e2\u05d9\u05e7\u05e8 \u05d4\u05e8\u05d1\u05d4 '
        '\u05d0\u05e0\u05e9\u05d9\u05dd. \u05de\u05d4 \u05e9\u05db\u05df - '
        '\u05d0\u05e4\u05e9\u05e8 \u05dc\u05e0\u05e6\u05dc \u05d0\u05ea \u05d4'
        '\u05d4\u05d3\u05d6\u05de\u05e0\u05d5\u05ea \u05dc\u05d4\u05e1\u05ea'
        '\u05db\u05dc \u05e2\u05dc \u05db\u05de\u05d4 \u05ea\u05de\u05d5\u05e0'
        '\u05d5\u05ea \u05de\u05e9\u05e2\u05e9\u05e2\u05d5\u05ea \u05d9\u05e9'
        '\u05e0\u05d5\u05ea \u05d9\u05d5\u05ea\u05e8 \u05e9\u05d9\u05e9 \u05dc'
        '\u05d9 \u05d1\u05d0\u05ea\u05e8',
        true);
    bidiText.add(item);

    item = SampleItem(
        'CAPTCHA \u05de\u05e9\u05d5\u05db\u05dc\u05dc '
        '\u05de\u05d3\u05d9?',
        true);
    bidiText.add(item);

    item = SampleItem(
        'Yes Prime Minister \u05e2\u05d3\u05db\u05d5\u05df. '
        '\u05e9\u05d0\u05dc\u05d5 \u05d0\u05d5\u05ea\u05d9 \u05de\u05d4 \u05d0'
        '\u05e0\u05d9 \u05e8\u05d5\u05e6\u05d4 \u05de\u05ea\u05e0\u05d4 '
        '\u05dc\u05d7\u05d2',
        true);
    bidiText.add(item);

    item = SampleItem(
        '17.4.02 \u05e9\u05e2\u05d4:13-20 .15-00 .\u05dc'
        '\u05d0 \u05d4\u05d9\u05d9\u05ea\u05d9 \u05db\u05d0\u05df.',
        true);
    bidiText.add(item);

    item = SampleItem(
        '5710 5720 5730. \u05d4\u05d3\u05dc\u05ea. \u05d4'
        '\u05e0\u05e9\u05d9\u05e7\u05d4',
        true);
    bidiText.add(item);

    item = SampleItem(
        '\u05d4\u05d3\u05dc\u05ea http://www.google.com '
        'http://www.gmail.com',
        true);
    bidiText.add(item);

    item = SampleItem('&gt;\u05d4&lt;', true, true);
    bidiText.add(item);

    item = SampleItem('&gt;\u05d4&lt;', false);
    bidiText.add(item);

    for (var i = 0; i < bidiText.length; i++) {
      var isRtlDir = Bidi.detectRtlDirectionality(bidiText[i].text,
          isHtml: bidiText[i].isHtml);

      if (isRtlDir != bidiText[i].isRtl) {
        var str = '"${bidiText[i].text} " should be '
            '${bidiText[i].isRtl ? "rtl" : "ltr"} but detected as '
            '${isRtlDir ? "rtl" : "ltr"}';
        fail(str);
      }
    }
  });
}

class SampleItem {
  String text;
  bool isRtl;
  bool isHtml;
  SampleItem([this.text = '', this.isRtl = false, this.isHtml = false]);
}
