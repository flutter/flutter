// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('English translations exist for all MaterialLocalizations properties', (WidgetTester tester) async {
    const MaterialLocalizations localizations = DefaultMaterialLocalizations();

    expect(localizations.openAppDrawerTooltip, isNotNull);
    expect(localizations.backButtonTooltip, isNotNull);
    expect(localizations.closeButtonTooltip, isNotNull);
    expect(localizations.deleteButtonTooltip, isNotNull);
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
    expect(localizations.modalBarrierDismissLabel, isNotNull);
    expect(localizations.drawerLabel, isNotNull);
    expect(localizations.popupMenuLabel, isNotNull);
    expect(localizations.dialogLabel, isNotNull);
    expect(localizations.alertDialogLabel, isNotNull);
    expect(localizations.searchFieldLabel, isNotNull);
    expect(localizations.reorderItemUp, isNotNull);
    expect(localizations.reorderItemDown, isNotNull);
    expect(localizations.reorderItemLeft, isNotNull);
    expect(localizations.reorderItemRight, isNotNull);
    expect(localizations.reorderItemToEnd, isNotNull);
    expect(localizations.reorderItemToStart, isNotNull);

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
