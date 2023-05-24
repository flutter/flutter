// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('can parse urls out of a nested tree', (WidgetTester tester) async {
    String? lastTappedLink;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return LinkedText.spans(
                onTap: (String text) {
                  lastTappedLink = text;
                },
                children: <InlineSpan>[
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
