// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests for https://github.com/flutter/flutter/issues/194931: when the user's
// preferred locale is not supported by the app, text widgets should not pass
// the app's fallback locale to the engine, so that the operating system's
// default locale is used for font fallback.

const Locale enUS = Locale('en', 'US');
const Locale zhCN = Locale('zh', 'CN');
const Locale jaJP = Locale('ja', 'JP');

void main() {
  void setDeviceLocales(WidgetTester tester, List<Locale> locales) {
    tester.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  Widget buildApp({
    Locale? locale,
    Iterable<Locale> supportedLocales = const <Locale>[enUS],
    required Widget child,
  }) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: supportedLocales,
      builder: (BuildContext context, Widget? _) => Center(child: child),
    );
  }

  Locale? paragraphLocale(WidgetTester tester) {
    return tester.renderObject<RenderParagraph>(find.byType(RichText)).locale;
  }

  testWidgets('RichText uses no locale when the preferred locale is unsupported', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(buildApp(child: const Text('你好')));

    expect(Localizations.localeOf(tester.element(find.byType(RichText))), enUS);
    expect(paragraphLocale(tester), isNull);
  });

  testWidgets('RichText uses no locale when only a lower preference is supported', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN, enUS]);
    await tester.pumpWidget(buildApp(child: const Text('你好')));

    expect(Localizations.localeOf(tester.element(find.byType(RichText))), enUS);
    expect(paragraphLocale(tester), isNull);
  });

  // Only the user's first preferred locale is considered. When the app matches
  // a lower preference instead, the app locale is still treated as a fallback.
  //
  // This is a deliberate trade-off. Here the app's own strings are Chinese, but
  // text will render with the operating system's default locale (likely
  // Japanese for this user), so Han characters in the app's strings may use
  // Japanese glyph variants. Considering secondary preferences would avoid that,
  // but it would also bring back the original bug for the more common case of
  // a user with `[zh_CN, en_US]` using an English-only app: the app resolves to
  // `en_US`, a secondary preference, and Han characters would again render with
  // Japanese fonts. Apps can opt out with an explicit `WidgetsApp.locale` or
  // `TextStyle.locale`.
  testWidgets('RichText uses no locale when only a lower preference matches a CJK app locale', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[jaJP, zhCN]);
    await tester.pumpWidget(
      buildApp(supportedLocales: const <Locale>[enUS, zhCN], child: const Text('你好')),
    );

    expect(Localizations.localeOf(tester.element(find.byType(RichText))), zhCN);
    expect(paragraphLocale(tester), isNull);
  });

  testWidgets('RichText uses the app locale when the preferred locale is supported', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      buildApp(supportedLocales: const <Locale>[enUS, zhCN], child: const Text('你好')),
    );

    expect(paragraphLocale(tester), zhCN);
  });

  testWidgets('RichText uses a supported explicit WidgetsApp.locale', (WidgetTester tester) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      buildApp(locale: jaJP, supportedLocales: const <Locale>[enUS, jaJP], child: const Text('你好')),
    );

    expect(paragraphLocale(tester), jaJP);
  });

  testWidgets('RichText uses no locale for an unsupported explicit WidgetsApp.locale', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[enUS]);
    await tester.pumpWidget(buildApp(locale: jaJP, child: const Text('你好')));

    expect(Localizations.localeOf(tester.element(find.byType(RichText))), enUS);
    expect(paragraphLocale(tester), isNull);
  });

  testWidgets('Explicit locales are respected when the preferred locale is unsupported', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      buildApp(
        child: Column(
          children: <Widget>[
            const Text('a', locale: jaJP),
            Builder(
              builder: (BuildContext context) {
                return Localizations.override(
                  context: context,
                  locale: jaJP,
                  child: const Text('b'),
                );
              },
            ),
          ],
        ),
      ),
    );

    final List<RenderParagraph> paragraphs = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .toList();
    expect(paragraphs.map((RenderParagraph p) => p.locale), <Locale>[jaJP, jaJP]);
  });

  testWidgets('RichText updates when the device locales change', (WidgetTester tester) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(buildApp(child: const Text('你好')));
    expect(paragraphLocale(tester), isNull);

    tester.platformDispatcher.localesTestValue = const <Locale>[enUS];
    await tester.pump();
    expect(paragraphLocale(tester), enUS);

    tester.platformDispatcher.localesTestValue = const <Locale>[jaJP, enUS];
    await tester.pump();
    expect(paragraphLocale(tester), isNull);
  });

  testWidgets('RichText updates when supportedLocales change', (WidgetTester tester) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(buildApp(child: const Text('你好')));
    expect(paragraphLocale(tester), isNull);

    await tester.pumpWidget(
      buildApp(supportedLocales: const <Locale>[enUS, zhCN], child: const Text('你好')),
    );
    expect(paragraphLocale(tester), zhCN);
  });

  testWidgets('EditableText uses no locale when the preferred locale is unsupported', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    final controller = TextEditingController(text: '你好');
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    RenderEditable renderEditable() => tester.allRenderObjects.whereType<RenderEditable>().single;

    Widget buildEditable(Iterable<Locale> supportedLocales) {
      return buildApp(
        supportedLocales: supportedLocales,
        child: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(),
          cursorColor: const Color(0xFF000000),
          backgroundCursorColor: const Color(0xFF000000),
        ),
      );
    }

    await tester.pumpWidget(buildEditable(const <Locale>[enUS]));
    expect(renderEditable().locale, isNull);

    await tester.pumpWidget(buildEditable(const <Locale>[enUS, zhCN]));
    expect(renderEditable().locale, zhCN);
  });

  testWidgets('Localizations without WidgetsApp is unaffected', (WidgetTester tester) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      Localizations(
        locale: enUS,
        delegates: const <LocalizationsDelegate<dynamic>>[DefaultWidgetsLocalizations.delegate],
        child: const Text('你好'),
      ),
    );

    expect(paragraphLocale(tester), enUS);
  });
}
