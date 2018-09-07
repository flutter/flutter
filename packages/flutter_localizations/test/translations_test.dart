// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (String language in kSupportedLanguages) {
    testWidgets('translations exist for $language', (WidgetTester tester) async {
      final Locale locale = new Locale(language, '');

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
    });
  }

  testWidgets('spot check selectedRowCount translations', (WidgetTester tester) async {
    MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('en', ''));
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

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('es', ''));
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

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('ro', ''));
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
  });

  testWidgets('spot check formatMediumDate(), formatFullDate() translations', (WidgetTester tester) async {
    MaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('en', ''));
    expect(localizations.formatMediumDate(new DateTime(2015, 7, 23)), 'Thu, Jul 23');
    expect(localizations.formatFullDate(new DateTime(2015, 7, 23)), 'Thursday, July 23, 2015');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('en', 'GB'));
    expect(localizations.formatMediumDate(new DateTime(2015, 7, 23)), 'Thu 23 Jul');
    expect(localizations.formatFullDate(new DateTime(2015, 7, 23)), 'Thursday, 23 July 2015');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('es', ''));
    expect(localizations.formatMediumDate(new DateTime(2015, 7, 23)), 'jue., 23 jul.');
    expect(localizations.formatFullDate(new DateTime(2015, 7, 23)), 'jueves, 23 de julio de 2015');

    localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('de', ''));
    expect(localizations.formatMediumDate(new DateTime(2015, 7, 23)), 'Do., 23. Juli');
    expect(localizations.formatFullDate(new DateTime(2015, 7, 23)), 'Donnerstag, 23. Juli 2015');
  });
}
