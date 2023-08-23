// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final RegExp hashTagRegExp = RegExp(r'#[a-zA-Z0-9]*');
  final RegExp urlRegExp = RegExp(r'(?<!@[a-zA-Z0-9-]*)(?<![\/\.a-zA-Z0-9-])((https?:\/\/)?(([a-zA-Z0-9-]*\.)*[a-zA-Z0-9-]+(\.[a-zA-Z]+)+))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?(?![a-zA-Z0-9-]*@)');

  group('url matching', () {
    for (final String text in <String>[
      'https://www.example.com',
      'www.example123.co.uk',
      'subdomain.example.net',
      'ftp.subdomain.example.net',
      'http://subdomain.example.net',
      'https://subdomain.example.net',
      'http://example.com/',
      'https://www.example.org/',
      'ftp.subdomain.example.net',
      'example.com',
      'subdomain.example.io',
      'www.example123.co.uk',
      'http://example.com:8080/',
      'https://www.example.com/path/to/resource',
      'http://www.example.com/index.php?query=test#fragment',
      'https://subdomain.example.io:8443/resource/file.html?search=query#result',
      'example.com',
      'subsub.www.example.com',
      'https://subsub.www.example.com'
    ]) {
      test('converts the valid url $text to a link by default', () {
        final InlineLinkedText inlineLinkedText = InlineLinkedText(
          onTap: (String text) {},
          text: text,
        );

        expect(inlineLinkedText.children, hasLength(1));
        expect(inlineLinkedText.children!.first, isA<TextSpan>());

        final TextSpan span = inlineLinkedText.children!.first as TextSpan;

        expect(span.text, text);
        expect(span.style, InlineLink.defaultLinkStyle);
        expect(span.children, isNull);

        expect(inlineLinkedText.recognizers, hasLength(1));
        for (final GestureRecognizer recognizer in inlineLinkedText.recognizers) {
          recognizer.dispose();
        }
      });
    }

    for (final String text in <String>[
      'abcd://subdomain.example.net',
      'ftp://subdomain.example.net',
    ]) {
      test('does nothing to the invalid url $text', () {
        final InlineLinkedText inlineLinkedText = InlineLinkedText(
          onTap: (String text) {},
          text: text,
        );

        expect(inlineLinkedText.children, hasLength(1));
        expect(inlineLinkedText.children!.first, isA<TextSpan>());

        final TextSpan span = inlineLinkedText.children!.first as TextSpan;

        expect(span.text, text);
        expect(span.style, isNull);
        expect(span.children, isNull);

        expect(inlineLinkedText.recognizers, hasLength(0));
      });
    }

    for (final String text in <String>[
      '"example.com"',
      "'example.com'",
      '(example.com)',
    ]) {
      test('can parse url $text with leading and trailing characters', () {
        final InlineLinkedText inlineLinkedText = InlineLinkedText(
          onTap: (String text) {},
          text: text,
        );

        expect(inlineLinkedText.children, hasLength(3));

        expect(inlineLinkedText.children!.first, isA<TextSpan>());
        final TextSpan leadingSpan = inlineLinkedText.children!.first as TextSpan;
        expect(leadingSpan.text, hasLength(1));
        expect(leadingSpan.style, isNull);
        expect(leadingSpan.children, isNull);

        expect(inlineLinkedText.children![1], isA<TextSpan>());
        final TextSpan bodySpan = inlineLinkedText.children![1] as TextSpan;
        expect(bodySpan.text, 'example.com');
        expect(bodySpan.style, InlineLink.defaultLinkStyle);
        expect(bodySpan.children, isNull);

        expect(inlineLinkedText.children!.last, isA<TextSpan>());
        final TextSpan trailingSpan = inlineLinkedText.children!.last as TextSpan;
        expect(trailingSpan.text, hasLength(1));
        expect(trailingSpan.style, isNull);
        expect(trailingSpan.children, isNull);

        expect(inlineLinkedText.recognizers, hasLength(1));
        for (final GestureRecognizer recognizer in inlineLinkedText.recognizers) {
          recognizer.dispose();
        }
      });
    }
  });

  test('can pass ranges directly', () {
    final InlineLinkedText inlineLinkedText = InlineLinkedText(
      onTap: (String text) {},
      ranges: const <TextRange>[
        TextRange(start: 1, end: 3),
        TextRange(start: 4, end: 6),
      ],
      text: 'abcdefghijklmnopqrstuvwxyz',
    );

    expect(inlineLinkedText.children, hasLength(5));

    expect(inlineLinkedText.children![0], isA<TextSpan>());
    final TextSpan textSpan1 = inlineLinkedText.children![0] as TextSpan;
    expect(textSpan1.text, 'a');
    expect(textSpan1.style, isNull);
    expect(textSpan1.children, isNull);

    expect(inlineLinkedText.children![1], isA<TextSpan>());
    final TextSpan linkSpan1 = inlineLinkedText.children![1] as TextSpan;
    expect(linkSpan1.text, 'bc');
    expect(linkSpan1.style, InlineLink.defaultLinkStyle);
    expect(linkSpan1.children, isNull);

    expect(inlineLinkedText.children![2], isA<TextSpan>());
    final TextSpan textSpan2 = inlineLinkedText.children![2] as TextSpan;
    expect(textSpan2.text, 'd');
    expect(textSpan2.style, null);
    expect(textSpan2.children, isNull);

    expect(inlineLinkedText.children![3], isA<TextSpan>());
    final TextSpan linkSpan2 = inlineLinkedText.children![3] as TextSpan;
    expect(linkSpan2.text, 'ef');
    expect(linkSpan2.style, InlineLink.defaultLinkStyle);
    expect(linkSpan2.children, isNull);

    expect(inlineLinkedText.children![4], isA<TextSpan>());
    final TextSpan textSpan3 = inlineLinkedText.children![4] as TextSpan;
    expect(textSpan3.text, 'ghijklmnopqrstuvwxyz');
    expect(textSpan3.style, null);
    expect(textSpan3.children, isNull);

    expect(inlineLinkedText.recognizers, hasLength(2)); // 'bc', 'ef'
    for (final GestureRecognizer recognizer in inlineLinkedText.recognizers) {
      recognizer.dispose();
    }
  });

  test('can use a custom regexp', () {
    final InlineLinkedText inlineLinkedText = InlineLinkedText.regExp(
      onTap: (String text) {},
      regExp: hashTagRegExp,
      text: 'Flutter is great #crossplatform #declarative',
    );

    expect(inlineLinkedText.children, hasLength(4));

    expect(inlineLinkedText.children!.first, isA<TextSpan>());
    final TextSpan leadingSpan = inlineLinkedText.children!.first as TextSpan;
    expect(leadingSpan.text, 'Flutter is great ');
    expect(leadingSpan.style, isNull);
    expect(leadingSpan.children, isNull);

    expect(inlineLinkedText.children![1], isA<TextSpan>());
    final TextSpan hashTagSpan1 = inlineLinkedText.children![1] as TextSpan;
    expect(hashTagSpan1.text, '#crossplatform');
    expect(hashTagSpan1.style, InlineLink.defaultLinkStyle);
    expect(hashTagSpan1.children, isNull);

    expect(inlineLinkedText.children![2], isA<TextSpan>());
    final TextSpan spaceSpan = inlineLinkedText.children![2] as TextSpan;
    expect(spaceSpan.text, ' ');
    expect(spaceSpan.style, isNull);
    expect(spaceSpan.children, isNull);

    expect(inlineLinkedText.children!.last, isA<TextSpan>());
    final TextSpan hashTagSpan2 = inlineLinkedText.children!.last as TextSpan;
    expect(hashTagSpan2.text, '#declarative');
    expect(hashTagSpan2.style, InlineLink.defaultLinkStyle);
    expect(hashTagSpan2.children, isNull);

    expect(inlineLinkedText.recognizers, hasLength(2));
    for (final GestureRecognizer recognizer in inlineLinkedText.recognizers) {
      recognizer.dispose();
    }
  });

  test('can use custom TextLinkers', () {
    final TextLinker urlTextLinker = TextLinker(
      rangesFinder: TextLinker.rangesFinderFromRegExp(urlRegExp),
      linkBuilder: InlineLinkedText.getDefaultLinkBuilder((String text) {}),
    );
    final TextLinker hashTagTextLinker = TextLinker(
      rangesFinder: TextLinker.rangesFinderFromRegExp(hashTagRegExp),
      linkBuilder: InlineLinkedText.getDefaultLinkBuilder((String text) {}),
    );
    final InlineLinkedText inlineLinkedText = InlineLinkedText.textLinkers(
      textLinkers: <TextLinker>[urlTextLinker, hashTagTextLinker],
      text: 'Flutter is great #crossplatform #declarative check out flutter.dev.',
    );

    expect(inlineLinkedText.children, hasLength(7));

    expect(inlineLinkedText.children!.first, isA<TextSpan>());
    final TextSpan textSpan1 = inlineLinkedText.children!.first as TextSpan;
    expect(textSpan1.text, 'Flutter is great ');
    expect(textSpan1.style, isNull);
    expect(textSpan1.children, isNull);

    expect(inlineLinkedText.children![1], isA<TextSpan>());
    final TextSpan hashTagSpan1 = inlineLinkedText.children![1] as TextSpan;
    expect(hashTagSpan1.text, '#crossplatform');
    expect(hashTagSpan1.style, InlineLink.defaultLinkStyle);
    expect(hashTagSpan1.children, isNull);

    expect(inlineLinkedText.children![2], isA<TextSpan>());
    final TextSpan textSpan2 = inlineLinkedText.children![2] as TextSpan;
    expect(textSpan2.text, ' ');
    expect(textSpan2.style, isNull);
    expect(textSpan2.children, isNull);

    expect(inlineLinkedText.children![3], isA<TextSpan>());
    final TextSpan hashTagSpan2 = inlineLinkedText.children![3] as TextSpan;
    expect(hashTagSpan2.text, '#declarative');
    expect(hashTagSpan2.style, InlineLink.defaultLinkStyle);
    expect(hashTagSpan2.children, isNull);

    expect(inlineLinkedText.children![4], isA<TextSpan>());
    final TextSpan textSpan3 = inlineLinkedText.children![4] as TextSpan;
    expect(textSpan3.text, ' check out ');
    expect(textSpan3.style, isNull);
    expect(textSpan3.children, isNull);

    expect(inlineLinkedText.children![5], isA<TextSpan>());
    final TextSpan urlSpan = inlineLinkedText.children![5] as TextSpan;
    expect(urlSpan.text, 'flutter.dev');
    expect(urlSpan.style, InlineLink.defaultLinkStyle);
    expect(urlSpan.children, isNull);

    expect(inlineLinkedText.children![6], isA<TextSpan>());
    final TextSpan textSpan4 = inlineLinkedText.children![6] as TextSpan;
    expect(textSpan4.text, '.');
    expect(textSpan4.style, isNull);
    expect(textSpan4.children, isNull);

    expect(inlineLinkedText.recognizers, hasLength(3)); // Two hash tags, one url.
    for (final GestureRecognizer recognizer in inlineLinkedText.recognizers) {
      recognizer.dispose();
    }
  });

  test('can pass TextSpans instead of a string', () {
    final InlineLinkedText inlineLinkedText = InlineLinkedText(
      onTap: (String text) {},
      spans: const <InlineSpan>[
        TextSpan(
          text: 'Check out https://www.',
          children: <InlineSpan>[
            TextSpan(
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
              text: 'flutter',
            ),
          ],
        ),
        TextSpan(
          text: '.dev!',
        ),
      ],
    );

    expect(inlineLinkedText.children, hasLength(2));
    expect(inlineLinkedText.children!.first, isA<TextSpan>());
    final TextSpan span1 = inlineLinkedText.children!.first as TextSpan;
    expect(span1.text, isNull);
    expect(span1.style, isNull);
    expect(span1.children, hasLength(3));

    // First span's children ('Check out https://www.flutter').
    expect(span1.children![0], isA<TextSpan>());
    final TextSpan span1Child1 = span1.children![0] as TextSpan;
    expect(span1Child1.text, 'Check out ');
    expect(span1Child1.style, isNull);
    expect(span1Child1.children, isNull);

    expect(span1.children![1], isA<TextSpan>());
    final TextSpan span1Child2 = span1.children![1] as TextSpan;
    expect(span1Child2.text, 'https://www.');
    expect(span1Child2.style, InlineLink.defaultLinkStyle);
    expect(span1Child2.children, isNull);

    expect(span1.children![2], isA<TextSpan>());
    final TextSpan span1Child3 = span1.children![2] as TextSpan;
    expect(span1Child3.text, null);
    expect(span1Child3.style, const TextStyle(fontWeight: FontWeight.w800));
    expect(span1Child3.children, hasLength(1));

    expect(span1Child3.children![0], isA<TextSpan>());
    final TextSpan span1Child3Child1 = span1Child3.children![0] as TextSpan;
    expect(span1Child3Child1.text, 'flutter');
    expect(span1Child3Child1.style, InlineLink.defaultLinkStyle);
    expect(span1Child3Child1.children, isNull);

    // Second span's children ('.dev!').
    expect(inlineLinkedText.children![1], isA<TextSpan>());
    final TextSpan span2 = inlineLinkedText.children![1] as TextSpan;
    expect(span2.text, isNull);
    expect(span2.children, hasLength(2));
    expect(span2.style, isNull);

    expect(span2.children![0], isA<TextSpan>());
    final TextSpan span2Child1 = span2.children![0] as TextSpan;
    expect(span2Child1.text, '.dev');
    expect(span2Child1.style, InlineLink.defaultLinkStyle);
    expect(span2Child1.children, isNull);

    expect(span2.children![1], isA<TextSpan>());
    final TextSpan span2Child2 = span2.children![1] as TextSpan;
    expect(span2Child2.text, '!');
    expect(span2Child2.children, isNull);

    expect(inlineLinkedText.recognizers, hasLength(3)); // 'https://www.', 'flutter', '.dev'
    for (final GestureRecognizer recognizer in inlineLinkedText.recognizers) {
      recognizer.dispose();
    }
  });
}
