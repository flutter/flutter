// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('TimePickerThemeData copyWith, ==, hashCode basics', () {
    expect(const TimePickerThemeData(), const TimePickerThemeData().copyWith());
    expect(const TimePickerThemeData().hashCode, const TimePickerThemeData().copyWith().hashCode);
  });

  test('TimePickerThemeData null fields by default', () {
    const TimePickerThemeData timePickerTheme = TimePickerThemeData();
    expect(timePickerTheme.backgroundColor, null);
    expect(timePickerTheme.hourMinuteTextColor, null);
    expect(timePickerTheme.hourMinuteColor, null);
    expect(timePickerTheme.dayPeriodTextColor, null);
    expect(timePickerTheme.dayPeriodColor, null);
    expect(timePickerTheme.dialHandColor, null);
    expect(timePickerTheme.dialBackgroundColor, null);
    expect(timePickerTheme.dialTextColor, null);
    expect(timePickerTheme.entryModeIconColor, null);
    expect(timePickerTheme.hourMinuteTextStyle, null);
    expect(timePickerTheme.dayPeriodTextStyle, null);
    expect(timePickerTheme.helpTextStyle, null);
    expect(timePickerTheme.shape, null);
    expect(timePickerTheme.hourMinuteShape, null);
    expect(timePickerTheme.dayPeriodShape, null);
    expect(timePickerTheme.dayPeriodBorderSide, null);
    expect(timePickerTheme.inputDecorationTheme, null);
  });

  testWidgets('Default TimePickerThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const TimePickerThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('TimePickerThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const TimePickerThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      hourMinuteTextColor: Color(0xFFFFFFFF),
      hourMinuteColor: Color(0xFFFFFFFF),
      dayPeriodTextColor: Color(0xFFFFFFFF),
      dayPeriodColor: Color(0xFFFFFFFF),
      dialHandColor: Color(0xFFFFFFFF),
      dialBackgroundColor: Color(0xFFFFFFFF),
      dialTextColor: Color(0xFFFFFFFF),
      entryModeIconColor: Color(0xFFFFFFFF),
      hourMinuteTextStyle: TextStyle(),
      dayPeriodTextStyle: TextStyle(),
      helpTextStyle: TextStyle(),
      shape: RoundedRectangleBorder(),
      hourMinuteShape: RoundedRectangleBorder(),
      dayPeriodShape: RoundedRectangleBorder(),
      dayPeriodBorderSide: BorderSide(),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'backgroundColor: Color(0xffffffff)',
      'hourMinuteTextColor: Color(0xffffffff)',
      'hourMinuteColor: Color(0xffffffff)',
      'dayPeriodTextColor: Color(0xffffffff)',
      'dayPeriodColor: Color(0xffffffff)',
      'dialHandColor: Color(0xffffffff)',
      'dialBackgroundColor: Color(0xffffffff)',
      'dialTextColor: Color(0xffffffff)',
      'entryModeIconColor: Color(0xffffffff)',
      'hourMinuteTextStyle: TextStyle(<all styles inherited>)',
      'dayPeriodTextStyle: TextStyle(<all styles inherited>)',
      'helpTextStyle: TextStyle(<all styles inherited>)',
      'shape: RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero)',
      'hourMinuteShape: RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero)',
      'dayPeriodShape: RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero)',
      'dayPeriodBorderSide: BorderSide(Color(0xff000000), 1.0, BorderStyle.solid)',
    ]);
  });

  testWidgets('Passing no TimePickerThemeData uses defaults', (WidgetTester tester) async {
    final ThemeData defaultTheme = ThemeData.fallback();
    await tester.pumpWidget(const _TimePickerLauncher());
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final Material dialogMaterial = _dialogMaterial(tester);
    expect(dialogMaterial.color, defaultTheme.colorScheme.surface);
    expect(dialogMaterial.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    final RenderBox dial = tester.firstRenderObject<RenderBox>(find.byType(CustomPaint));
    expect(
      dial,
      paints
        ..circle(color: defaultTheme.colorScheme.onBackground.withOpacity(0.12)) // Dial background color.
        ..circle(color: Color(defaultTheme.colorScheme.primary.value)), // Dial hand color.
    );

    final RenderParagraph hourText = _textRenderParagraph(tester, '7');
    expect(
      hourText.text.style,
      Typography.material2014().englishLike.headline2!
          .merge(Typography.material2014().black.headline2)
          .copyWith(color: defaultTheme.colorScheme.primary),
    );

    final RenderParagraph minuteText = _textRenderParagraph(tester, '15');
    expect(
      minuteText.text.style,
      Typography.material2014().englishLike.headline2!
          .merge(Typography.material2014().black.headline2)
          .copyWith(color: defaultTheme.colorScheme.onSurface),
    );

    final RenderParagraph amText = _textRenderParagraph(tester, 'AM');
    expect(
      amText.text.style,
      Typography.material2014().englishLike.subtitle1!
          .merge(Typography.material2014().black.subtitle1)
          .copyWith(color: defaultTheme.colorScheme.primary),
    );

    final RenderParagraph pmText = _textRenderParagraph(tester, 'PM');
    expect(
      pmText.text.style,
      Typography.material2014().englishLike.subtitle1!
          .merge(Typography.material2014().black.subtitle1)
          .copyWith(color: defaultTheme.colorScheme.onSurface.withOpacity(0.6)),
    );

    final RenderParagraph helperText = _textRenderParagraph(tester, 'SELECT TIME');
    expect(
      helperText.text.style,
      Typography.material2014().englishLike.overline!
          .merge(Typography.material2014().black.overline),
    );

    final CustomPaint dialPaint = tester.widget(findDialPaint);
    final dynamic dialPainter = dialPaint.painter;
    final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
    expect(
      primaryLabels.first.painter.text.style,
      Typography.material2014().englishLike.bodyText1!
        .merge(Typography.material2014().black.bodyText1)
        .copyWith(color: defaultTheme.colorScheme.onSurface),
    );
    final List<dynamic> secondaryLabels = dialPainter.secondaryLabels as List<dynamic>;
    expect(
      secondaryLabels.first.painter.text.style,
      Typography.material2014().englishLike.bodyText1!
        .merge(Typography.material2014().white.bodyText1)
        .copyWith(color: defaultTheme.colorScheme.onPrimary),
    );

    final Material hourMaterial = _textMaterial(tester, '7');
    expect(hourMaterial.color, defaultTheme.colorScheme.primary.withOpacity(0.12));
    expect(hourMaterial.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    final Material minuteMaterial = _textMaterial(tester, '15');
    expect(minuteMaterial.color, defaultTheme.colorScheme.onSurface.withOpacity(0.12));
    expect(minuteMaterial.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    final Material amMaterial = _textMaterial(tester, 'AM');
    expect(amMaterial.color, defaultTheme.colorScheme.primary.withOpacity(0.12));

    final Material pmMaterial = _textMaterial(tester, 'PM');
    expect(pmMaterial.color, Colors.transparent);

    final Color expectedBorderColor = Color.alphaBlend(
      defaultTheme.colorScheme.onBackground.withOpacity(0.38),
      defaultTheme.colorScheme.surface,
    );
    final Material dayPeriodMaterial = _dayPeriodMaterial(tester);
    expect(
      dayPeriodMaterial.shape,
      RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        side: BorderSide(color: expectedBorderColor),
      ),
    );

    final Container dayPeriodDivider = _dayPeriodDivider(tester);
    expect(
      dayPeriodDivider.decoration,
      BoxDecoration(border: Border(left: BorderSide(color: expectedBorderColor))),
    );

    final IconButton entryModeIconButton = _entryModeIconButton(tester);
    expect(
      entryModeIconButton.color,
      defaultTheme.colorScheme.onSurface.withOpacity(0.6),
    );
  });


  testWidgets('Passing no TimePickerThemeData uses defaults - input mode', (WidgetTester tester) async {
    final ThemeData defaultTheme = ThemeData.fallback();
    await tester.pumpWidget(const _TimePickerLauncher(entryMode: TimePickerEntryMode.input));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final InputDecoration hourDecoration = _textField(tester, '7').decoration!;
    expect(hourDecoration.filled, true);
    expect(hourDecoration.fillColor, defaultTheme.colorScheme.onSurface.withOpacity(0.12));
    expect(hourDecoration.enabledBorder, const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)));
    expect(hourDecoration.errorBorder, OutlineInputBorder(borderSide: BorderSide(color: defaultTheme.colorScheme.error, width: 2)));
    expect(hourDecoration.focusedBorder, OutlineInputBorder(borderSide: BorderSide(color: defaultTheme.colorScheme.primary, width: 2)));
    expect(hourDecoration.focusedErrorBorder, OutlineInputBorder(borderSide: BorderSide(color: defaultTheme.colorScheme.error, width: 2)));
    expect(
      hourDecoration.hintStyle,
      Typography.material2014().englishLike.headline2!
          .merge(defaultTheme.textTheme.headline2!.copyWith(color: defaultTheme.colorScheme.onSurface.withOpacity(0.36))),
    );
  });

  testWidgets('Time picker uses values from TimePickerThemeData', (WidgetTester tester) async {
    final TimePickerThemeData timePickerTheme = _timePickerTheme();
    final ThemeData theme = ThemeData(timePickerTheme: timePickerTheme);
    await tester.pumpWidget(_TimePickerLauncher(themeData: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final Material dialogMaterial = _dialogMaterial(tester);
    expect(dialogMaterial.color, timePickerTheme.backgroundColor);
    expect(dialogMaterial.shape, timePickerTheme.shape);

    final RenderBox dial = tester.firstRenderObject<RenderBox>(find.byType(CustomPaint));
    expect(
      dial,
      paints
        ..circle(color: Color(timePickerTheme.dialBackgroundColor!.value)) // Dial background color.
        ..circle(color: Color(timePickerTheme.dialHandColor!.value)), // Dial hand color.
    );

    final RenderParagraph hourText = _textRenderParagraph(tester, '7');
    expect(
      hourText.text.style,
      Typography.material2014().englishLike.bodyText2!
          .merge(Typography.material2014().black.bodyText2)
          .merge(timePickerTheme.hourMinuteTextStyle)
          .copyWith(color: _selectedColor),
    );

    final RenderParagraph minuteText = _textRenderParagraph(tester, '15');
    expect(
      minuteText.text.style,
      Typography.material2014().englishLike.bodyText2!
          .merge(Typography.material2014().black.bodyText2)
          .merge(timePickerTheme.hourMinuteTextStyle)
          .copyWith(color: _unselectedColor),
    );

    final RenderParagraph amText = _textRenderParagraph(tester, 'AM');
    expect(
      amText.text.style,
      Typography.material2014().englishLike.subtitle1!
          .merge(Typography.material2014().black.subtitle1)
          .merge(timePickerTheme.dayPeriodTextStyle)
          .copyWith(color: _selectedColor),
    );

    final RenderParagraph pmText = _textRenderParagraph(tester, 'PM');
    expect(
      pmText.text.style,
      Typography.material2014().englishLike.subtitle1!
          .merge(Typography.material2014().black.subtitle1)
          .merge(timePickerTheme.dayPeriodTextStyle)
          .copyWith(color: _unselectedColor),
    );

    final RenderParagraph helperText = _textRenderParagraph(tester, 'SELECT TIME');
    expect(
      helperText.text.style,
      Typography.material2014().englishLike.bodyText2!
          .merge(Typography.material2014().black.bodyText2)
          .merge(timePickerTheme.helpTextStyle),
    );

    final CustomPaint dialPaint = tester.widget(findDialPaint);
    final dynamic dialPainter = dialPaint.painter;
    final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
    expect(
      primaryLabels.first.painter.text.style,
      Typography.material2014().englishLike.bodyText1!
          .merge(Typography.material2014().black.bodyText1)
          .copyWith(color: _unselectedColor),
    );
    final List<dynamic> secondaryLabels = dialPainter.secondaryLabels as List<dynamic>;
    expect(
      secondaryLabels.first.painter.text.style,
      Typography.material2014().englishLike.bodyText1!
          .merge(Typography.material2014().white.bodyText1)
          .copyWith(color: _selectedColor),
    );

    final Material hourMaterial = _textMaterial(tester, '7');
    expect(hourMaterial.color, _selectedColor);
    expect(hourMaterial.shape, timePickerTheme.hourMinuteShape);

    final Material minuteMaterial = _textMaterial(tester, '15');
    expect(minuteMaterial.color, _unselectedColor);
    expect(minuteMaterial.shape, timePickerTheme.hourMinuteShape);

    final Material amMaterial = _textMaterial(tester, 'AM');
    expect(amMaterial.color, _selectedColor);

    final Material pmMaterial = _textMaterial(tester, 'PM');
    expect(pmMaterial.color, _unselectedColor);

    final Material dayPeriodMaterial = _dayPeriodMaterial(tester);
    expect(
      dayPeriodMaterial.shape,
      timePickerTheme.dayPeriodShape!.copyWith(side: timePickerTheme.dayPeriodBorderSide),
    );

    final Container dayPeriodDivider = _dayPeriodDivider(tester);
    expect(
      dayPeriodDivider.decoration,
      BoxDecoration(border: Border(left: timePickerTheme.dayPeriodBorderSide!)),
    );

    final IconButton entryModeIconButton = _entryModeIconButton(tester);
    expect(
      entryModeIconButton.color,
      timePickerTheme.entryModeIconColor,
    );
  });

  testWidgets('Time picker uses values from TimePickerThemeData with InputDecorationTheme - input mode', (WidgetTester tester) async {
    final TimePickerThemeData timePickerTheme = _timePickerTheme(includeInputDecoration: true);
    final ThemeData theme = ThemeData(timePickerTheme: timePickerTheme);
    await tester.pumpWidget(_TimePickerLauncher(themeData: theme, entryMode: TimePickerEntryMode.input));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final InputDecoration hourDecoration = _textField(tester, '7').decoration!;
    expect(hourDecoration.filled, timePickerTheme.inputDecorationTheme!.filled);
    expect(hourDecoration.fillColor, timePickerTheme.inputDecorationTheme!.fillColor);
    expect(hourDecoration.enabledBorder, timePickerTheme.inputDecorationTheme!.enabledBorder);
    expect(hourDecoration.errorBorder, timePickerTheme.inputDecorationTheme!.errorBorder);
    expect(hourDecoration.focusedBorder, timePickerTheme.inputDecorationTheme!.focusedBorder);
    expect(hourDecoration.focusedErrorBorder, timePickerTheme.inputDecorationTheme!.focusedErrorBorder);
    expect(hourDecoration.hintStyle, timePickerTheme.inputDecorationTheme!.hintStyle);
  });

  testWidgets('Time picker uses values from TimePickerThemeData without InputDecorationTheme - input mode', (WidgetTester tester) async {
    final TimePickerThemeData timePickerTheme = _timePickerTheme();
    final ThemeData theme = ThemeData(timePickerTheme: timePickerTheme);
    await tester.pumpWidget(_TimePickerLauncher(themeData: theme, entryMode: TimePickerEntryMode.input));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final InputDecoration hourDecoration = _textField(tester, '7').decoration!;
    expect(hourDecoration.fillColor, timePickerTheme.hourMinuteColor);
  });
}

final Color _selectedColor = Colors.green[100]!;
final Color _unselectedColor = Colors.green[200]!;

TimePickerThemeData _timePickerTheme({bool includeInputDecoration = false}) {
  Color getColor(Set<MaterialState> states) {
    return states.contains(MaterialState.selected) ? _selectedColor : _unselectedColor;
  }
  final MaterialStateColor materialStateColor = MaterialStateColor.resolveWith(getColor);
  return TimePickerThemeData(
    backgroundColor: Colors.orange,
    hourMinuteTextColor: materialStateColor,
    hourMinuteColor: materialStateColor,
    dayPeriodTextColor: materialStateColor,
    dayPeriodColor: materialStateColor,
    dialHandColor: Colors.brown,
    dialBackgroundColor: Colors.pinkAccent,
    dialTextColor: materialStateColor,
    entryModeIconColor: Colors.red,
    hourMinuteTextStyle: const TextStyle(fontSize: 8.0),
    dayPeriodTextStyle: const TextStyle(fontSize: 8.0),
    helpTextStyle: const TextStyle(fontSize: 8.0),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
    hourMinuteShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
    dayPeriodShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
    dayPeriodBorderSide: const BorderSide(color: Colors.blueAccent),
    inputDecorationTheme: includeInputDecoration ? const InputDecorationTheme(
      filled: true,
      fillColor: Colors.purple,
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
      errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
      focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
      hintStyle: TextStyle(fontSize: 8),
    ) : null,
  );
}

class _TimePickerLauncher extends StatelessWidget {
  const _TimePickerLauncher({
    Key? key,
    this.themeData,
    this.entryMode = TimePickerEntryMode.dial,
  }) : super(key: key);

  final ThemeData? themeData;
  final TimePickerEntryMode entryMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeData,
      home: Material(
        child: Center(
          child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  child: const Text('X'),
                  onPressed: () async {
                    await showTimePicker(
                      context: context,
                      initialEntryMode: entryMode,
                      initialTime: const TimeOfDay(hour: 7, minute: 15),
                    );
                  },
                );
              }
          ),
        ),
      ),
    );
  }
}

Material _dialogMaterial(WidgetTester tester) {
  return tester.widget<Material>(find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first);
}

Material _textMaterial(WidgetTester tester, String text) {
  return tester.widget<Material>(find.ancestor(of: find.text(text), matching: find.byType(Material)).first);
}

TextField _textField(WidgetTester tester, String text) {
  return tester.widget<TextField>(find.ancestor(of: find.text(text), matching: find.byType(TextField)).first);
}

Material _dayPeriodMaterial(WidgetTester tester) {
  return tester.widget<Material>(find.descendant(of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodControl'), matching: find.byType(Material)).first);
}

Container _dayPeriodDivider(WidgetTester tester) {
  return tester.widget<Container>(find.descendant(of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodControl'), matching: find.byType(Container)).at(0));
}

IconButton _entryModeIconButton(WidgetTester tester) {
  return tester.widget<IconButton>(find.descendant(of: find.byType(Dialog), matching: find.byType(IconButton)).first);
}

RenderParagraph _textRenderParagraph(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(find.text(text).first).renderObject! as RenderParagraph;
}

final Finder findDialPaint = find.descendant(
  of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_Dial'),
  matching: find.byWidgetPredicate((Widget w) => w is CustomPaint),
);
