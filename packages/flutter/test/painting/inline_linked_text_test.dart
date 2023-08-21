// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    testWidgets('converts the valid url $text to a link by default', (WidgetTester tester) async {
      final InlineLinkedText inlineLinkedText = InlineLinkedText(
        onTap: (String text) {},
        style: const TextStyle(),
        text: text,
      );

      expect(inlineLinkedText.children, hasLength(1));
      expect(inlineLinkedText.children!.first, isA<TextSpan>());

      final TextSpan span = inlineLinkedText.children!.first as TextSpan;

      expect(span.text, text);
      expect(span.style, InlineLink.defaultLinkStyle);
    });
  }

  for (final String text in <String>[
    'abcd://subdomain.example.net',
    'ftp://subdomain.example.net',
  ]) {
    testWidgets('does nothing to the invalid url $text', (WidgetTester tester) async {
      final InlineLinkedText inlineLinkedText = InlineLinkedText(
        onTap: (String text) {},
        style: const TextStyle(),
        text: text,
      );

      expect(inlineLinkedText.children, hasLength(1));
      expect(inlineLinkedText.children!.first, isA<TextSpan>());

      final TextSpan span = inlineLinkedText.children!.first as TextSpan;

      expect(span.text, text);
      expect(span.style, null);
    });
  }

  for (final String text in <String>[
    '"example.com"',
    "'example.com'",
    '(example.com)',
  ]) {
    testWidgets('can parse url $text with leading and trailing characters', (WidgetTester tester) async {
      final InlineLinkedText inlineLinkedText = InlineLinkedText(
        onTap: (String text) {},
        style: const TextStyle(),
        text: text,
      );

      expect(inlineLinkedText.children, hasLength(3));

      expect(inlineLinkedText.children!.first, isA<TextSpan>());
      final TextSpan leadingSpan = inlineLinkedText.children!.first as TextSpan;
      expect(leadingSpan.text, hasLength(1));
      expect(leadingSpan.style, null);

      expect(inlineLinkedText.children![1], isA<TextSpan>());
      final TextSpan bodySpan = inlineLinkedText.children![1] as TextSpan;
      expect(bodySpan.text, 'example.com');
      expect(bodySpan.style, InlineLink.defaultLinkStyle);

      expect(inlineLinkedText.children!.last, isA<TextSpan>());
      final TextSpan trailingSpan = inlineLinkedText.children!.last as TextSpan;
      expect(trailingSpan.text, hasLength(1));
      expect(trailingSpan.style, null);
    });
  }

  // TODO(justinmc): Test custom regex, test multiple TextLinkers.
}
