// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('English translations exist for all MaterialLocalizations properties', (WidgetTester tester) async {
    const MaterialLocalizations localizations = DefaultMaterialLocalizations();

    expect(localizations.openAppDrawerTooltip, isNotNull);
    expect(localizations.backButtonTooltip, isNotNull);
    expect(localizations.closeButtonTooltip, isNotNull);
    expect(localizations.deleteButtonTooltip, isNotNull);
    expect(localizations.moreButtonTooltip, isNotNull);
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
    expect(localizations.anteMeridiemAbbreviation, isNotNull);
    expect(localizations.postMeridiemAbbreviation, isNotNull);
    expect(localizations.timePickerHourModeAnnouncement, isNotNull);
    expect(localizations.timePickerMinuteModeAnnouncement, isNotNull);
    expect(localizations.modalBarrierDismissLabel, isNotNull);
    expect(localizations.drawerLabel, isNotNull);
    expect(localizations.popupMenuLabel, isNotNull);
    expect(localizations.dialogLabel, isNotNull);
    expect(localizations.alertDialogLabel, isNotNull);
    expect(localizations.searchFieldLabel, isNotNull);
    expect(localizations.dateSeparator, isNotNull);
    expect(localizations.dateHelpText, isNotNull);
    expect(localizations.selectYearSemanticsLabel, isNotNull);
    expect(localizations.unspecifiedDate, isNotNull);
    expect(localizations.unspecifiedDateRange, isNotNull);
    expect(localizations.dateInputLabel, isNotNull);
    expect(localizations.dateRangeStartLabel, isNotNull);
    expect(localizations.dateRangeEndLabel, isNotNull);
    expect(localizations.invalidDateFormatLabel, isNotNull);
    expect(localizations.invalidDateRangeLabel, isNotNull);
    expect(localizations.dateOutOfRangeLabel, isNotNull);
    expect(localizations.saveButtonLabel, isNotNull);
    expect(localizations.datePickerHelpText, isNotNull);
    expect(localizations.dateRangePickerHelpText, isNotNull);
    expect(localizations.calendarModeButtonLabel, isNotNull);
    expect(localizations.inputDateModeButtonLabel, isNotNull);
    expect(localizations.timePickerDialHelpText, isNotNull);
    expect(localizations.timePickerInputHelpText, isNotNull);
    expect(localizations.timePickerHourLabel, isNotNull);
    expect(localizations.timePickerMinuteLabel, isNotNull);
    expect(localizations.invalidTimeLabel, isNotNull);
    expect(localizations.dialModeButtonLabel, isNotNull);
    expect(localizations.inputTimeModeButtonLabel, isNotNull);
    expect(localizations.signedInLabel, isNotNull);
    expect(localizations.hideAccountsLabel, isNotNull);
    expect(localizations.showAccountsLabel, isNotNull);
    expect(localizations.reorderItemToStart, isNotNull);
    expect(localizations.reorderItemToEnd, isNotNull);
    expect(localizations.reorderItemUp, isNotNull);
    expect(localizations.reorderItemDown, isNotNull);
    expect(localizations.reorderItemLeft, isNotNull);
    expect(localizations.reorderItemRight, isNotNull);

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

    expect(localizations.licensesPackageDetailText(0), isNotNull);
    expect(localizations.licensesPackageDetailText(1), isNotNull);
    expect(localizations.licensesPackageDetailText(2), isNotNull);
    expect(localizations.licensesPackageDetailText(100), isNotNull);
    expect(localizations.licensesPackageDetailText(1).contains(r'$licensesCount'), isFalse);
    expect(localizations.licensesPackageDetailText(2).contains(r'$licensesCount'), isFalse);
    expect(localizations.licensesPackageDetailText(100).contains(r'$licensesCount'), isFalse);
  });
}
