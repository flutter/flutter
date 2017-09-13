// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildFrame({
  Locale locale,
  WidgetBuilder buildContent,
  Iterable<Locale> supportedLocales: const <Locale>[
    const Locale('en', 'US'),
    const Locale('es', 'es'),
  ],
}) {
  return new MaterialApp(
    color: const Color(0xFFFFFFFF),
    locale: locale,
    supportedLocales: supportedLocales,
    onGenerateRoute: (RouteSettings settings) {
      return new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return buildContent(context);
        }
      );
    },
  );
}

void main() {
  testWidgets('sanity check', (WidgetTester tester) async {
    final Key textKey = new UniqueKey();

    await tester.pumpWidget(
      buildFrame(
        buildContent: (BuildContext context) {
          return new Text(
            MaterialLocalizations.of(context).backButtonTooltip,
            key: textKey,
          );
        }
      )
    );

    expect(tester.widget<Text>(find.byKey(textKey)).data, 'Back');

    // Unrecognized locale falls back to 'en'
    await tester.binding.setLocale('foo', 'bar');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(textKey)).data, 'Back');

    // Spanish Bolivia locale, falls back to just 'es'
    await tester.binding.setLocale('es', 'bo');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(textKey)).data, 'Espalda');

  });

  testWidgets('translations exist for all materia/i18n languages', (WidgetTester tester) async {
    final List<String> languages = <String>[
      'ar', // Arabic
      'de', // German
      'en', // English
      'es', // Spanish
      'fa', // Farsi (Persian)
      'fr', // French
      'he', // Hebrew
      'it', // Italian
      'ja', // Japanese
      'ps', // Pashto
      'pt', // Portugese
      'ru', // Russian
      'sd', // Sindhi
      'ur', // Urdu
      'zh', // Chinese (simplified)
    ];

    for (String language in languages) {
      final Locale locale = new Locale(language, '');
      final MaterialLocalizations localizations = new DefaultMaterialLocalizations(locale);

      expect(localizations.openAppDrawerTooltip, isNotNull);
      expect(localizations.backButtonTooltip, isNotNull);
      expect(localizations.closeButtonTooltip, isNotNull);
      expect(localizations.nextMonthTooltip, isNotNull);
      expect(localizations.previousMonthTooltip, isNotNull);
      expect(localizations.nextPageTooltip, isNotNull);
      expect(localizations.previousPageTooltip, isNotNull);
      expect(localizations.showMenuTooltip, isNotNull);
      expect(localizations.licensesPageTitle, isNotNull);
      expect(localizations.rowsPerPageTitle, isNotNull);
      expect(localizations.cancelButtonLabel, isNotNull);
      expect(localizations.closeButtonLabel, isNotNull);
      expect(localizations.continueButtonLabel, isNotNull);
      expect(localizations.copyButtonLabel, isNotNull);
      expect(localizations.cutButtonLabel, isNotNull);
      expect(localizations.okButtonLabel, isNotNull);
      expect(localizations.pasteButtonLabel, isNotNull);
      expect(localizations.selectAllButtonLabel, isNotNull);
      expect(localizations.viewLicensesButtonLabel, isNotNull);

      expect(localizations.selectedRowCountTitle(0), isNotNull);
      expect(localizations.selectedRowCountTitle(1), isNotNull);
      expect(localizations.selectedRowCountTitle(2), isNotNull);
      expect(localizations.selectedRowCountTitle(100), isNotNull);
      expect(localizations.selectedRowCountTitle(0).contains(r'$selectedRowCount'), isFalse);
      expect(localizations.selectedRowCountTitle(1).contains(r'$selectedRowCount'), isFalse);
      expect(localizations.selectedRowCountTitle(2).contains(r'$selectedRowCount'), isFalse);
      expect(localizations.selectedRowCountTitle(100).contains(r'$selectedRowCount'), isFalse);

      expect(localizations.pageRowsInfoTitle(1, 10, 100, true), isNotNull);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, false), isNotNull);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, true).contains(r'$firstRow'), isFalse);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, true).contains(r'$lastRow'), isFalse);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, true).contains(r'$rowCount'), isFalse);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, false).contains(r'$firstRow'), isFalse);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, false).contains(r'$lastRow'), isFalse);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, false).contains(r'$rowCount'), isFalse);
    }
  });

  testWidgets('spot check selectedRowCount translations', (WidgetTester tester) async {
    MaterialLocalizations localizations = new DefaultMaterialLocalizations(const Locale('en', ''));
    expect(localizations.selectedRowCountTitle(0), 'No items selected');
    expect(localizations.selectedRowCountTitle(1), '1 item selected');
    expect(localizations.selectedRowCountTitle(2), '2 items selected');
    expect(localizations.selectedRowCountTitle(123456789), '123,456,789 items selected');

    localizations = new DefaultMaterialLocalizations(const Locale('es', ''));
    expect(localizations.selectedRowCountTitle(0), 'No se han seleccionado elementos');
    expect(localizations.selectedRowCountTitle(1), '1 artículo seleccionado');
    expect(localizations.selectedRowCountTitle(2), '2 artículos seleccionados');
    expect(localizations.selectedRowCountTitle(123456789), '123.456.789 artículos seleccionados');
  });

  testWidgets('deprecated Android/Java locales are modernized', (WidgetTester tester) async {
    final Key textKey = new UniqueKey();

    await tester.pumpWidget(
      buildFrame(
        supportedLocales: <Locale>[
          const Locale('en', 'US'),
          const Locale('he', 'IL'),
          const Locale('yi', 'IL'),
          const Locale('id', 'JV'),
        ],
        buildContent: (BuildContext context) {
          return new Text(
            '${Localizations.localeOf(context)}',
            key: textKey,
          );
        },
      )
    );

    expect(tester.widget<Text>(find.byKey(textKey)).data, 'en_US');

    // Hebrew was iw (ISO-639) is he (ISO-639-1)
    await tester.binding.setLocale('iw', 'IL');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(textKey)).data, 'he_IL');

    // Yiddish was ji (ISO-639) is yi (ISO-639-1)
    await tester.binding.setLocale('ji', 'IL');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(textKey)).data, 'yi_IL');

    // Indonesian was in (ISO-639) is id (ISO-639-1)
    await tester.binding.setLocale('in', 'JV');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(textKey)).data, 'id_JV');
  });

}
