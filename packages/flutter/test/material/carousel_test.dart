// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CarouselView defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    final ColorScheme colorScheme = theme.colorScheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: CarouselView(
            itemExtent: 200,
            children: List<Widget>.generate(10, (int index) {
              return Center(child: Text('Item $index'));
            }),
          ),
        ),
      ),
    );

    final Finder carouselMaterial = find.descendant(
      of: find.byType(CarouselView),
      matching: find.byType(Material),
    ).first;

    final Material material = tester.widget<Material>(carouselMaterial);
    expect(material.clipBehavior, Clip.antiAlias);
    expect(material.color, colorScheme.surface);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28.0))
    ));
  });

  testWidgets('CarouselView items customization', (WidgetTester tester) async {
    final Key key = UniqueKey();
    final ThemeData theme = ThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: CarouselView(
            padding: const EdgeInsets.all(20.0),
            backgroundColor: Colors.amber,
            elevation: 10.0,
            shape: const StadiumBorder(),
            overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.yellow;
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.red;
              }
              if (states.contains(WidgetState.focused)) {
                return Colors.purple;
              }
              return null;
            }),
            itemExtent: 200,
            children: List<Widget>.generate(10, (int index) {
              if (index == 0) {
                return Center(
                  key: key,
                  child: Center(child: Text('Item $index')),
                );
              }
              return Center(child: Text('Item $index'));
            }),
          ),
        ),
      ),
    );

    final Finder carouselMaterial = find.descendant(
      of: find.byType(CarouselView),
      matching: find.byType(Material),
    ).first;

    expect(tester.getSize(carouselMaterial).width, 200 - 20 - 20); // Padding is 20 on both side.
    final Material material = tester.widget<Material>(carouselMaterial);
    expect(material.color, Colors.amber);
    expect(material.elevation, 10.0);
    expect(material.shape, const StadiumBorder());

    RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');

    // On hovered.
    final TestGesture gesture = await hoverPointerOverCarouselItem(tester, key);
    await tester.pumpAndSettle();
    expect(inkFeatures, paints..rect(color: Colors.red.withOpacity(1.0)));

    // On pressed.
    await tester.pumpAndSettle();
    await gesture.down(tester.getCenter(find.byKey(key)));
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect()..rect(color: Colors.yellow.withOpacity(1.0)));

    await tester.pumpAndSettle();
    await gesture.up();
    await gesture.removePointer();

    // On focused.
    final Element inkWellElement = tester.element(find.descendant(of: carouselMaterial, matching: find.byType(InkWell)));
    expect(inkWellElement.widget, isA<InkWell>());
    final InkWell inkWell = inkWellElement.widget as InkWell;

    const MaterialState state = MaterialState.focused;

    // Check overlay color in focused state.
    expect(inkWell.overlayColor?.resolve(<WidgetState>{state}), Colors.purple);
  });

  testWidgets('CarouselView respects onTap', (WidgetTester tester) async {
    final List<Key> keys = List<Key>.generate(10, (_) => UniqueKey());
    final ThemeData theme = ThemeData();
    int tapIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: CarouselView(
            itemExtent: 50,
            onTap: (int index) {
              tapIndex = index;
            },
            children: List<Widget>.generate(10, (int index) {
              return Center(
                key: keys[index],
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      ),
    );

    final Finder item1 = find.byKey(keys.elementAt(1));
    await tester.tap(find.ancestor(of: item1, matching: find.byType(Stack)));
    await tester.pump();
    expect(tapIndex, 1);

    final Finder item2 = find.byKey(keys.elementAt(2));
    await tester.tap(find.ancestor(of: item2, matching: find.byType(Stack)));
    await tester.pump();
    expect(tapIndex, 2);
  });

  testWidgets('CarouselView layout (Uncontained layout)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarouselView(
            itemExtent: 250,
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      )
    );

    final Size viewportSize = MediaQuery.sizeOf(tester.element(find.byType(CarouselView)));
    expect(viewportSize, const Size(800, 600));

    expect(find.text('Item 0'), findsOneWidget);
    final Rect rect0 = tester.getRect(getItem(0));
    expect(rect0, const Rect.fromLTRB(0.0, 0.0, 250.0, 600.0));

    expect(find.text('Item 1'), findsOneWidget);
    final Rect rect1 = tester.getRect(getItem(1));
    expect(rect1, const Rect.fromLTRB(250.0, 0.0, 500.0, 600.0));

    expect(find.text('Item 2'), findsOneWidget);
    final Rect rect2 = tester.getRect(getItem(2));
    expect(rect2, const Rect.fromLTRB(500.0, 0.0, 750.0, 600.0));

    expect(find.text('Item 3'), findsOneWidget);
    final Rect rect3 = tester.getRect(getItem(3));
    expect(rect3, const Rect.fromLTRB(750.0, 0.0, 800.0, 600.0));

    expect(find.text('Item 4'), findsNothing);
  });

  testWidgets('CarouselController initialItem', (WidgetTester tester) async {
    final CarouselController controller = CarouselController(initialItem: 5);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarouselView(
            controller: controller,
            itemExtent: 400,
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      )
    );

    final Size viewportSize = MediaQuery.sizeOf(tester.element(find.byType(CarouselView)));
    expect(viewportSize, const Size(800, 600));

    expect(find.text('Item 5'), findsOneWidget);
    final Rect rect5 = tester.getRect(getItem(5));
    // Item width is 400.
    expect(rect5, const Rect.fromLTRB(0.0, 0.0, 400.0, 600.0));

    expect(find.text('Item 6'), findsOneWidget);
    final Rect rect6 = tester.getRect(getItem(6));
    // Item width is 400.
    expect(rect6, const Rect.fromLTRB(400.0, 0.0, 800.0, 600.0));

    expect(find.text('Item 4'), findsNothing);
    expect(find.text('Item 7'), findsNothing);
  });

  testWidgets('CarouselView respects itemSnapping', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarouselView(
            itemSnapping: true,
            itemExtent: 300,
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      )
    );

    void checkOriginalExpectations() {
      expect(getItem(0), findsOneWidget);
      expect(getItem(1), findsOneWidget);
      expect(getItem(2), findsOneWidget);
      expect(getItem(3), findsNothing);
    }

    checkOriginalExpectations();

    // Snap back to the original item.
    await tester.drag(getItem(0), const Offset(-150, 0));
    await tester.pumpAndSettle();

    checkOriginalExpectations();

    // Snap back to the original item.
    await tester.drag(getItem(0), const Offset(100, 0));
    await tester.pumpAndSettle();

    checkOriginalExpectations();

    // Snap to the next item.
    await tester.drag(getItem(0), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(getItem(0), findsNothing);
    expect(getItem(1), findsOneWidget);
    expect(getItem(2), findsOneWidget);
    expect(getItem(3), findsOneWidget);
  });

  testWidgets('CarouselView respect itemSnapping when fling', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarouselView(
            itemSnapping: true,
            itemExtent: 300,
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      )
    );

    // Show item 0, 1, and 2.
    expect(getItem(0), findsOneWidget);
    expect(getItem(1), findsOneWidget);
    expect(getItem(2), findsOneWidget);
    expect(getItem(3), findsNothing);

    // Snap to the next item. Show item 1, 2 and 3.
    await tester.fling(getItem(0), const Offset(-100, 0), 800);
    await tester.pumpAndSettle();

    expect(getItem(0), findsNothing);
    expect(getItem(1), findsOneWidget);
    expect(getItem(2), findsOneWidget);
    expect(getItem(3), findsOneWidget);
    expect(getItem(4), findsNothing);

    // Snap to the next item. Show item 2, 3 and 4.
    await tester.fling(getItem(1), const Offset(-100, 0), 800);
    await tester.pumpAndSettle();

    expect(getItem(0), findsNothing);
    expect(getItem(1), findsNothing);
    expect(getItem(2), findsOneWidget);
    expect(getItem(3), findsOneWidget);
    expect(getItem(4), findsOneWidget);
    expect(getItem(5), findsNothing);

    // Fling back to the previous item. Show item 1, 2 and 3.
    await tester.fling(getItem(2), const Offset(100, 0), 800);
    await tester.pumpAndSettle();

    expect(getItem(1), findsOneWidget);
    expect(getItem(2), findsOneWidget);
    expect(getItem(3), findsOneWidget);
    expect(getItem(4), findsNothing);
  });

  testWidgets('CarouselView respects scrollingDirection: Axis.vertical', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarouselView(
            itemExtent: 200,
            padding: EdgeInsets.zero,
            scrollDirection: Axis.vertical,
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      )
    );
    await tester.pumpAndSettle();

    expect(getItem(0), findsOneWidget);
    expect(getItem(1), findsOneWidget);
    expect(getItem(2), findsOneWidget);
    expect(getItem(3), findsNothing);
    final Rect rect0 = tester.getRect(getItem(0));
    // Item width is 200 of the viewport.
    expect(rect0, const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0));

    // Simulate a scroll up
    await tester.drag(find.byType(CarouselView), const Offset(0, -200), kind: PointerDeviceKind.trackpad);
    await tester.pumpAndSettle();
    expect(getItem(0), findsNothing);
    expect(getItem(3), findsOneWidget);
  });

  testWidgets('CarouselView respects reverse', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarouselView(
            itemExtent: 200,
            reverse: true,
            padding: EdgeInsets.zero,
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      )
    );
    await tester.pumpAndSettle();

    expect(getItem(0), findsOneWidget);
    final Rect rect0 = tester.getRect(getItem(0));
    // Item 0 should be placed on the end of the screen.
    expect(rect0, const Rect.fromLTRB(600.0, 0.0, 800.0, 600.0));

    expect(getItem(1), findsOneWidget);
    final Rect rect1 = tester.getRect(getItem(1));
    // Item 1 should be placed before item 0.
    expect(rect1, const Rect.fromLTRB(400.0, 0.0, 600.0, 600.0));

    expect(getItem(2), findsOneWidget);
    final Rect rect2 = tester.getRect(getItem(2));
    // Item 2 should be placed before item 1.
    expect(rect2, const Rect.fromLTRB(200.0, 0.0, 400.0, 600.0));

    expect(getItem(3), findsOneWidget);
    final Rect rect3 = tester.getRect(getItem(3));
    // Item 3 should be placed before item 2.
    expect(rect3, const Rect.fromLTRB(0.0, 0.0, 200.0, 600.0));
  });

  testWidgets('CarouselView respects shrinkExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarouselView(
            itemExtent: 350,
            shrinkExtent: 300,
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      )
    );
    await tester.pumpAndSettle();

    final Rect rect0 = tester.getRect(getItem(0));
    expect(rect0, const Rect.fromLTRB(0.0, 0.0, 350.0, 600.0));

    final Rect rect1 = tester.getRect(getItem(1));
    expect(rect1, const Rect.fromLTRB(350.0, 0.0, 700.0, 600.0));

    final Rect rect2 = tester.getRect(getItem(2));
    // The extent of item 2 is 300, and only 100 is on screen.
    expect(rect2, const Rect.fromLTRB(700.0, 0.0, 1000.0, 600.0));

    await tester.drag(find.byType(CarouselView), const Offset(-50, 0), kind: PointerDeviceKind.trackpad);
    await tester.pump();
    // The item 0 should be pinned and has a size change from 350 to 50.
    expect(tester.getRect(getItem(0)), const Rect.fromLTRB(0.0, 0.0, 300.0, 600.0));
    // Keep dragging to left, extent of item 0 won't change (still 300) and part of item 0 will
    // be off screen.
    await tester.drag(find.byType(CarouselView), const Offset(-50, 0), kind: PointerDeviceKind.trackpad);
    await tester.pump();
    expect(tester.getRect(getItem(0)), const Rect.fromLTRB(-50, 0.0, 250, 600));
  });
}

Finder getItem(int index) {
  return find.descendant(of: find.byType(CarouselView), matching: find.ancestor(of: find.text('Item $index'), matching: find.byType(Padding)));
}

Future<TestGesture> hoverPointerOverCarouselItem(WidgetTester tester, Key key) async {
  final Offset center = tester.getCenter(find.byKey(key));
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );

  // On hovered.
  await gesture.addPointer();
  await gesture.moveTo(center);
  return gesture;
}
