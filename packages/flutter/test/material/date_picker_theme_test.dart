// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DatePickerThemeData datePickerTheme = DatePickerThemeData(
    backgroundColor: Color(0xfffffff0),
    elevation: 6,
    shadowColor: Color(0xfffffff1),
    surfaceTintColor: Color(0xfffffff2),
    shape: RoundedRectangleBorder(),
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
    todayBorder: BorderSide(width: 3),
    yearStyle: TextStyle(fontSize: 13),
    yearForegroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffffa)),
    yearBackgroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffffb)),
    yearOverlayColor: MaterialStatePropertyAll<Color>(Color(0xfffffffc)),
    rangePickerBackgroundColor: Color(0xfffffffd),
    rangePickerElevation: 7,
    rangePickerShadowColor: Color(0xfffffffe),
    rangePickerSurfaceTintColor: Color(0xffffffff),
    rangePickerShape: RoundedRectangleBorder(),
    rangePickerHeaderBackgroundColor: Color(0xffffff0f),
    rangePickerHeaderForegroundColor: Color(0xffffff1f),
    rangePickerHeaderHeadlineStyle: TextStyle(fontSize: 14),
    rangePickerHeaderHelpStyle: TextStyle(fontSize: 15),
    rangeSelectionBackgroundColor: Color(0xffffff2f),
    rangeSelectionOverlayColor: MaterialStatePropertyAll<Color>(Color(0xffffff3f)),
  );

  Material findDialogMaterial(WidgetTester tester) {
    return tester.widget<Material>(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(Material)
      ).first
    );
  }

  Material findHeaderMaterial(WidgetTester tester, String text) {
    return tester.widget<Material>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(Material)
      ).first,
    );
  }

  BoxDecoration? findTextDecoration(WidgetTester tester, String date) {
    final Container container = tester.widget<Container>(
      find.ancestor(
        of: find.text(date),
        matching: find.byType(Container)
      ).first,
    );
    return container.decoration as BoxDecoration?;
  }

  test('DatePickerThemeData copyWith, ==, hashCode basics', () {
    expect(const DatePickerThemeData(), const DatePickerThemeData().copyWith());
    expect(const DatePickerThemeData().hashCode, const DatePickerThemeData().copyWith().hashCode);
  });

  test('DatePickerThemeData lerp special cases', () {
    const DatePickerThemeData data = DatePickerThemeData();
    expect(identical(DatePickerThemeData.lerp(data, data, 0.5), data), true);
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
    expect(theme.rangePickerBackgroundColor, null);
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

  testWidgets('DatePickerTheme.defaults M3 defaults', (WidgetTester tester) async {
    late final DatePickerThemeData m3; // M3 Defaults
    late final ThemeData theme;
    late final ColorScheme colorScheme;
    late final TextTheme textTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Builder(
          builder: (BuildContext context) {
            m3 = DatePickerTheme.defaults(context);
            theme = Theme.of(context);
            colorScheme = theme.colorScheme;
            textTheme = theme.textTheme;
            return Container();
          },
        ),
      ),
    );

    expect(m3.backgroundColor, colorScheme.surface);
    expect(m3.elevation, 6);
    expect(m3.shadowColor, const Color(0x00000000)); // Colors.transparent
    expect(m3.surfaceTintColor, colorScheme.surfaceTint);
    expect(m3.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)));
    expect(m3.headerBackgroundColor, const Color(0x00000000)); // Colors.transparent
    expect(m3.headerForegroundColor, colorScheme.onSurfaceVariant);
    expect(m3.headerHeadlineStyle, textTheme.headlineLarge);
    expect(m3.headerHelpStyle, textTheme.labelLarge);
    expect(m3.weekdayStyle, textTheme.bodyLarge?.apply(color: colorScheme.onSurface));
    expect(m3.dayStyle, textTheme.bodyLarge);
    expect(m3.dayForegroundColor?.resolve(<MaterialState>{}), colorScheme.onSurface);
    expect(m3.dayForegroundColor?.resolve(<MaterialState>{MaterialState.selected}), colorScheme.onPrimary);
    expect(m3.dayForegroundColor?.resolve(<MaterialState>{MaterialState.disabled}), colorScheme.onSurface.withOpacity(0.38));
    expect(m3.dayBackgroundColor?.resolve(<MaterialState>{}), null);
    expect(m3.dayBackgroundColor?.resolve(<MaterialState>{MaterialState.selected}), colorScheme.primary);
    expect(m3.dayOverlayColor?.resolve(<MaterialState>{}), null);
    expect(m3.dayOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.hovered}), colorScheme.onPrimary.withOpacity(0.08));
    expect(m3.dayOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.focused}), colorScheme.onPrimary.withOpacity(0.12));
    expect(m3.dayOverlayColor?.resolve(<MaterialState>{MaterialState.hovered}), colorScheme.onSurfaceVariant.withOpacity(0.08));
    expect(m3.dayOverlayColor?.resolve(<MaterialState>{MaterialState.focused}), colorScheme.onSurfaceVariant.withOpacity(0.12));
    expect(m3.dayOverlayColor?.resolve(<MaterialState>{MaterialState.pressed}), colorScheme.onSurfaceVariant.withOpacity(0.12));
    expect(m3.todayForegroundColor?.resolve(<MaterialState>{}), colorScheme.primary);
    expect(m3.todayForegroundColor?.resolve(<MaterialState>{MaterialState.disabled}), colorScheme.primary.withOpacity(0.38));
    expect(m3.todayBorder, BorderSide(color: colorScheme.primary));
    expect(m3.yearStyle, textTheme.bodyLarge);
    expect(m3.yearForegroundColor?.resolve(<MaterialState>{}), colorScheme.onSurfaceVariant);
    expect(m3.yearForegroundColor?.resolve(<MaterialState>{MaterialState.selected}), colorScheme.onPrimary);
    expect(m3.yearForegroundColor?.resolve(<MaterialState>{MaterialState.disabled}), colorScheme.onSurfaceVariant.withOpacity(0.38));
    expect(m3.yearBackgroundColor?.resolve(<MaterialState>{}), null);
    expect(m3.yearBackgroundColor?.resolve(<MaterialState>{MaterialState.selected}), colorScheme.primary);
    expect(m3.yearOverlayColor?.resolve(<MaterialState>{}), null);
    expect(m3.yearOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.hovered}), colorScheme.onPrimary.withOpacity(0.08));
    expect(m3.yearOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.focused}), colorScheme.onPrimary.withOpacity(0.12));
    expect(m3.yearOverlayColor?.resolve(<MaterialState>{MaterialState.hovered}), colorScheme.onSurfaceVariant.withOpacity(0.08));
    expect(m3.yearOverlayColor?.resolve(<MaterialState>{MaterialState.focused}), colorScheme.onSurfaceVariant.withOpacity(0.12));
    expect(m3.yearOverlayColor?.resolve(<MaterialState>{MaterialState.pressed}), colorScheme.onSurfaceVariant.withOpacity(0.12));
    expect(m3.rangePickerElevation, 0);
    expect(m3.rangePickerShape, const RoundedRectangleBorder());
    expect(m3.rangePickerShadowColor, Colors.transparent);
    expect(m3.rangePickerSurfaceTintColor, Colors.transparent);
    expect(m3.rangeSelectionOverlayColor?.resolve(<MaterialState>{}), null);
    expect(m3.rangePickerHeaderBackgroundColor, Colors.transparent);
    expect(m3.rangePickerHeaderForegroundColor, colorScheme.onSurfaceVariant);
    expect(m3.rangePickerHeaderHeadlineStyle, textTheme.titleLarge);
    expect(m3.rangePickerHeaderHelpStyle, textTheme.titleSmall);
  });


  testWidgets('DatePickerTheme.defaults M2 defaults', (WidgetTester tester) async {
    late final DatePickerThemeData m2; // M2 defaults
    late final ThemeData theme;
    late final ColorScheme colorScheme;
    late final TextTheme textTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: false),
        home: Builder(
          builder: (BuildContext context) {
            m2 = DatePickerTheme.defaults(context);
            theme = Theme.of(context);
            colorScheme = theme.colorScheme;
            textTheme = theme.textTheme;
            return Container();
          },
        ),
      ),
    );

    expect(m2.elevation, 24);
    expect(m2.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));
    expect(m2.headerBackgroundColor, colorScheme.primary);
    expect(m2.headerForegroundColor, colorScheme.onPrimary);
    expect(m2.headerHeadlineStyle, textTheme.headlineSmall);
    expect(m2.headerHelpStyle, textTheme.labelSmall);
    expect(m2.weekdayStyle, textTheme.bodySmall?.apply(color: colorScheme.onSurface.withOpacity(0.60)));
    expect(m2.dayStyle, textTheme.bodySmall);
    expect(m2.dayForegroundColor?.resolve(<MaterialState>{}), colorScheme.onSurface);
    expect(m2.dayForegroundColor?.resolve(<MaterialState>{MaterialState.selected}), colorScheme.onPrimary);
    expect(m2.dayForegroundColor?.resolve(<MaterialState>{MaterialState.disabled}), colorScheme.onSurface.withOpacity(0.38));
    expect(m2.dayBackgroundColor?.resolve(<MaterialState>{}), null);
    expect(m2.dayBackgroundColor?.resolve(<MaterialState>{MaterialState.selected}), colorScheme.primary);
    expect(m2.dayOverlayColor?.resolve(<MaterialState>{}), null);
    expect(m2.dayOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.hovered}), colorScheme.onPrimary.withOpacity(0.08));
    expect(m2.dayOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.focused}), colorScheme.onPrimary.withOpacity(0.12));
    expect(m2.dayOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.pressed}), colorScheme.onPrimary.withOpacity(0.38));
    expect(m2.dayOverlayColor?.resolve(<MaterialState>{MaterialState.hovered}), colorScheme.onSurfaceVariant.withOpacity(0.08));
    expect(m2.dayOverlayColor?.resolve(<MaterialState>{MaterialState.focused}), colorScheme.onSurfaceVariant.withOpacity(0.12));
    expect(m2.dayOverlayColor?.resolve(<MaterialState>{MaterialState.pressed}), colorScheme.onSurfaceVariant.withOpacity(0.12));
    expect(m2.todayForegroundColor?.resolve(<MaterialState>{}), colorScheme.primary);
    expect(m2.todayForegroundColor?.resolve(<MaterialState>{MaterialState.disabled}), colorScheme.onSurface.withOpacity(0.38));
    expect(m2.todayBorder, BorderSide(color: colorScheme.primary));
    expect(m2.yearStyle, textTheme.bodyLarge);
    expect(m2.rangePickerBackgroundColor, colorScheme.surface);
    expect(m2.rangePickerElevation, 0);
    expect(m2.rangePickerShape, const RoundedRectangleBorder());
    expect(m2.rangePickerShadowColor, Colors.transparent);
    expect(m2.rangePickerSurfaceTintColor, Colors.transparent);
    expect(m2.rangeSelectionOverlayColor?.resolve(<MaterialState>{}), null);
    expect(m2.rangeSelectionOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.hovered}), colorScheme.onPrimary.withOpacity(0.08));
    expect(m2.rangeSelectionOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.focused}), colorScheme.onPrimary.withOpacity(0.12));
    expect(m2.rangeSelectionOverlayColor?.resolve(<MaterialState>{MaterialState.selected, MaterialState.pressed}), colorScheme.onPrimary.withOpacity(0.38));
    expect(m2.rangeSelectionOverlayColor?.resolve(<MaterialState>{MaterialState.hovered}), colorScheme.onSurfaceVariant.withOpacity(0.08));
    expect(m2.rangeSelectionOverlayColor?.resolve(<MaterialState>{MaterialState.focused}), colorScheme.onSurfaceVariant.withOpacity(0.12));
    expect(m2.rangeSelectionOverlayColor?.resolve(<MaterialState>{MaterialState.pressed}), colorScheme.onSurfaceVariant.withOpacity(0.12));
    expect(m2.rangePickerHeaderBackgroundColor, colorScheme.primary);
    expect(m2.rangePickerHeaderForegroundColor, colorScheme.onPrimary);
    expect(m2.rangePickerHeaderHeadlineStyle, textTheme.headlineSmall);
    expect(m2.rangePickerHeaderHelpStyle, textTheme.labelSmall);
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

    datePickerTheme.debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'backgroundColor: Color(0xfffffff0)',
      'elevation: 6.0',
      'shadowColor: Color(0xfffffff1)',
      'surfaceTintColor: Color(0xfffffff2)',
      'shape: RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.zero)',
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
      'todayBorder: BorderSide(width: 3.0)',
      'yearStyle: TextStyle(inherit: true, size: 13.0)',
      'yearForegroundColor: MaterialStatePropertyAll(Color(0xfffffffa))',
      'yearBackgroundColor: MaterialStatePropertyAll(Color(0xfffffffb))',
      'yearOverlayColor: MaterialStatePropertyAll(Color(0xfffffffc))',
      'rangePickerBackgroundColor: Color(0xfffffffd)',
      'rangePickerElevation: 7.0',
      'rangePickerShadowColor: Color(0xfffffffe)',
      'rangePickerSurfaceTintColor: Color(0xffffffff)',
      'rangePickerShape: RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.zero)',
      'rangePickerHeaderBackgroundColor: Color(0xffffff0f)',
      'rangePickerHeaderForegroundColor: Color(0xffffff1f)',
      'rangePickerHeaderHeadlineStyle: TextStyle(inherit: true, size: 14.0)',
      'rangePickerHeaderHelpStyle: TextStyle(inherit: true, size: 15.0)',
      'rangeSelectionBackgroundColor: Color(0xffffff2f)',
      'rangeSelectionOverlayColor: MaterialStatePropertyAll(Color(0xffffff3f))',
    ]);
  });

  testWidgets('DatePickerDialog uses ThemeData datePicker theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true).copyWith(
          datePickerTheme: datePickerTheme,
        ),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: DatePickerDialog(
                initialDate: DateTime(2023, DateTime.january, 25),
                firstDate: DateTime(2022),
                lastDate: DateTime(2024, DateTime.december, 31),
                currentDate: DateTime(2023, DateTime.january, 24),
              ),
            ),
          ),
        ),
      ),
    );

    final Material material = findDialogMaterial(tester);
    expect(material.color, datePickerTheme.backgroundColor);
    expect(material.elevation, datePickerTheme.elevation);
    expect(material.shadowColor, datePickerTheme.shadowColor);
    expect(material.surfaceTintColor, datePickerTheme.surfaceTintColor);
    expect(material.shape, datePickerTheme.shape);

    final Text selectDate = tester.widget<Text>(find.text('Select date'));
    final Material headerMaterial = findHeaderMaterial(tester, 'Select date');
    expect(selectDate.style?.color, datePickerTheme.headerForegroundColor);
    expect(selectDate.style?.fontSize, datePickerTheme.headerHelpStyle?.fontSize);
    expect(headerMaterial.color, datePickerTheme.headerBackgroundColor);

    final Text weekday = tester.widget<Text>(find.text('W'));
    expect(weekday.style?.color, datePickerTheme.weekdayStyle?.color);
    expect(weekday.style?.fontSize, datePickerTheme.weekdayStyle?.fontSize);

    final Text selectedDate = tester.widget<Text>(find.text('Wed, Jan 25'));
    expect(selectedDate.style?.color, datePickerTheme.headerForegroundColor);
    expect(selectedDate.style?.fontSize, datePickerTheme.headerHeadlineStyle?.fontSize);

    final Text day31 = tester.widget<Text>(find.text('31'));
    final BoxDecoration day31Decoration = findTextDecoration(tester, '31')!;
    expect(day31.style?.color, datePickerTheme.dayForegroundColor?.resolve(<MaterialState>{}));
    expect(day31.style?.fontSize, datePickerTheme.dayStyle?.fontSize);
    expect(day31Decoration.color, datePickerTheme.dayBackgroundColor?.resolve(<MaterialState>{}));

    final Text day24 = tester.widget<Text>(find.text('24')); // DatePickerDialog.currentDate
    final BoxDecoration day24Decoration = findTextDecoration(tester, '24')!;
    expect(day24.style?.fontSize, datePickerTheme.dayStyle?.fontSize);
    expect(day24.style?.color, datePickerTheme.todayForegroundColor?.resolve(<MaterialState>{}));
    expect(day24Decoration.color, datePickerTheme.todayBackgroundColor?.resolve(<MaterialState>{}));
    expect(day24Decoration.border?.top.width, datePickerTheme.todayBorder?.width);
    expect(day24Decoration.border?.bottom.width, datePickerTheme.todayBorder?.width);

    // Show the year selector.

    await tester.tap(find.text('January 2023'));
    await tester.pumpAndSettle();

    final Text year2022 = tester.widget<Text>(find.text('2022'));
    final BoxDecoration year2022Decoration = findTextDecoration(tester, '2022')!;
    expect(year2022.style?.fontSize, datePickerTheme.yearStyle?.fontSize);
    expect(year2022.style?.color, datePickerTheme.yearForegroundColor?.resolve(<MaterialState>{}));
    expect(year2022Decoration.color, datePickerTheme.yearBackgroundColor?.resolve(<MaterialState>{}));

    final Text year2023 = tester.widget<Text>(find.text('2023')); // DatePickerDialog.currentDate
    final BoxDecoration year2023Decoration = findTextDecoration(tester, '2023')!;
    expect(year2023.style?.fontSize, datePickerTheme.yearStyle?.fontSize);
    expect(year2023.style?.color, datePickerTheme.todayForegroundColor?.resolve(<MaterialState>{}));
    expect(year2023Decoration.color, datePickerTheme.todayBackgroundColor?.resolve(<MaterialState>{}));
    expect(year2023Decoration.border?.top.width, datePickerTheme.todayBorder?.width);
    expect(year2023Decoration.border?.bottom.width, datePickerTheme.todayBorder?.width);
    expect(year2023Decoration.border?.top.color, datePickerTheme.todayForegroundColor?.resolve(<MaterialState>{}));
    expect(year2023Decoration.border?.bottom.color, datePickerTheme.todayForegroundColor?.resolve(<MaterialState>{}));
  });


  testWidgets('DateRangePickerDialog uses ThemeData datePicker theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true).copyWith(
          datePickerTheme: datePickerTheme,
        ),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: DateRangePickerDialog(
                firstDate: DateTime(2023),
                lastDate: DateTime(2023, DateTime.january, 31),
                initialDateRange: DateTimeRange(
                  start: DateTime(2023, DateTime.january, 17),
                  end: DateTime(2023, DateTime.january, 20),
                ),
                currentDate: DateTime(2023, DateTime.january, 23),
              ),
            ),
          ),
        ),
      ),
    );

    final Material material = findDialogMaterial(tester);
    expect(material.color, datePickerTheme.backgroundColor); //!!
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, datePickerTheme.rangePickerBackgroundColor);
    expect(material.elevation, datePickerTheme.rangePickerElevation);
    expect(material.shadowColor, datePickerTheme.rangePickerShadowColor);
    expect(material.surfaceTintColor, datePickerTheme.rangePickerSurfaceTintColor);
    expect(material.shape, datePickerTheme.rangePickerShape);

    final Text selectRange = tester.widget<Text>(find.text('Select range'));
    expect(selectRange.style?.color, datePickerTheme.rangePickerHeaderForegroundColor);
    expect(selectRange.style?.fontSize, datePickerTheme.rangePickerHeaderHelpStyle?.fontSize);

    final Text selectedDate = tester.widget<Text>(find.text('Jan 17'));
    expect(selectedDate.style?.color, datePickerTheme.rangePickerHeaderForegroundColor);
    expect(selectedDate.style?.fontSize, datePickerTheme.rangePickerHeaderHeadlineStyle?.fontSize);
  });
}
