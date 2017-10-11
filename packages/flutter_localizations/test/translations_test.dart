// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    testWidgets('translations exist for $language', (WidgetTester tester) async {
      final Locale locale = new Locale(language, '');
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
    expect(localizations.selectedRowCountTitle(1), '1 artículo seleccionado');
    expect(localizations.selectedRowCountTitle(2), '2 artículos seleccionados');
    expect(localizations.selectedRowCountTitle(123456789), '123.456.789 artículos seleccionados');
  });
}
