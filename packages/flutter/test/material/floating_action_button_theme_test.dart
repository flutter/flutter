import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FloatingActionButtonThemeData copyWith, ==, hashCode basics', () {
    expect(const FloatingActionButtonThemeData(), const FloatingActionButtonThemeData().copyWith());
    expect(const FloatingActionButtonThemeData().hashCode, const FloatingActionButtonThemeData().copyWith().hashCode);
  });

  testWidgets('Default values are used when no FloatingActionButton or FloatingActionButtonThemeData properties are specified', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(onPressed: () { }),
      ),
    ));

    final Material widget = _getFloatingActionButtonMaterial(tester);

    expect(widget.color, ThemeData().accentColor);
    expect(widget.elevation, 6.0);
    expect(widget.shape, CircleBorder());
  });

  testWidgets('FloatingActionButtonThemeData values are used when no widget properties are specified', (WidgetTester tester) async {

  });

  testWidgets('FloatingActionButton values take priority over FloatingActionButtonThemeData', (WidgetTester tester) async {

  });

  testWidgets('FloatingActionButton foreground color uses iconAccentTheme if no widget or widget theme color is specified', (WidgetTester tester) async {

  });
}

Material _getFloatingActionButtonMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byType(Material),
    ),
  );
}