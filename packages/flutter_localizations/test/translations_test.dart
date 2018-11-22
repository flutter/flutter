// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (String language in kSupportedLanguages) {
    testWidgets('translations exist for $language', (WidgetTester tester) async {
      final Locale locale = Locale(language);

      expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);

      final MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(locale);

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
      expect(localizations.drawerLabel, isNotNull);
      expect(localizations.popupMenuLabel, isNotNull);
      expect(localizations.dialogLabel, isNotNull);
      expect(localizations.alertDialogLabel, isNotNull);
      expect(localizations.collapsedIconTapHint, isNotNull);
      expect(localizations.expandedIconTapHint, isNotNull);
      expect(localizations.refreshIndicatorSemanticLabel, isNotNull);

      expect(localizations.remainingTextFieldCharacterCount(0), isNotNull);
      expect(localizations.remainingTextFieldCharacterCount(1), isNotNull);
      expect(localizations.remainingTextFieldCharacterCount(10), isNotNull);
      expect(localizations.remainingTextFieldCharacterCount(0), isNot(contains(r'$remainingCount')));
      expect(localizations.remainingTextFieldCharacterCount(1), isNot(contains(r'$remainingCount')));
      expect(localizations.remainingTextFieldCharacterCount(10), isNot(contains(r'$remainingCount')));

      expect(localizations.aboutListTileTitle('FOO'), isNotNull);
      expect(localizations.aboutListTileTitle('FOO'), contains('FOO'));

      expect(localizations.selectedRowCountTitle(0), isNotNull);
      expect(localizations.selectedRowCountTitle(1), isNotNull);
      expect(localizations.selectedRowCountTitle(2), isNotNull);
      expect(localizations.selectedRowCountTitle(100), isNotNull);
      expect(localizations.selectedRowCountTitle(0), isNot(contains(r'$selectedRowCount')));
      expect(localizations.selectedRowCountTitle(1), isNot(contains(r'$selectedRowCount')));
      expect(localizations.selectedRowCountTitle(2), isNot(contains(r'$selectedRowCount')));
      expect(localizations.selectedRowCountTitle(100), isNot(contains(r'$selectedRowCount')));

      expect(localizations.pageRowsInfoTitle(1, 10, 100, true), isNotNull);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, false), isNotNull);
      expect(localizations.pageRowsInfoTitle(1, 10, 100, true), isNot(contains(r'$firstRow')));
      expect(localizations.pageRowsInfoTitle(1, 10, 100, true), isNot(contains(r'$lastRow')));
      expect(localizations.pageRowsInfoTitle(1, 10, 100, true), isNot(contains(r'$rowCount')));
      expect(localizations.pageRowsInfoTitle(1, 10, 100, false), isNot(contains(r'$firstRow')));
      expect(localizations.pageRowsInfoTitle(1, 10, 100, false), isNot(contains(r'$lastRow')));
      expect(localizations.pageRowsInfoTitle(1, 10, 100, false), isNot(contains(r'$rowCount')));

      expect(localizations.tabLabel(tabIndex: 2, tabCount: 5), isNotNull);
      expect(localizations.tabLabel(tabIndex: 2, tabCount: 5), isNot(contains(r'$tabIndex')));
      expect(localizations.tabLabel(tabIndex: 2, tabCount: 5), isNot(contains(r'$tabCount')));
      expect(() => localizations.tabLabel(tabIndex: 0, tabCount: 5), throwsAssertionError);
      expect(() => localizations.tabLabel(tabIndex: 2, tabCount: 0), throwsAssertionError);

      expect(localizations.formatHour(const TimeOfDay(hour: 10, minute: 0)), isNotNull);
      expect(localizations.formatMinute(const TimeOfDay(hour: 10, minute: 0)), isNotNull);
      expect(localizations.formatYear(DateTime(2018, 8, 1)), isNotNull);
      expect(localizations.formatMediumDate(DateTime(2018, 8, 1)), isNotNull);
      expect(localizations.formatFullDate(DateTime(2018, 8, 1)), isNotNull);
      expect(localizations.formatMonthYear(DateTime(2018, 8, 1)), isNotNull);
      expect(localizations.narrowWeekdays, isNotNull);
      expect(localizations.narrowWeekdays.length, 7);
      expect(localizations.formatDecimal(123), isNotNull);
      expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 10, minute: 0)), isNotNull);
    });
  }

  testWidgets('spot check selectedRowCount translations', (WidgetTester tester) async {
    MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('en'));
    expect(localizations.selectedRowCountTitle(0), 'No items selected');
    expect(localizations.selectedRowCountTitle(1), '1 item selected');
    expect(localizations.selectedRowCountTitle(2), '2 items selected');
    expect(localizations.selectedRowCountTitle(3), '3 items selected');
    expect(localizations.selectedRowCountTitle(5), '5 items selected');
    expect(localizations.selectedRowCountTitle(10), '10 items selected');
    expect(localizations.selectedRowCountTitle(15), '15 items selected');
    expect(localizations.selectedRowCountTitle(29), '29 items selected');
    expect(localizations.selectedRowCountTitle(10000), '10,000 items selected');
    expect(localizations.selectedRowCountTitle(10019), '10,019 items selected');
    expect(localizations.selectedRowCountTitle(123456789), '123,456,789 items selected');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('es'));
    expect(localizations.selectedRowCountTitle(0), 'No se han seleccionado elementos');
    expect(localizations.selectedRowCountTitle(1), '1 elemento seleccionado');
    expect(localizations.selectedRowCountTitle(2), '2 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(3), '3 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(5), '5 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(10), '10 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(15), '15 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(29), '29 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(10000), '10.000 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(10019), '10.019 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(123456789), '123.456.789 elementos seleccionados');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('ro'));
    expect(localizations.selectedRowCountTitle(0), 'Nu există elemente selectate');
    expect(localizations.selectedRowCountTitle(1), 'Un articol selectat');
    expect(localizations.selectedRowCountTitle(2), '2 articole selectate');
    expect(localizations.selectedRowCountTitle(3), '3 articole selectate');
    expect(localizations.selectedRowCountTitle(5), '5 articole selectate');
    expect(localizations.selectedRowCountTitle(10), '10 articole selectate');
    expect(localizations.selectedRowCountTitle(15), '15 articole selectate');
    expect(localizations.selectedRowCountTitle(29), '29 de articole selectate');
    expect(localizations.selectedRowCountTitle(10000), '10.000 de articole selectate');
    expect(localizations.selectedRowCountTitle(10019), '10.019 articole selectate');
    expect(localizations.selectedRowCountTitle(123456789), '123.456.789 de articole selectate');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('km'));
    expect(localizations.selectedRowCountTitle(0), 'បាន​ជ្រើស​រើស​ធាតុ 0');
    expect(localizations.selectedRowCountTitle(1), 'បាន​ជ្រើស​រើស​ធាតុ 1');
    expect(localizations.selectedRowCountTitle(2), 'បាន​ជ្រើស​រើស​ធាតុ 2');
    expect(localizations.selectedRowCountTitle(10000), 'បាន​ជ្រើស​រើស​ធាតុ 10.000');
    expect(localizations.selectedRowCountTitle(123456789), 'បាន​ជ្រើស​រើស​ធាតុ 123.456.789');
  });

  testWidgets('spot check formatMediumDate(), formatFullDate() translations', (WidgetTester tester) async {
    MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('en'));
    expect(localizations.formatMediumDate(DateTime(2015, 7, 23)), 'Thu, Jul 23');
    expect(localizations.formatFullDate(DateTime(2015, 7, 23)), 'Thursday, July 23, 2015');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('en', 'GB'));
    expect(localizations.formatMediumDate(DateTime(2015, 7, 23)), 'Thu 23 Jul');
    expect(localizations.formatFullDate(DateTime(2015, 7, 23)), 'Thursday, 23 July 2015');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('es'));
    expect(localizations.formatMediumDate(DateTime(2015, 7, 23)), 'jue., 23 jul.');
    expect(localizations.formatFullDate(DateTime(2015, 7, 23)), 'jueves, 23 de julio de 2015');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('de'));
    expect(localizations.formatMediumDate(DateTime(2015, 7, 23)), 'Do., 23. Juli');
    expect(localizations.formatFullDate(DateTime(2015, 7, 23)), 'Donnerstag, 23. Juli 2015');
  });

  testWidgets('Chinese resolution', (WidgetTester tester) async {
    Locale locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZh, true);

    locale = const Locale('zh', 'TW');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHantTw, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: null, countryCode: 'HK');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHantHk, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: null, countryCode: 'TW');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHantTw, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHans, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHant, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHans, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHans, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'TW');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHans, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'CN');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHant, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHant, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: null, countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZh, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Latn', countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZh, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Latn', countryCode: 'TW');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZh, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: null, countryCode: 'TW');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEn, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Cyrl', countryCode: 'RU');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZh, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: null, countryCode: 'RU');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZh, true);

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Cyrl', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZh, true);
  });

testWidgets('Serbian resolution', (WidgetTester tester) async {
    Locale locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSr, true);

    locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSrCyrl, true);

    locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSrLatn, true);

    locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: null, countryCode: 'SR');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSr, true);

    locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl', countryCode: 'SR');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSrCyrl, true);

    locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn', countryCode: 'SR');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSrLatn, true);

    locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl', countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSrCyrl, true);

    locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn', countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSrLatn, true);

    locale = const Locale.fromSubtags(languageCode: 'sr', scriptCode: null, countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationSr, true);
  });

  testWidgets('Misc resolution', (WidgetTester tester) async {
    Locale locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEn, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: 'Cyrl', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEn, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: null, countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEn, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: null, countryCode: 'AU');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEnAu, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: null, countryCode: 'GB');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEnGb, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: null, countryCode: 'SG');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEnSg, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: null, countryCode: 'MX');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEn, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: 'Hant', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEn, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: 'Hant', countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEn, true);

    locale = const Locale.fromSubtags(languageCode: 'en', scriptCode: 'Hans', countryCode: 'CN');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEn, true);

    locale = const Locale.fromSubtags(languageCode: 'es', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEs, true);

    locale = const Locale.fromSubtags(languageCode: 'es', scriptCode: null, countryCode: '419');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEs419, true);

    locale = const Locale.fromSubtags(languageCode: 'es', scriptCode: null, countryCode: 'MX');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEsMx, true);

    locale = const Locale.fromSubtags(languageCode: 'es', scriptCode: null, countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEsUs, true);

    locale = const Locale.fromSubtags(languageCode: 'es', scriptCode: null, countryCode: 'AR');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEsAr, true);

    locale = const Locale.fromSubtags(languageCode: 'es', scriptCode: null, countryCode: 'ES');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEs, true);

    locale = const Locale.fromSubtags(languageCode: 'es', scriptCode: 'Latn', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEs, true);

    locale = const Locale.fromSubtags(languageCode: 'es', scriptCode: 'Latn', countryCode: 'US');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationEsUs, true);

    locale = const Locale.fromSubtags(languageCode: 'fr', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationFr, true);

    locale = const Locale.fromSubtags(languageCode: 'fr', scriptCode: null, countryCode: 'CA');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationFrCa, true);

    locale = const Locale.fromSubtags(languageCode: 'de', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationDe, true);

    locale = const Locale.fromSubtags(languageCode: 'de', scriptCode: null, countryCode: 'CH');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationDeCh, true);

    locale = const Locale.fromSubtags(languageCode: 'th', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationTh, true);

    locale = const Locale.fromSubtags(languageCode: 'ru', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationRu, true);
  });

  testWidgets('Chinese translations spot check', (WidgetTester tester) async {
    Locale locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: null, countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZh, true);
    expect(localizations.alertDialogLabel, '提醒');
    expect(localizations.anteMeridiemAbbreviation, '上午');
    expect(localizations.closeButtonLabel, '关闭');
    expect(localizations.okButtonLabel, '确定');

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHans, true);
    expect(localizations.alertDialogLabel, '提醒');
    expect(localizations.anteMeridiemAbbreviation, '上午');
    expect(localizations.closeButtonLabel, '关闭');
    expect(localizations.okButtonLabel, '确定');

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: null);
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHant, true);
    expect(localizations.alertDialogLabel, '快訊');
    expect(localizations.anteMeridiemAbbreviation, '上午');
    expect(localizations.closeButtonLabel, '關閉');
    expect(localizations.okButtonLabel, '確定');

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHantTw, true);
    expect(localizations.alertDialogLabel, '快訊');
    expect(localizations.anteMeridiemAbbreviation, '上午');
    expect(localizations.closeButtonLabel, '關閉');
    expect(localizations.okButtonLabel, '確定');

    locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK');
    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    localizations = await GlobalMaterialLocalizations.delegate.load(locale);
    expect(localizations is MaterialLocalizationZhHantHk, true);
    expect(localizations.alertDialogLabel, '快訊');
    expect(localizations.anteMeridiemAbbreviation, '上午');
    expect(localizations.closeButtonLabel, '關閉');
    expect(localizations.okButtonLabel, '確定');
  });
}
