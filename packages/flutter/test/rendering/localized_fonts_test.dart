// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TODO(hansmuller): when https://github.com/flutter/flutter/issues/17700
// is fixed, these tests should be updated to use a real font (not Ahem).

void main() {
  testWidgets(
    'RichText TextSpan styles with different locales',
    (WidgetTester tester) async {

      await tester.pumpWidget(
        new MaterialApp(
          supportedLocales: const <Locale>[
            Locale('en', 'US'),
            Locale('ja'),
            Locale('zh'),
          ],
          home: new Builder(
            builder: (BuildContext context) {
              const String character = '骨';
              final TextStyle style = Theme.of(context).textTheme.display3;
              return new Scaffold(
                body: new Container(
                  padding: const EdgeInsets.all(48.0),
                  alignment: Alignment.center,
                  child: new RepaintBoundary(
                    // Expected result can be seen here:
                    // https://user-images.githubusercontent.com/1377460/40503473-faad6f34-5f42-11e8-972b-d83b727c9d0e.png
                    child: new RichText(
                      text: new TextSpan(
                        children: <TextSpan>[
                          new TextSpan(text: character, style: style.copyWith(locale: const Locale('ja'))),
                          new TextSpan(text: character, style: style.copyWith(locale: const Locale('zh'))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      );

      await expectLater(
        find.byType(RichText),
        matchesGoldenFile('localized_fonts.rich_text.styled_text_span.png'),
      );
    },
    skip: !Platform.isLinux,
  );

  testWidgets(
    'Text with locale-specific glyphs, ambient locale',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        new MaterialApp(
          supportedLocales: const <Locale>[
            Locale('en', 'US'),
            Locale('ja'),
            Locale('zh'),
          ],
          home: new Builder(
            builder: (BuildContext context) {
              const String character = '骨';
              final TextStyle style = Theme.of(context).textTheme.display3;
              return new Scaffold(
                body: new Container(
                  padding: const EdgeInsets.all(48.0),
                  alignment: Alignment.center,
                  child: new RepaintBoundary(
                    // Expected result can be seen here:
                    // https://user-images.githubusercontent.com/1377460/40503473-faad6f34-5f42-11e8-972b-d83b727c9d0e.png
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        new Localizations.override(
                          context: context,
                          locale: const Locale('ja'),
                          child: new Text(character, style: style),
                        ),
                        new Localizations.override(
                          context: context,
                          locale: const Locale('zh'),
                          child: new Text(character, style: style),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        )
      );

      await expectLater(
        find.byType(Row),
        matchesGoldenFile('localized_fonts.text_ambient_locale.chars.png'),
      );
    },
    skip: !Platform.isLinux,
  );

  testWidgets(
    'Text with locale-specific glyphs, explicit locale',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        new MaterialApp(
          supportedLocales: const <Locale>[
            Locale('en', 'US'),
            Locale('ja'),
            Locale('zh'),
          ],
          home: new Builder(
            builder: (BuildContext context) {
              const String character = '骨';
              final TextStyle style = Theme.of(context).textTheme.display3;
              return new Scaffold(
                body: new Container(
                  padding: const EdgeInsets.all(48.0),
                  alignment: Alignment.center,
                  child: new RepaintBoundary(
                    // Expected result can be seen here:
                    // https://user-images.githubusercontent.com/1377460/40503473-faad6f34-5f42-11e8-972b-d83b727c9d0e.png
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        new Text(character, style: style, locale: const Locale('ja')),
	                new Text(character, style: style, locale: const Locale('zh')),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        )
      );

      await expectLater(
        find.byType(Row),
        matchesGoldenFile('localized_fonts.text_explicit_locale.chars.png'),
      );
    },
    skip: !Platform.isLinux,
  );

}
