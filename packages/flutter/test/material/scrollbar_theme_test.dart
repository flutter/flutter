// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('ScrollbarTheme copyWith, ==, hashCode basics', () {
    expect(const ScrollbarTheme(), const ScrollbarTheme().copyWith());
    expect(const ScrollbarTheme().hashCode, const ScrollbarTheme().copyWith().hashCode);
  });

  testWidgets('Passing no ScrollbarTheme returns defaults', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scrollbar(
          isAlwaysShown: true,
          showTrackOnHover: true,
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(width: 4000.0, height: 4000.0)
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Idle scrollbar behavior
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(790.0, 0.0, 798.0, 90.0),
          const Radius.circular(8.0),
        ),
        color: const Color(0x1a000000),
      ),
    );

    // Drag scrollbar behavior
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(790.0, 0.0, 798.0, 90.0),
          const Radius.circular(8.0),
        ),
        // Drag color
        color: const Color(0x99000000),
      ),
    );

    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // Hover scrollbar behavior
    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(const Offset(794.0, 5.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(784.0, 0.0, 800.0, 600.0),
          color: const Color(0x08000000),
        )
        ..line(
          p1: const Offset(784.0, 0.0),
          p2: const Offset(784.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x1a000000),
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            // Scrollbar thumb is larger
            const Rect.fromLTRB(786.0, 10.0, 798.0, 100.0),
            const Radius.circular(8.0),
          ),
          // Hover color
          color: const Color(0x80000000),
        ),
    );
  });

  testWidgets('Scrollbar uses values from ScrollbarTheme', (WidgetTester tester) async {
    final ScrollbarTheme scrollbarTheme = _scrollbarTheme();
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(scrollbarTheme: scrollbarTheme),
      home: Scrollbar(
        isAlwaysShown: true,
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: const SizedBox(width: 4000.0, height: 4000.0)
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // Idle scrollbar behavior
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(787.0, 10.0, 795.0, 97.0),
          const Radius.circular(6.0),
        ),
        color: const Color(0xff4caf50),
      ),
    );

    // Drag scrollbar behavior
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(787.0, 10.0, 795.0, 97.0),
          const Radius.circular(6.0),
        ),
        // Drag color
        color: const Color(0xfff44336),
      ),
    );

    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // Hover scrollbar behavior
    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(const Offset(794.0, 5.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(770.0, 0.0, 800.0, 580.0),
          color: const Color(0xff000000),
        )
        ..line(
          p1: const Offset(770.0, 0.0),
          p2: const Offset(770.0, 580.0),
          strokeWidth: 1.0,
          color: const Color(0xffffeb3b),
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            // Scrollbar thumb is larger
            const Rect.fromLTRB(775.0, 20.0, 795.0, 107.0),
            const Radius.circular(6.0),
          ),
          // Hover color
          color: const Color(0xff2196f3),
        ),
    );
  });

  testWidgets('Scrollbar widget properties take priority over theme', (WidgetTester tester) async {
    const double thickness = 4.0;
    const double hoverThickness = 4.0;
    const bool showTrackOnHover = true;
    const Radius radius = Radius.circular(3.0);
    final ScrollController scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light()),
        home: Scrollbar(
          thickness: thickness,
          hoverThickness: hoverThickness,
          isAlwaysShown: true,
          showTrackOnHover: showTrackOnHover,
          radius: radius,
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(width: 4000.0, height: 4000.0)
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    // Idle scrollbar behavior
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(794.0, 0.0, 798.0, 90.0),
          const Radius.circular(3.0),
        ),
        color: const Color(0x1a000000),
      ),
    );

    // Drag scrollbar behavior
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(794.0, 0.0, 798.0, 90.0),
          const Radius.circular(3.0),
        ),
        // Drag color
        color: const Color(0x99000000),
      ),
    );

    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // Hover scrollbar behavior
    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(const Offset(794.0, 5.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(792.0, 0.0, 800.0, 600.0),
          color: const Color(0x08000000),
        )
        ..line(
          p1: const Offset(792.0, 0.0),
          p2: const Offset(792.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x1a000000),
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            // Scrollbar thumb is larger
            const Rect.fromLTRB(794.0, 10.0, 798.0, 100.0),
            const Radius.circular(3.0),
          ),
          // Hover color
          color: const Color(0x80000000),
        ),
    );
  });

  testWidgets('ThemeData colorScheme is used when no ScrollbarTheme is set', (WidgetTester tester) async {
    Widget buildFrame(ThemeData appTheme) {
      final ScrollController scrollController = ScrollController();
      return MaterialApp(
        theme: appTheme,
        home: Scrollbar(
          isAlwaysShown: true,
          showTrackOnHover: true,
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(width: 4000.0, height: 4000.0)
          ),
        )
      );
    }

    // Scrollbar defaults for light themes:
    // - coloring based on ColorScheme.onSurface
    await tester.pumpWidget(buildFrame(ThemeData.from(colorScheme: const ColorScheme.light())));
    await tester.pumpAndSettle();
    // Idle scrollbar behavior
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(790.0, 0.0, 798.0, 90.0),
          const Radius.circular(8.0),
        ),
        color: const Color(0x1a000000),
      ),
    );

    // Drag scrollbar behavior
    const double scrollAmount = 10.0;
    TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(790.0, 0.0, 798.0, 90.0),
          const Radius.circular(8.0),
        ),
        // Drag color
        color: const Color(0x99000000),
      ),
    );

    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // Hover scrollbar behavior
    final TestGesture hoverGesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await hoverGesture.addPointer();
    addTearDown(hoverGesture.removePointer);
    await hoverGesture.moveTo(const Offset(794.0, 5.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(784.0, 0.0, 800.0, 600.0),
          color: const Color(0x08000000),
        )
        ..line(
          p1: const Offset(784.0, 0.0),
          p2: const Offset(784.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x1a000000),
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            // Scrollbar thumb is larger
            const Rect.fromLTRB(786.0, 10.0, 798.0, 100.0),
            const Radius.circular(8.0),
          ),
          // Hover color
          color: const Color(0x80000000),
        ),
    );

    await hoverGesture.moveTo(const Offset(0.0, 0.0));

    // Scrollbar defaults for dark themes:
    // - coloring slightly different based on ColorScheme.onSurface
    await tester.pumpWidget(buildFrame(ThemeData.from(colorScheme: const ColorScheme.dark())));
    await tester.pumpAndSettle(); // Theme change animation

    // Idle scrollbar behavior
    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(790.0, 10.0, 798.0, 100.0),
          const Radius.circular(8.0),
        ),
        color: const Color(0x4dffffff),
      ),
    );

    // Drag scrollbar behavior
    dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(790.0, 10.0, 798.0, 100.0),
          const Radius.circular(8.0),
        ),
        // Drag color
        color: const Color(0xbfffffff),
      ),
    );

    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // Hover scrollbar behavior
    await hoverGesture.moveTo(const Offset(794.0, 5.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(784.0, 0.0, 800.0, 600.0),
          color: const Color(0x0dffffff),
        )
        ..line(
          p1: const Offset(784.0, 0.0),
          p2: const Offset(784.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x40ffffff),
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            // Scrollbar thumb is larger
            const Rect.fromLTRB(786.0, 20.0, 798.0, 110.0),
            const Radius.circular(8.0),
          ),
          // Hover color
          color: const Color(0xa6ffffff),
        ),
    );
  });

  testWidgets('Default ScrollbarTheme debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ScrollbarTheme().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('ScrollbarTheme implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ScrollbarTheme(
      thickness: 6.0,
      hoverThickness: 12.0,
      showTrackOnHover: true,
      radius: Radius.circular(3.0),
      thumbDragColor: Colors.red,
      thumbHoverColor: Colors.orange,
      thumbIdleColor: Colors.yellow,
      trackColor: Colors.green,
      trackBorderColor: Colors.blue,
      crossAxisMargin: 3.0,
      mainAxisMargin: 6.0,
      minThumbLength: 120.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[
      'thickness: 6.0',
      'hoverThickness: 12.0',
      'showTrackOnHover: true',
      'radius: Radius.circular(3.0)',
      'thumbDragColor: MaterialColor(primary value: Color(0xfff44336))',
      'thumbHoverColor: MaterialColor(primary value: Color(0xffff9800))',
      'thumbIdleColor: MaterialColor(primary value: Color(0xffffeb3b))',
      'trackColor: MaterialColor(primary value: Color(0xff4caf50))',
      'trackBorderColor: MaterialColor(primary value: Color(0xff2196f3))',
      'crossAxisMargin: 3.0',
      'mainAxisMargin: 6.0',
      'minThumbLength: 120.0'
    ]);

    // On the web, Dart doubles and ints are backed by the same kind of object because
    // JavaScript does not support integers. So, the Dart double "4.0" is identical
    // to "4", which results in the web evaluating to the value "4" regardless of which
    // one is used. This results in a difference for doubles in debugFillProperties between
    // the web and the rest of Flutter's target platforms.
  }, skip: kIsWeb);
}

ScrollbarTheme _scrollbarTheme({
  double thickness = 10.0,
  double hoverThickness = 20.0,
  bool showTrackOnHover = true,
  Radius radius = const Radius.circular(6.0),
  Color thumbDragColor = Colors.red,
  Color thumbHoverColor = Colors.blue,
  Color thumbIdleColor = Colors.green,
  Color trackColor = Colors.black,
  Color trackBorderColor = Colors.yellow,
  double crossAxisMargin = 5.0,
  double mainAxisMargin = 10.0,
  double minThumbLength = 50.0,
}) {
  return ScrollbarTheme(
    thickness: thickness,
    hoverThickness: hoverThickness,
    showTrackOnHover: showTrackOnHover,
    radius: radius,
    thumbDragColor: thumbDragColor,
    thumbHoverColor: thumbHoverColor,
    thumbIdleColor: thumbIdleColor,
    trackColor: trackColor,
    trackBorderColor: trackBorderColor,
    crossAxisMargin: crossAxisMargin,
    mainAxisMargin: mainAxisMargin,
    minThumbLength: minThumbLength,
  );
}
