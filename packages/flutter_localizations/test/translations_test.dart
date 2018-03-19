// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Watch out: this list must be kept in sync with the comment at the top of
  // GlobalMaterialLocalizations.
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
    'ko', // Korean
    'nl', // Dutch
    'pl', // Polish
    'ps', // Pashto
    'pt', // Portugese
    'ro', // Romanian
    'ru', // Russian
    'th', // Thai
    'tr', // Turkish
    'ur', // Urdu
    'zh', // Chinese (simplified)
  ];

  for (String language in languages) {
    testWidgets('translations exist for $language', (WidgetTester tester) async {
      final Locale locale = new Locale(language, '');

      expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);

      final MaterialLocalizations localizations = new GlobalMaterialLocalizations(locale);

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
    });
  }

  testWidgets('spot check selectedRowCount translations', (WidgetTester tester) async {
    MaterialLocalizations localizations = new GlobalMaterialLocalizations(const Locale('en', ''));
    expect(localizations.selectedRowCountTitle(0), 'No items selected');
    expect(localizations.selectedRowCountTitle(1), '1 item selected');
    expect(localizations.selectedRowCountTitle(2), '2 items selected');
    expect(localizations.selectedRowCountTitle(123456789), '123,456,789 items selected');

    localizations = new GlobalMaterialLocalizations(const Locale('es', ''));
    expect(localizations.selectedRowCountTitle(0), 'No se han seleccionado elementos');
    expect(localizations.selectedRowCountTitle(1), '1 elemento seleccionado');
    expect(localizations.selectedRowCountTitle(2), '2 elementos seleccionados');
    expect(localizations.selectedRowCountTitle(123456789), '123.456.789 elementos seleccionados');

    localizations = new GlobalMaterialLocalizations(const Locale('ro', ''));
    expect(localizations.selectedRowCountTitle(0), 'Nu există elemente selectate');
    expect(localizations.selectedRowCountTitle(1), 'Un articol selectat');
    expect(localizations.selectedRowCountTitle(2), '2 de articole selectate');
    expect(localizations.selectedRowCountTitle(123456789), '123.456.789 de articole selectate');
  });
}
