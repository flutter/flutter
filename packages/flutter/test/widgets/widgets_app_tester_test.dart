// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

void main() {
  group('TestWidgetsApp', () {
    testWidgets('home widget is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(const TestWidgetsApp(home: Text('Home Widget')));

      expect(find.text('Home Widget'), findsOneWidget);
    });

    testWidgets('uses default color (white) when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(const TestWidgetsApp(home: Placeholder()));

      final WidgetsApp widgetsApp = tester.widget(find.byType(WidgetsApp));
      expect(widgetsApp.color, const Color(0xFFFFFFFF));
    });

    testWidgets('uses custom color when specified', (WidgetTester tester) async {
      const customColor = Color(0xFF123456);

      await tester.pumpWidget(const TestWidgetsApp(home: Placeholder(), color: customColor));

      final WidgetsApp widgetsApp = tester.widget(find.byType(WidgetsApp));
      expect(widgetsApp.color, customColor);
    });

    testWidgets('provides working Overlay', (WidgetTester tester) async {
      late OverlayState overlayState;

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  overlayState = Overlay.of(context);
                },
                child: const Text('Tap me'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(overlayState, isNotNull);
    });

    testWidgets('overlay entries can be inserted and displayed', (WidgetTester tester) async {
      late OverlayState overlayState;
      OverlayEntry? overlayEntry;

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  overlayState = Overlay.of(context);
                  overlayEntry = OverlayEntry(
                    builder: (BuildContext context) {
                      return const Positioned(top: 100, left: 100, child: Text('Overlay Content'));
                    },
                  );
                  overlayState.insert(overlayEntry!);
                },
                child: const Text('Show Overlay'),
              );
            },
          ),
        ),
      );

      expect(find.text('Overlay Content'), findsNothing);

      await tester.tap(find.text('Show Overlay'));
      await tester.pump();

      expect(find.text('Overlay Content'), findsOneWidget);

      overlayEntry?.remove();
      overlayEntry?.dispose();
      await tester.pump();

      expect(find.text('Overlay Content'), findsNothing);
    });

    testWidgets('provides working Navigator', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                          ) {
                            return const Text('Second Page');
                          },
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Second Page'), findsNothing);

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Second Page'), findsOneWidget);
    });

    testWidgets('Navigator can pop routes', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                          ) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Second Page - Tap to go back'),
                            );
                          },
                    ),
                  );
                },
                child: const Text('First Page'),
              );
            },
          ),
        ),
      );

      expect(find.text('First Page'), findsOneWidget);

      await tester.tap(find.text('First Page'));
      await tester.pumpAndSettle();

      expect(find.text('Second Page - Tap to go back'), findsOneWidget);
      expect(find.text('First Page'), findsNothing);

      await tester.tap(find.text('Second Page - Tap to go back'));
      await tester.pumpAndSettle();

      expect(find.text('First Page'), findsOneWidget);
      expect(find.text('Second Page - Tap to go back'), findsNothing);
    });

    testWidgets('provides MediaQuery', (WidgetTester tester) async {
      late MediaQueryData mediaQueryData;

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              mediaQueryData = MediaQuery.of(context);
              return const Placeholder();
            },
          ),
        ),
      );

      expect(mediaQueryData, isNotNull);
      expect(mediaQueryData.size, isNotNull);
    });

    testWidgets('provides Directionality', (WidgetTester tester) async {
      late TextDirection textDirection;

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              textDirection = Directionality.of(context);
              return const Placeholder();
            },
          ),
        ),
      );

      expect(textDirection, isNotNull);
    });
  });
}
