// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests for https://github.com/flutter/flutter/issues/194931: when the app
// does not configure its locales, its locale is always the default en_US. Text
// widgets should not pass that default to the engine, so that the platform's
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
    Iterable<Locale>? supportedLocales,
    LocaleResolutionCallback? localeResolutionCallback,
    required Widget child,
  }) {
    if (supportedLocales == null) {
      // Use WidgetsApp's default supportedLocales.
      return WidgetsApp(
        color: const Color(0xFF000000),
        locale: locale,
        localeResolutionCallback: localeResolutionCallback,
        builder: (BuildContext context, Widget? _) => Center(child: child),
      );
    }
    return WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      builder: (BuildContext context, Widget? _) => Center(child: child),
    );
  }

  Locale? paragraphLocale(WidgetTester tester) {
    return tester.renderObject<RenderParagraph>(find.byType(RichText)).locale;
  }

  bool isDefaultLocale(WidgetTester tester) {
    return Localizations.isDefaultLocaleOf(tester.element(find.byType(RichText)));
  }

  testWidgets('RichText uses no locale when the app uses the default locale', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(buildApp(child: const Text('你好')));

    expect(Localizations.localeOf(tester.element(find.byType(RichText))), enUS);
    expect(isDefaultLocale(tester), isTrue);
    expect(paragraphLocale(tester), isNull);
  });

  testWidgets('RichText uses no locale for the default locale regardless of device locale', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[enUS]);
    await tester.pumpWidget(buildApp(child: const Text('你好')));
    expect(paragraphLocale(tester), isNull);

    tester.platformDispatcher.localesTestValue = const <Locale>[zhCN];
    await tester.pump();
    expect(paragraphLocale(tester), isNull);
  });

  testWidgets('RichText uses the resolved locale when the app sets supportedLocales', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      // A non-const list, so it is not the default supportedLocales.
      // ignore: prefer_const_literals_to_create_immutables
      buildApp(supportedLocales: <Locale>[enUS], child: const Text('你好')),
    );

    // The app is rendered in en_US, so en_US is used for text.
    expect(Localizations.localeOf(tester.element(find.byType(RichText))), enUS);
    expect(isDefaultLocale(tester), isFalse);
    expect(paragraphLocale(tester), enUS);
  });

  // The default supportedLocales is detected by identity. A const list equal to
  // the default is canonicalized to the same object, so it is treated as the
  // default too.
  testWidgets('A const supportedLocales equal to the default is treated as the default', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      buildApp(supportedLocales: const <Locale>[enUS], child: const Text('你好')),
    );

    expect(isDefaultLocale(tester), isTrue);
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

  testWidgets('RichText uses the app locale when a secondary preferred locale is supported', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[jaJP, zhCN]);
    await tester.pumpWidget(
      buildApp(supportedLocales: const <Locale>[enUS, zhCN], child: const Text('你好')),
    );

    expect(paragraphLocale(tester), zhCN);
  });

  testWidgets('RichText uses the resolved locale when WidgetsApp.locale is set', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(buildApp(locale: enUS, child: const Text('你好')));

    expect(isDefaultLocale(tester), isFalse);
    expect(paragraphLocale(tester), enUS);
  });

  testWidgets('RichText uses the resolved locale when a localeResolutionCallback is set', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      buildApp(
        localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) => enUS,
        child: const Text('你好'),
      ),
    );

    expect(isDefaultLocale(tester), isFalse);
    expect(paragraphLocale(tester), enUS);
  });

  testWidgets('Explicit locales are respected when the app uses the default locale', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      buildApp(
        child: Column(
          children: <Widget>[
            const Text('a', locale: jaJP),
            const Text('b', style: TextStyle(locale: jaJP)),
            Builder(
              builder: (BuildContext context) {
                return Localizations.override(
                  context: context,
                  locale: jaJP,
                  child: const Text('c'),
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
    expect(paragraphs[0].locale, jaJP);
    expect(paragraphs[1].text.style?.locale, jaJP);
    expect(paragraphs[2].locale, jaJP);
  });

  testWidgets('Localizations.override without a locale inherits isDefaultLocale', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    await tester.pumpWidget(
      buildApp(
        child: Builder(
          builder: (BuildContext context) {
            return Localizations.override(
              context: context,
              delegates: const <LocalizationsDelegate<dynamic>>[
                DefaultWidgetsLocalizations.delegate,
              ],
              child: const Text('你好'),
            );
          },
        ),
      ),
    );

    expect(isDefaultLocale(tester), isTrue);
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

    await tester.pumpWidget(buildApp(child: const Text('你好')));
    expect(paragraphLocale(tester), isNull);
  });

  // Only isDefaultLocale changes here; the resolved locale stays en_US and the
  // localized resources aren't reloaded, so text must be updated by the
  // Localizations dependency notifying.
  testWidgets('RichText updates when only isDefaultLocale changes', (WidgetTester tester) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    // Reuse a single instance so that the Text is not rebuilt by its parent.
    // (Widget creation tracking makes const widgets from different call sites
    // distinct instances.)
    const Widget text = Text('你好');
    await tester.pumpWidget(buildApp(child: text));
    expect(Localizations.localeOf(tester.element(find.byType(RichText))), enUS);
    expect(paragraphLocale(tester), isNull);

    await tester.pumpWidget(
      // A non-const list, so it is not the default supportedLocales.
      // ignore: prefer_const_literals_to_create_immutables
      buildApp(supportedLocales: <Locale>[enUS], child: text),
    );
    expect(Localizations.localeOf(tester.element(find.byType(RichText))), enUS);
    expect(paragraphLocale(tester), enUS);

    await tester.pumpWidget(buildApp(child: text));
    expect(paragraphLocale(tester), isNull);
  });

  testWidgets('EditableText uses no locale when the app uses the default locale', (
    WidgetTester tester,
  ) async {
    setDeviceLocales(tester, const <Locale>[zhCN]);
    final controller = TextEditingController(text: '你好');
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    RenderEditable renderEditable() => tester.allRenderObjects.whereType<RenderEditable>().single;

    Widget buildEditable(Iterable<Locale>? supportedLocales) {
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

    await tester.pumpWidget(buildEditable(null));
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

    expect(isDefaultLocale(tester), isFalse);
    expect(paragraphLocale(tester), enUS);
  });

  testWidgets('Localizations.isDefaultLocaleOf is false without a Localizations ancestor', (
    WidgetTester tester,
  ) async {
    late bool result;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          result = Localizations.isDefaultLocaleOf(context);
          return const SizedBox();
        },
      ),
    );

    expect(result, isFalse);
  });

  testWidgets('Localizations reports isDefaultLocale in its diagnostics', (
    WidgetTester tester,
  ) async {
    final builder = DiagnosticPropertiesBuilder();
    Localizations(
      locale: enUS,
      isDefaultLocale: true,
      delegates: const <LocalizationsDelegate<dynamic>>[DefaultWidgetsLocalizations.delegate],
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();
    expect(description, contains('default locale'));
  });
}
