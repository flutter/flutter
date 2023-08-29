// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final RegExp hashTagRegExp = RegExp(r'#[a-zA-Z0-9]*');
  final RegExp urlRegExp = RegExp(r'(?<!@[a-zA-Z0-9-]*)(?<![\/\.a-zA-Z0-9-])((https?:\/\/)?(([a-zA-Z0-9-]*\.)*[a-zA-Z0-9-]+(\.[a-zA-Z]+)+))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?(?![a-zA-Z0-9-]*@)');

  group('LinkedText.linkSpans', () {
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
          final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
              LinkedText.linkSpans(
                 <InlineSpan>[
                   TextSpan(
                     text: text,
                   ),
                 ],
                <TextLinker>[
                  TextLinker(
                    textRangesFinder: LinkedText.defaultTextRangesFinder,
                    linkBuilder: LinkedText.getDefaultLinkBuilder((String text) {}),
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
          expect(span.style, InlineLinkSpan.defaultLinkStyle);
          expect(span.children, isNull);

          expect(recognizers, hasLength(1));
          for (final GestureRecognizer recognizer in recognizers) {
            recognizer.dispose();
          }
        });
      }

      for (final String text in <String>[
        'abcd://subdomain.example.net',
        'ftp://subdomain.example.net',
      ]) {
        test('does nothing to the invalid url $text', () {
          final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
              LinkedText.linkSpans(
                 <InlineSpan>[
                   TextSpan(
                     text: text,
                   ),
                 ],
                <TextLinker>[
                  TextLinker(
                    textRangesFinder: LinkedText.defaultTextRangesFinder,
                    linkBuilder: LinkedText.getDefaultLinkBuilder((String text) {}),
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

          expect(recognizers, hasLength(0));
        });
      }

      for (final String text in <String>[
        '"example.com"',
        "'example.com'",
        '(example.com)',
      ]) {
        test('can parse url $text with leading and trailing characters', () {
          final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
              LinkedText.linkSpans(
                 <InlineSpan>[
                   TextSpan(
                     text: text,
                   ),
                 ],
                <TextLinker>[
                  TextLinker(
                    textRangesFinder: LinkedText.defaultTextRangesFinder,
                    linkBuilder: LinkedText.getDefaultLinkBuilder((String text) {}),
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
          expect(bodySpan.style, InlineLinkSpan.defaultLinkStyle);
          expect(bodySpan.children, isNull);

          expect(wrapperSpan.children!.last, isA<TextSpan>());
          final TextSpan trailingSpan = wrapperSpan.children!.last as TextSpan;
          expect(trailingSpan.text, hasLength(1));
          expect(trailingSpan.style, isNull);
          expect(trailingSpan.children, isNull);

          expect(recognizers, hasLength(1));
          for (final GestureRecognizer recognizer in recognizers) {
            recognizer.dispose();
          }
        });
      }
    });

    test('multiple TextLinkers', () {
      final TextLinker urlTextLinker = TextLinker(
        textRangesFinder: TextLinker.textRangesFinderFromRegExp(urlRegExp),
        linkBuilder: LinkedText.getDefaultLinkBuilder((String text) {}),
      );
      final TextLinker hashTagTextLinker = TextLinker(
        textRangesFinder: TextLinker.textRangesFinderFromRegExp(hashTagRegExp),
        linkBuilder: LinkedText.getDefaultLinkBuilder((String text) {}),
      );
      final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
          LinkedText.linkSpans(
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
      expect(hashTagSpan1.style, InlineLinkSpan.defaultLinkStyle);
      expect(hashTagSpan1.children, isNull);

      expect(wrapperSpan.children![2], isA<TextSpan>());
      final TextSpan textSpan2 = wrapperSpan.children![2] as TextSpan;
      expect(textSpan2.text, ' ');
      expect(textSpan2.style, isNull);
      expect(textSpan2.children, isNull);

      expect(wrapperSpan.children![3], isA<TextSpan>());
      final TextSpan hashTagSpan2 = wrapperSpan.children![3] as TextSpan;
      expect(hashTagSpan2.text, '#declarative');
      expect(hashTagSpan2.style, InlineLinkSpan.defaultLinkStyle);
      expect(hashTagSpan2.children, isNull);

      expect(wrapperSpan.children![4], isA<TextSpan>());
      final TextSpan textSpan3 = wrapperSpan.children![4] as TextSpan;
      expect(textSpan3.text, ' check out ');
      expect(textSpan3.style, isNull);
      expect(textSpan3.children, isNull);

      expect(wrapperSpan.children![5], isA<TextSpan>());
      final TextSpan urlSpan = wrapperSpan.children![5] as TextSpan;
      expect(urlSpan.text, 'flutter.dev');
      expect(urlSpan.style, InlineLinkSpan.defaultLinkStyle);
      expect(urlSpan.children, isNull);

      expect(wrapperSpan.children![6], isA<TextSpan>());
      final TextSpan textSpan4 = wrapperSpan.children![6] as TextSpan;
      expect(textSpan4.text, '.');
      expect(textSpan4.style, isNull);
      expect(textSpan4.children, isNull);

      expect(recognizers, hasLength(3)); // Two hash tags, one url.
      for (final GestureRecognizer recognizer in recognizers) {
        recognizer.dispose();
      }
    });

    test('complex span tree', () {
      final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
          LinkedText.linkSpans(
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
                textRangesFinder: LinkedText.defaultTextRangesFinder,
                linkBuilder: LinkedText.getDefaultLinkBuilder((String text) {}),
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
      expect(span1Child2.style, InlineLinkSpan.defaultLinkStyle);
      expect(span1Child2.children, isNull);

      expect(span1.children![2], isA<TextSpan>());
      final TextSpan span1Child3 = span1.children![2] as TextSpan;
      expect(span1Child3.text, null);
      expect(span1Child3.style, const TextStyle(fontWeight: FontWeight.w800));
      expect(span1Child3.children, hasLength(1));

      expect(span1Child3.children![0], isA<TextSpan>());
      final TextSpan span1Child3Child1 = span1Child3.children![0] as TextSpan;
      expect(span1Child3Child1.text, 'flutter');
      expect(span1Child3Child1.style, InlineLinkSpan.defaultLinkStyle);
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
      expect(span2Child1.style, InlineLinkSpan.defaultLinkStyle);
      expect(span2Child1.children, isNull);

      expect(span2.children![1], isA<TextSpan>());
      final TextSpan span2Child2 = span2.children![1] as TextSpan;
      expect(span2Child2.text, '!');
      expect(span2Child2.children, isNull);

      expect(recognizers, hasLength(3)); // 'https://www.', 'flutter', '.dev'
      for (final GestureRecognizer recognizer in recognizers) {
        recognizer.dispose();
      }
    });
  });

  testWidgets('links urls by default', (WidgetTester tester) async {
    String? lastTappedLink;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return LinkedText(
                onTap: (String text) {
                  lastTappedLink = text;
                },
                text: 'Check out flutter.dev.',
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(RichText), findsOneWidget);
    expect(lastTappedLink, isNull);

    await tester.tapAt(tester.getCenter(find.byType(RichText)));

    expect(lastTappedLink, 'flutter.dev');
  });

  testWidgets('can pass custom regexp', (WidgetTester tester) async {
    String? lastTappedLink;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return LinkedText.regExp(
                onTap: (String text) {
                  lastTappedLink = text;
                },
                regExp: hashTagRegExp,
                text: 'Flutter is great #crossplatform #declarative',
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(RichText), findsOneWidget);
    expect(lastTappedLink, isNull);

    await tester.tapAt(tester.getCenter(find.byType(RichText)));
    expect(lastTappedLink, '#crossplatform');
  });

  testWidgets('can link multiple different types', (WidgetTester tester) async {
    String? lastTappedLink;
    final TextLinker urlTextLinker = TextLinker(
      textRangesFinder: TextLinker.textRangesFinderFromRegExp(urlRegExp),
      linkBuilder: LinkedText.getDefaultLinkBuilder((String text) {
        lastTappedLink = text;
      }),
    );
    final TextLinker hashTagTextLinker = TextLinker(
      textRangesFinder: TextLinker.textRangesFinderFromRegExp(hashTagRegExp),
      linkBuilder: LinkedText.getDefaultLinkBuilder((String text) {
        lastTappedLink = text;
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return LinkedText.textLinkers(
                textLinkers: <TextLinker>[urlTextLinker, hashTagTextLinker],
                text: 'flutter.dev is great #crossplatform #declarative',
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(RichText), findsOneWidget);
    expect(lastTappedLink, isNull);

    await tester.tapAt(tester.getTopLeft(find.byType(RichText)));
    expect(lastTappedLink, 'flutter.dev');

    await tester.tapAt(tester.getCenter(find.byType(RichText)));
    expect(lastTappedLink, '#crossplatform');
  });

  testWidgets('can customize linkBuilder', (WidgetTester tester) async {
    String? lastTappedLink;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return LinkedText.textLinkers(
                textLinkers: <TextLinker>[
                  TextLinker(
                    textRangesFinder: LinkedText.defaultTextRangesFinder,
                    linkBuilder: (String displayString, String linkString) {
                      final TapGestureRecognizer recognizer = TapGestureRecognizer()
                          ..onTap = () {
                            lastTappedLink = linkString;
                          };
                      return (
                        TextSpan(
                          recognizer: recognizer,
                          text: displayString,
                          mouseCursor: SystemMouseCursors.help,
                        ),
                        recognizer,
                      );
                    },
                  ),
                ],
                text: 'Check out flutter.dev.',
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(RichText), findsOneWidget);
    expect(lastTappedLink, isNull);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(Scaffold)));
    await tester.pump();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
    await gesture.moveTo(tester.getCenter(find.byType(RichText)));
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.help);

    await tester.tapAt(tester.getCenter(find.byType(RichText)));
    expect(lastTappedLink, 'flutter.dev');
  });

  testWidgets('can take nested spans', (WidgetTester tester) async {
    String? lastTappedLink;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return LinkedText(
                onTap: (String text) {
                  lastTappedLink = text;
                },
                spans: <InlineSpan>[
                  TextSpan(
                    text: 'Check out fl',
                    style: DefaultTextStyle.of(context).style,
                    children: const <InlineSpan>[
                      TextSpan(
                        text: 'u',
                        children: <InlineSpan>[
                          TextSpan(
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                            text: 'tt',
                          ),
                          TextSpan(
                            text: 'er',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const TextSpan(
                    text: '.dev.',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(RichText), findsOneWidget);
    expect(lastTappedLink, isNull);

    await tester.tapAt(tester.getCenter(find.byType(RichText)));

    expect(lastTappedLink, 'flutter.dev');
  });
}
