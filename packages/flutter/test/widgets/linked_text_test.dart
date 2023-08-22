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

  testWidgets('can customize linkBuilder', (WidgetTester tester) async {
    String? lastTappedLink;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return LinkedText(
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

  testWidgets('can pass ranges directly', (WidgetTester tester) async {
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
                ranges: const <TextRange>[
                  TextRange(start: 0, end: 5), // 'Check'
                  TextRange(start: 10, end: 17), // 'flutter'
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

    await tester.tapAt(tester.getTopLeft(find.byType(RichText)));
    expect(lastTappedLink, 'Check');

    await tester.tapAt(tester.getCenter(find.byType(RichText)));
    expect(lastTappedLink, 'flutter');
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
      rangesFinder: TextLinker.rangesFinderFromRegExp(urlRegExp),
      linkBuilder: InlineLinkedText.getDefaultLinkBuilder((String text) {
        lastTappedLink = text;
      }),
    );
    final TextLinker hashTagTextLinker = TextLinker(
      rangesFinder: TextLinker.rangesFinderFromRegExp(hashTagRegExp),
      linkBuilder: InlineLinkedText.getDefaultLinkBuilder((String text) {
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
