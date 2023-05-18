// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/list_tile/list_tile.5.dart';
import 'package:flutter_test/flutter_test.dart';

Size size(Element e) {
  final RenderBox r = e.renderObject! as RenderBox;
  return r.size;
}

Offset center(Element e) {
  return size(e).center(Offset.zero);
}

bool menuItemChecked(String text) {
  return (find
          .ancestor(
            of: find.text(text),
            matching: find.byType(CheckedPopupMenuItem<int>),
          )
          .evaluate()
          .first
          .widget as CheckedPopupMenuItem<int>)
      .checked;
}

void main() {
  testWidgets('List tile widths are constrained by cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ListTileApp(),
    );

    final Offset pageCenter = tester.getCenter(find.byType(MaterialApp));

    find
        .descendant(
          of: find.byType(ListCard, skipOffstage: false),
          matching: find.byType(ListTile, skipOffstage: false),
        )
        .evaluate()
        .mapIndexed((int index, Element listTile) {
      expect(center(listTile).dx, pageCenter.dx,
          reason: '$index should be centered');
      expect(size(listTile).width, 360,
          reason: '$index should have its width constrained by its Card');
    });
  });

  testWidgets('can toggle text direction', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ListTileApp(),
    );

    find
        .descendant(
          of: find.byType(ListCard, skipOffstage: false),
          matching: find.byType(Directionality, skipOffstage: false),
        )
        .evaluate()
        .mapIndexed((int index, Element directionality) {
      expect(
        (directionality.widget as Directionality).textDirection,
        TextDirection.ltr,
        reason: '$index should default to ltr',
      );
    });

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Left-to-right text'), true);
    await tester.tap(
      find.ancestor(
        of: find.text('Left-to-right text'),
        matching: find.byType(CheckedPopupMenuItem<int>),
      ),
    );
    await tester.pumpAndSettle();

    find
        .descendant(
          of: find.byType(ListCard, skipOffstage: false),
          matching: find.byType(Directionality, skipOffstage: false),
        )
        .evaluate()
        .mapIndexed((int index, Element directionality) {
      expect(
        (directionality.widget as Directionality).textDirection,
        TextDirection.rtl,
        reason: '$index should change to rtl',
      );
    });

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Left-to-right text'), false);
  });

  testWidgets('can toggle density', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ListTileApp(),
    );

    expect(
      (find.byType(MaterialApp).evaluate().first.widget as MaterialApp)
          .theme!
          .visualDensity,
      VisualDensity.standard,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Use adaptive platform density'), false);
    await tester.tap(
      find.ancestor(
        of: find.text('Use adaptive platform density'),
        matching: find.byType(CheckedPopupMenuItem<int>),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      (find.byType(MaterialApp).evaluate().first.widget as MaterialApp)
          .theme!
          .visualDensity,
      VisualDensity.adaptivePlatformDensity,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Use adaptive platform density'), true);
  });

  testWidgets('can toggle light and dark', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ListTileApp(),
    );

    expect(
      (find.byType(MaterialApp).evaluate().first.widget as MaterialApp)
          .themeMode,
      ThemeMode.light,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Use dark mode'), false);
    await tester.tap(
      find.ancestor(
        of: find.text('Use dark mode'),
        matching: find.byType(CheckedPopupMenuItem<int>),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      (find.byType(MaterialApp).evaluate().first.widget as MaterialApp)
          .themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Use dark mode'), true);
  });

  testWidgets('can toggle Material 2 and 3', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ListTileApp(),
    );

    expect(
      (find.byType(MaterialApp).evaluate().first.widget as MaterialApp)
          .theme!
          .useMaterial3,
      true,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Use Material 3'), true);
    await tester.tap(
      find.ancestor(
        of: find.text('Use Material 3'),
        matching: find.byType(CheckedPopupMenuItem<int>),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      (find.byType(MaterialApp).evaluate().first.widget as MaterialApp)
          .theme!
          .useMaterial3,
      false,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Use Material 3'), false);
  });

  testWidgets('can toggle dividers', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ListTileApp(),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Show dividers'), false);
    await tester.tap(
      find.ancestor(
        of: find.text('Show dividers'),
        matching: find.byType(CheckedPopupMenuItem<int>),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(menuItemChecked('Show dividers'), true);
  });
}
