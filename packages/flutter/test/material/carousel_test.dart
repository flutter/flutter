// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Carousel defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    final ColorScheme colorScheme = theme.colorScheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Carousel(
            itemExtent: 200,
            children: List<Widget>.generate(10, (int index) {
              return Center(child: Text('Item $index'));
            }),
          ),
        ),
      ),
    );

    final Finder carouselMaterial = find.descendant(
      of: find.byType(Carousel),
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

    testWidgets('Carousel items customization', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final ThemeData theme = ThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Carousel(
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
      of: find.byType(Carousel),
      matching: find.byType(Material),
    ).first;

    expect(tester.getSize(carouselMaterial).width, 200 - 20 - 20); // Padding is 20 on both side.
    final Material material = tester.widget<Material>(carouselMaterial);
    expect(material.color, Colors.amber);
    expect(material.elevation, 10.0);
    expect(material.shape, const StadiumBorder());

    RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');

    // On hovered.
    final TestGesture gesture = await _pointGestureToCarouselItem(tester, key);
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

    // Check overlay color in focused state
    expect(inkWell.overlayColor?.resolve(<WidgetState>{state}), Colors.purple);
  });

  testWidgets('Carousel respect onTap', (WidgetTester tester) async {
    final List<GlobalKey> keys = List<GlobalKey>.generate(10, (_) => GlobalKey());
    final ThemeData theme = ThemeData();
    int tapIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Carousel(
            itemExtent: 50,
            onTap: (int index) {
              tapIndex = index;
            },
            children: List<Widget>.generate(10, (int index) {
              return Center(
                key: keys.elementAt(index),
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      ),
    );

    // await tester.tap(find.text('Item 1'));
    // await tester.tap(find.byKey(keys.elementAt(1)));
    final Finder item1 = find.byKey(keys.elementAt(1));
    await tester.tap(find.ancestor(of: item1, matching: find.byType(Stack)));
    await tester.pump();
    expect(tapIndex, 1);

    final Finder item2 = find.byKey(keys.elementAt(2));
    await tester.tap(find.ancestor(of: item2, matching: find.byType(Stack)));
    await tester.pump();
    expect(tapIndex, 2);
  });

  testWidgets('Carousel layout (Uncontained layout)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Carousel(
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

    final Size viewportSize = MediaQuery.of(tester.element(find.byType(Carousel))).size;
    expect(viewportSize, const Size(800, 600));

    Finder getItem(int index) {
      return find.descendant(of: find.byType(Carousel), matching: find.ancestor(of: find.text('Item $index'), matching: find.byType(Padding)));
    }

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

  testWidgets('Carousel.weighted layout', (WidgetTester tester) async {
    Widget buildCarousel({ required List<int> weights }) {
      return MaterialApp(
        home: Scaffold(
          body: Carousel.weighted(
            layoutWeights: const <int>[4,3,2,1],
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildCarousel(weights: <int>[4,3,2,1]));

    final Size viewportSize = MediaQuery.of(tester.element(find.byType(Carousel))).size;
    expect(viewportSize, const Size(800, 600));

    Finder getItem(int index) {
      return find.descendant(of: find.byType(Carousel), matching: find.ancestor(of: find.text('Item $index'), matching: find.byType(Padding)));
    }

    expect(find.text('Item 0'), findsOneWidget);
    Rect rect0 = tester.getRect(getItem(0));
    // Item width is 4/10 of the viewport.
    expect(rect0, const Rect.fromLTRB(0.0, 0.0, 320.0, 600.0));

    expect(find.text('Item 1'), findsOneWidget);
    Rect rect1 = tester.getRect(getItem(1));
    // Item width is 3/10 of the viewport.
    expect(rect1, const Rect.fromLTRB(320.0, 0.0, 560.0, 600.0));

    expect(find.text('Item 2'), findsOneWidget);
    final Rect rect2 = tester.getRect(getItem(2));
    // Item width is 2/10 of the viewport.
    expect(rect2, const Rect.fromLTRB(560.0, 0.0, 720.0, 600.0));

    expect(find.text('Item 3'), findsOneWidget);
    final Rect rect3 = tester.getRect(getItem(3));
    // Item width is 1/10 of the viewport.
    expect(rect3, const Rect.fromLTRB(720.0, 0.0, 800.0, 600.0));

    expect(find.text('Item 4'), findsNothing);

    // Test shorter weight list.
    await tester.pumpWidget(buildCarousel(weights: <int>[7,1]));
    expect(viewportSize, const Size(800, 600));

    expect(find.text('Item 0'), findsOneWidget);
    rect0 = tester.getRect(getItem(0));
    // Item width is 7/8 of the viewport.
    // expect(rect0, const Rect.fromLTRB(0.0, 0.0, 700.0, 600.0));

    expect(find.text('Item 1'), findsOneWidget);
    rect1 = tester.getRect(getItem(1));
    // Item width is 1/8 of the viewport.
    // expect(rect1, const Rect.fromLTRB(700.0, 0.0, 800.0, 600.0));

    expect(find.text('Item 2'), findsNothing);
  });

  testWidgets('Carousel ', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Carousel.weighted(
            layoutWeights: const <int>[7,1],
            children: List<Widget>.generate(10, (int index) {
              return Center(
                child: Text('Item $index'),
              );
            }),
          ),
        ),
      )
    );

    final Size viewportSize = MediaQuery.of(tester.element(find.byType(Carousel))).size;
    expect(viewportSize, const Size(800, 600));

    Finder getItem(int index) {
      return find.descendant(of: find.byType(Carousel), matching: find.ancestor(of: find.text('Item $index'), matching: find.byType(Padding)));
    }

    expect(find.text('Item 0'), findsOneWidget);
    final Rect rect0 = tester.getRect(getItem(0));
    // Item width is 7/8 of the viewport.
    expect(rect0, const Rect.fromLTRB(0.0, 0.0, 700.0, 600.0));

    expect(find.text('Item 1'), findsOneWidget);
    final Rect rect1 = tester.getRect(getItem(1));
    // Item width is 1/8 of the viewport.
    expect(rect1, const Rect.fromLTRB(700.0, 0.0, 800.0, 600.0));

    expect(find.text('Item 2'), findsNothing);
  });

}

Future<TestGesture> _pointGestureToCarouselItem(WidgetTester tester, GlobalKey key) async {
  final Offset center = tester.getCenter(find.byKey(key));
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );

  // On hovered.
  await gesture.addPointer();
  await gesture.moveTo(center);
  return gesture;
}
