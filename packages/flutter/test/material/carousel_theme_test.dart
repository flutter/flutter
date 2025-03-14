// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CarouselViewThemeData copyWith, ==, hashCode basics', () {
    expect(const CarouselViewThemeData(), const CarouselViewThemeData().copyWith());
    expect(
      const CarouselViewThemeData().hashCode,
      const CarouselViewThemeData().copyWith().hashCode,
    );
  });

  test('CarouselViewThemeData null fields by default', () {
    const CarouselViewThemeData carouselViewTheme = CarouselViewThemeData();
    expect(carouselViewTheme.backgroundColor, null);
    expect(carouselViewTheme.elevation, null);
    expect(carouselViewTheme.overlayColor, null);
    expect(carouselViewTheme.padding, null);
    expect(carouselViewTheme.shape, null);
  });

  testWidgets('Default DividerThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const CarouselViewThemeData().debugFillProperties(builder);

    final List<String> description =
        builder.properties
            .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
            .map((DiagnosticsNode node) => node.toString())
            .toList();

    expect(description, <String>[]);
  });

  testWidgets('CarouselViewThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const CarouselViewThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      elevation: 5.0,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(),
      overlayColor: MaterialStatePropertyAll<Color>(Colors.red),
    ).debugFillProperties(builder);

    final List<String> description =
        builder.properties
            .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
            .map((DiagnosticsNode node) => node.toString())
            .toList();

    expect(description, <String>[
      'backgroundColor: ${const Color(0xffffffff)}',
      'elevation: 5.0',
      'shape: RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.zero)',
      'overlayColor: WidgetStatePropertyAll(${Colors.red})',
      'padding: EdgeInsets.zero',
    ]);
  });

  testWidgets('Uses value from CarouselViewThemeData', (WidgetTester tester) async {
    final CarouselViewThemeData carouselViewTheme = _carouselViewThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(carouselViewTheme: carouselViewTheme),
        home: const Scaffold(
          body: Center(
            child: CarouselView(
              itemExtent: 100,
              children: <Widget>[SizedBox(width: 100, height: 100)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CarouselView), findsOneWidget);

    final Finder padding = find.descendant(
      of: find.byType(CarouselView),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is Padding && widget.child is Material,
      ),
    );

    expect(padding, findsOneWidget);
    final Padding paddingWidget = tester.widget<Padding>(padding);
    final Material material = paddingWidget.child! as Material;

    final InkWell inkWell = tester.widget<InkWell>(
      find.descendant(of: find.byType(CarouselView), matching: find.byType(InkWell)),
    );

    expect(paddingWidget.padding, carouselViewTheme.padding);
    expect(material.color, carouselViewTheme.backgroundColor);
    expect(material.elevation, carouselViewTheme.elevation);
    expect(material.shape, carouselViewTheme.shape);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.antiAlias);
    expect(inkWell.overlayColor, carouselViewTheme.overlayColor);
  });

  testWidgets('CarouselViewTheme overrides defaults', (WidgetTester tester) async {
    final CarouselViewThemeData carouselViewTheme = _carouselViewThemeData();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CarouselViewTheme(
              data: carouselViewTheme,
              child: const CarouselView(
                itemExtent: 100,
                children: <Widget>[SizedBox(width: 100, height: 100)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CarouselView), findsOneWidget);

    final Finder padding = find.descendant(
      of: find.byType(CarouselView),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is Padding && widget.child is Material,
      ),
    );

    expect(padding, findsOneWidget);
    final Padding paddingWidget = tester.widget<Padding>(padding);
    final Material material = paddingWidget.child! as Material;

    final InkWell inkWell = tester.widget<InkWell>(
      find.descendant(of: find.byType(CarouselView), matching: find.byType(InkWell)),
    );

    expect(paddingWidget.padding, carouselViewTheme.padding);
    expect(material.color, carouselViewTheme.backgroundColor);
    expect(material.elevation, carouselViewTheme.elevation);
    expect(material.shape, carouselViewTheme.shape);
    expect(inkWell.overlayColor, carouselViewTheme.overlayColor);
  });

  testWidgets('Widgets properties override theme', (WidgetTester tester) async {
    final CarouselViewThemeData carouselViewTheme = _carouselViewThemeData();
    const Color backgroundColor = Color(0xFFFF0000);
    const double elevation = 10.0;
    const EdgeInsets padding = EdgeInsets.all(15.0);
    const OutlinedBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
    const WidgetStateProperty<Color?> overlayColor = MaterialStatePropertyAll<Color>(Colors.green);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(carouselViewTheme: carouselViewTheme),
        home: const Scaffold(
          body: Center(
            child: CarouselView(
              backgroundColor: backgroundColor,
              elevation: elevation,
              padding: padding,
              shape: shape,
              overlayColor: overlayColor,
              itemExtent: 100,
              children: <Widget>[SizedBox(width: 100, height: 100)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CarouselView), findsOneWidget);

    final Finder paddingFinder = find.descendant(
      of: find.byType(CarouselView),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is Padding && widget.child is Material,
      ),
    );

    expect(paddingFinder, findsOneWidget);
    final Padding paddingWidget = tester.widget<Padding>(paddingFinder);
    final Material material = paddingWidget.child! as Material;

    final InkWell inkWell = tester.widget<InkWell>(
      find.descendant(of: find.byType(CarouselView), matching: find.byType(InkWell)),
    );

    expect(paddingWidget.padding, padding);
    expect(material.color, backgroundColor);
    expect(material.elevation, elevation);
    expect(material.shape, shape);
    expect(inkWell.overlayColor, overlayColor);
  });
}

CarouselViewThemeData _carouselViewThemeData() {
  const Color backgroundColor = Color(0xFF0000FF);
  const double elevation = 5.0;
  const EdgeInsets padding = EdgeInsets.all(10.0);
  const OutlinedBorder shape = RoundedRectangleBorder();
  const WidgetStateProperty<Color?> overlayColor = MaterialStatePropertyAll<Color>(Colors.red);

  return const CarouselViewThemeData(
    backgroundColor: backgroundColor,
    elevation: elevation,
    padding: padding,
    shape: shape,
    overlayColor: overlayColor,
  );
}
