// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DatePickerThemeData copyWith, ==, hashCode basics', () {
    expect(const DatePickerThemeData(), const DatePickerThemeData().copyWith());
    expect(const DatePickerThemeData().hashCode, const DatePickerThemeData().copyWith().hashCode);
  });

  test('DatePickerThemeData defaults', () {
    const DatePickerThemeData theme = DatePickerThemeData();
    expect(theme.backgroundColor, null);
    expect(theme.elevation, null);
    expect(theme.shadowColor, null);
    expect(theme.surfaceTintColor, null);
    expect(theme.shape, null);
    expect(theme.headerBackgroundColor, null);
    expect(theme.headerForegroundColor, null);
    expect(theme.headerHeadlineStyle, null);
    expect(theme.headerHelpStyle, null);
    expect(theme.weekdayStyle, null);
    expect(theme.dayStyle, null);
    expect(theme.dayForegroundColor, null);
    expect(theme.dayBackgroundColor, null);
    expect(theme.dayOverlayColor, null);
    expect(theme.todayForegroundColor, null);
    expect(theme.todayBackgroundColor, null);
    expect(theme.todayBorder, null);
    expect(theme.yearStyle, null);
    expect(theme.yearForegroundColor, null);
    expect(theme.yearBackgroundColor, null);
    expect(theme.yearOverlayColor, null);
    expect(theme.rangePickerElevation, null);
    expect(theme.rangePickerShadowColor, null);
    expect(theme.rangePickerSurfaceTintColor, null);
    expect(theme.rangePickerShape, null);
    expect(theme.rangePickerHeaderBackgroundColor, null);
    expect(theme.rangePickerHeaderForegroundColor, null);
    expect(theme.rangePickerHeaderHeadlineStyle, null);
    expect(theme.rangePickerHeaderHelpStyle, null);
    expect(theme.rangeSelectionBackgroundColor, null);
    expect(theme.rangeSelectionOverlayColor, null);
  });

  testWidgets('Default DatePickerThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const DatePickerThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('DatePickerThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const DatePickerThemeData(
      backgroundColor: Color(0xfffffff0),
      elevation: 6,
      shadowColor: Color(0xfffffff1),
      surfaceTintColor: Color(0xfffffff2),
      shape: StadiumBorder(),
      headerBackgroundColor: Color(0xfffffff3),
      headerForegroundColor: Color(0xfffffff4),
      headerHeadlineStyle: TextStyle(fontSize: 10),
      headerHelpStyle: TextStyle(fontSize: 11),
      weekdayStyle: TextStyle(fontSize: 12),
      dayStyle: TextStyle(fontSize: 13),
      dayForegroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffff5)),
      dayBackgroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffff6)),
      dayOverlayColor: MaterialStatePropertyAll<Color>(Color(0xfffffff7)),
      todayForegroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffff8)),
      todayBackgroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffff9)),
      todayBorder: BorderSide(width: 10),
      yearStyle: TextStyle(fontSize: 13),
      yearForegroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffff9)),
      yearBackgroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffffa)),
      yearOverlayColor: MaterialStatePropertyAll<Color>(Color(0xfffffffb)),
      rangePickerElevation: 7,
      rangePickerShadowColor: Color(0xfffffffc),
      rangePickerSurfaceTintColor: Color(0xfffffffd),
      rangePickerShape: CircleBorder(),
      rangePickerHeaderBackgroundColor: Color(0xfffffffe),
      rangePickerHeaderForegroundColor: Color(0xffffff0f),
      rangePickerHeaderHeadlineStyle: TextStyle(fontSize: 14),
      rangePickerHeaderHelpStyle: TextStyle(fontSize: 15),
      rangeSelectionBackgroundColor: Color(0xffffff1f),
      rangeSelectionOverlayColor: MaterialStatePropertyAll<Color>(Color(0xffffff2f)),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'backgroundColor: Color(0xfffffff0)',
      'elevation: 6.0',
      'shadowColor: Color(0xfffffff1)',
      'surfaceTintColor: Color(0xfffffff2)',
      'shape: StadiumBorder(BorderSide(width: 0.0, style: none))',
      'headerBackgroundColor: Color(0xfffffff3)',
      'headerForegroundColor: Color(0xfffffff4)',
      'headerHeadlineStyle: TextStyle(inherit: true, size: 10.0)',
      'headerHelpStyle: TextStyle(inherit: true, size: 11.0)',
      'weekDayStyle: TextStyle(inherit: true, size: 12.0)',
      'dayStyle: TextStyle(inherit: true, size: 13.0)',
      'dayForegroundColor: MaterialStatePropertyAll(Color(0xfffffff5))',
      'dayBackgroundColor: MaterialStatePropertyAll(Color(0xfffffff6))',
      'dayOverlayColor: MaterialStatePropertyAll(Color(0xfffffff7))',
      'todayForegroundColor: MaterialStatePropertyAll(Color(0xfffffff8))',
      'todayBackgroundColor: MaterialStatePropertyAll(Color(0xfffffff9))',
      'todayBorder: BorderSide(width: 10.0)',
      'yearStyle: TextStyle(inherit: true, size: 13.0)',
      'yearForegroundColor: MaterialStatePropertyAll(Color(0xfffffff9))',
      'yearBackgroundColor: MaterialStatePropertyAll(Color(0xfffffffa))',
      'yearOverlayColor: MaterialStatePropertyAll(Color(0xfffffffb))',
      'rangePickerElevation: 7.0',
      'rangePickerShadowColor: Color(0xfffffffc)',
      'rangePickerSurfaceTintColor: Color(0xfffffffd)',
      'rangePickerShape: CircleBorder(BorderSide(width: 0.0, style: none))',
      'rangePickerHeaderBackgroundColor: Color(0xfffffffe)',
      'rangePickerHeaderForegroundColor: Color(0xffffff0f)',
      'rangePickerHeaderHeadlineStyle: TextStyle(inherit: true, size: 14.0)',
      'rangePickerHeaderHelpStyle: TextStyle(inherit: true, size: 15.0)',
      'rangeSelectionBackgroundColor: Color(0xffffff1f)',
      'rangeSelectionOverlayColor: MaterialStatePropertyAll(Color(0xffffff2f))',
    ]);
  });
}
