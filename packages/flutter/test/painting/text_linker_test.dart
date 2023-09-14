// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final RegExp hashTagRegExp = RegExp(r'#[a-zA-Z0-9]*');
  final RegExp urlRegExp = RegExp(r'(?<!@[a-zA-Z0-9-]*)(?<![\/\.a-zA-Z0-9-])((https?:\/\/)?(([a-zA-Z0-9-]*\.)*[a-zA-Z0-9-]+(\.[a-zA-Z]+)+))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?(?![a-zA-Z0-9-]*@)');

  group('TextLinker.linkSpans', () {
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
          final Iterable<InlineSpan> linkedSpans = TextLinker.linkSpans(
             <InlineSpan>[
               TextSpan(
                 text: text,
               ),
             ],
            <TextLinker>[
              TextLinker(
                regExp: LinkedText.defaultUriRegExp,
                linkBuilder: (String displayString, String linkString) {
                  return TextSpan(
                    style: LinkedText.defaultLinkStyle,
                    text: displayString,
                  );
                },
              ),
            ],
          );

          expect(linkedSpans, hasLength(1));
          expect(linkedSpans.first, isA<TextSpan>());

          final TextSpan wrapperSpan = linkedSpans.first as TextSpan;
          expect(wrapperSpan.text, isNull);
          expect(wrapperSpan.children, hasLength(1));

          final TextSpan span = wrapperSpan.children!.first as TextSpan;

          expect(span.text, text);
          expect(span.style, LinkedText.defaultLinkStyle);
          expect(span.children, isNull);
        });
      }

      for (final String text in <String>[
        'abcd://subdomain.example.net',
        'ftp://subdomain.example.net',
      ]) {
        test('does nothing to the invalid url $text', () {
          final Iterable<InlineSpan> linkedSpans = TextLinker.linkSpans(
             <InlineSpan>[
               TextSpan(
                 text: text,
               ),
             ],
            <TextLinker>[
              TextLinker(
                regExp: LinkedText.defaultUriRegExp,
                linkBuilder: (String displayString, String linkString) {
                  return TextSpan(
                    text: displayString,
                  );
                },
              ),
            ],
          );

          expect(linkedSpans, hasLength(1));
          expect(linkedSpans.first, isA<TextSpan>());

          final TextSpan wrapperSpan = linkedSpans.first as TextSpan;
          expect(wrapperSpan.text, isNull);
          expect(wrapperSpan.children, hasLength(1));

          final TextSpan span = wrapperSpan.children!.first as TextSpan;

          expect(span.text, text);
          expect(span.style, isNull);
          expect(span.children, isNull);
        });
      }

      for (final String text in <String>[
        '"example.com"',
        "'example.com'",
        '(example.com)',
      ]) {
        test('can parse url $text with leading and trailing characters', () {
          final Iterable<InlineSpan> linkedSpans = TextLinker.linkSpans(
             <InlineSpan>[
               TextSpan(
                 text: text,
               ),
             ],
            <TextLinker>[
              TextLinker(
                regExp: LinkedText.defaultUriRegExp,
                linkBuilder: (String displayString, String linkString) {
                  return TextSpan(
                    style: LinkedText.defaultLinkStyle,
                    text: displayString,
                  );
                },
              ),
            ],
          );

          expect(linkedSpans, hasLength(1));
          expect(linkedSpans.first, isA<TextSpan>());

          final TextSpan wrapperSpan = linkedSpans.first as TextSpan;
          expect(wrapperSpan.text, isNull);
          expect(wrapperSpan.children, hasLength(3));

          expect(wrapperSpan.children!.first, isA<TextSpan>());
          final TextSpan leadingSpan = wrapperSpan.children!.first as TextSpan;
          expect(leadingSpan.text, hasLength(1));
          expect(leadingSpan.style, isNull);
          expect(leadingSpan.children, isNull);

          expect(wrapperSpan.children![1], isA<TextSpan>());
          final TextSpan bodySpan = wrapperSpan.children![1] as TextSpan;
          expect(bodySpan.text, 'example.com');
          expect(bodySpan.style, LinkedText.defaultLinkStyle);
          expect(bodySpan.children, isNull);

          expect(wrapperSpan.children!.last, isA<TextSpan>());
          final TextSpan trailingSpan = wrapperSpan.children!.last as TextSpan;
          expect(trailingSpan.text, hasLength(1));
          expect(trailingSpan.style, isNull);
          expect(trailingSpan.children, isNull);
        });
      }
    });

    test('multiple TextLinkers', () {
      final TextLinker urlTextLinker = TextLinker(
        regExp: urlRegExp,
        linkBuilder: (String displayString, String linkString) {
          return TextSpan(
            style: LinkedText.defaultLinkStyle,
            text: displayString,
          );
        },
      );
      final TextLinker hashTagTextLinker = TextLinker(
        regExp: hashTagRegExp,
        linkBuilder: (String displayString, String linkString) {
          return TextSpan(
            style: LinkedText.defaultLinkStyle,
            text: displayString,
          );
        },
      );
      final Iterable<InlineSpan> linkedSpans = TextLinker.linkSpans(
         <InlineSpan>[
           const TextSpan(
             text: 'Flutter is great #crossplatform #declarative check out flutter.dev.',
           ),
         ],
         <TextLinker>[urlTextLinker, hashTagTextLinker],
      );

      expect(linkedSpans, hasLength(1));
      expect(linkedSpans.first, isA<TextSpan>());

      final TextSpan wrapperSpan = linkedSpans.first as TextSpan;
      expect(wrapperSpan.text, isNull);
      expect(wrapperSpan.children, hasLength(7));

      expect(wrapperSpan.children!.first, isA<TextSpan>());
      final TextSpan textSpan1 = wrapperSpan.children!.first as TextSpan;
      expect(textSpan1.text, 'Flutter is great ');
      expect(textSpan1.style, isNull);
      expect(textSpan1.children, isNull);

      expect(wrapperSpan.children![1], isA<TextSpan>());
      final TextSpan hashTagSpan1 = wrapperSpan.children![1] as TextSpan;
      expect(hashTagSpan1.text, '#crossplatform');
      expect(hashTagSpan1.style, LinkedText.defaultLinkStyle);
      expect(hashTagSpan1.children, isNull);

      expect(wrapperSpan.children![2], isA<TextSpan>());
      final TextSpan textSpan2 = wrapperSpan.children![2] as TextSpan;
      expect(textSpan2.text, ' ');
      expect(textSpan2.style, isNull);
      expect(textSpan2.children, isNull);

      expect(wrapperSpan.children![3], isA<TextSpan>());
      final TextSpan hashTagSpan2 = wrapperSpan.children![3] as TextSpan;
      expect(hashTagSpan2.text, '#declarative');
      expect(hashTagSpan2.style, LinkedText.defaultLinkStyle);
      expect(hashTagSpan2.children, isNull);

      expect(wrapperSpan.children![4], isA<TextSpan>());
      final TextSpan textSpan3 = wrapperSpan.children![4] as TextSpan;
      expect(textSpan3.text, ' check out ');
      expect(textSpan3.style, isNull);
      expect(textSpan3.children, isNull);

      expect(wrapperSpan.children![5], isA<TextSpan>());
      final TextSpan urlSpan = wrapperSpan.children![5] as TextSpan;
      expect(urlSpan.text, 'flutter.dev');
      expect(urlSpan.style, LinkedText.defaultLinkStyle);
      expect(urlSpan.children, isNull);

      expect(wrapperSpan.children![6], isA<TextSpan>());
      final TextSpan textSpan4 = wrapperSpan.children![6] as TextSpan;
      expect(textSpan4.text, '.');
      expect(textSpan4.style, isNull);
      expect(textSpan4.children, isNull);
    });

    test('complex span tree', () {
      final Iterable<InlineSpan> linkedSpans = TextLinker.linkSpans(
        const <InlineSpan>[
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
        <TextLinker>[
          TextLinker(
            regExp: LinkedText.defaultUriRegExp,
            linkBuilder: (String displayString, String linkString) {
              return TextSpan(
                style: LinkedText.defaultLinkStyle,
                text: displayString,
              );
            },
          ),
        ],
      );

      expect(linkedSpans, hasLength(2));

      expect(linkedSpans.first, isA<TextSpan>());
      final TextSpan span1 = linkedSpans.first as TextSpan;
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
      expect(span1Child2.style, LinkedText.defaultLinkStyle);
      expect(span1Child2.children, isNull);

      expect(span1.children![2], isA<TextSpan>());
      final TextSpan span1Child3 = span1.children![2] as TextSpan;
      expect(span1Child3.text, null);
      expect(span1Child3.style, const TextStyle(fontWeight: FontWeight.w800));
      expect(span1Child3.children, hasLength(1));

      expect(span1Child3.children![0], isA<TextSpan>());
      final TextSpan span1Child3Child1 = span1Child3.children![0] as TextSpan;
      expect(span1Child3Child1.text, 'flutter');
      expect(span1Child3Child1.style, LinkedText.defaultLinkStyle);
      expect(span1Child3Child1.children, isNull);

      // Second span's children ('.dev!').
      expect(linkedSpans.elementAt(1), isA<TextSpan>());
      final TextSpan span2 = linkedSpans.elementAt(1) as TextSpan;
      expect(span2.text, isNull);
      expect(span2.children, hasLength(2));
      expect(span2.style, isNull);

      expect(span2.children![0], isA<TextSpan>());
      final TextSpan span2Child1 = span2.children![0] as TextSpan;
      expect(span2Child1.text, '.dev');
      expect(span2Child1.style, LinkedText.defaultLinkStyle);
      expect(span2Child1.children, isNull);

      expect(span2.children![1], isA<TextSpan>());
      final TextSpan span2Child2 = span2.children![1] as TextSpan;
      expect(span2Child2.text, '!');
      expect(span2Child2.children, isNull);
    });
  });
}
