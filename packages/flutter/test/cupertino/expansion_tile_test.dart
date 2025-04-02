// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Toggles expansion on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(title: Text('Title'), child: Text('Content')),
        ),
      ),
    );

    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Title'));
    await tester.pump();
    // The child animating its height and a clone fading in.
    expect(find.text('Content'), findsNWidgets(2));

    await tester.tap(find.text('Title'));
    await tester.pump();
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('Can be controlled by ExpansibleController', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(
            controller: controller,
            title: const Text('Title'),
            child: const Text('Content'),
          ),
        ),
      ),
    );

    expect(controller.isExpanded, isFalse);
    expect(find.text('Content'), findsNothing);

    controller.expand();
    await tester.pump();
    expect(controller.isExpanded, isTrue);
    expect(find.text('Content'), findsOneWidget);

    controller.collapse();
    await tester.pump();
    expect(controller.isExpanded, isFalse);
    expect(find.text('Content'), findsNothing);

    controller.dispose();
  });

  testWidgets('Nested expansion tile', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(
            title: Text('Outer'),
            child: CupertinoExpansionTile(title: Text('Inner'), child: Text('Content')),
          ),
        ),
      ),
    );

    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Outer'));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Inner'));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsOneWidget);

    await tester.tap(find.text('Inner'));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Outer'));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);
  });

  testWidgets(
    'Default expansion animation and icon rotation',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: RepaintBoundary(
              child: CupertinoExpansionTile(
                title: Text('Title'),
                child: SizedBox(height: 50.0, child: ColoredBox(color: Color(0xffff0000))),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CupertinoExpansionTile),
        matchesGoldenFile('expansion_tile.default.collapsed.png'),
      );

      await tester.tap(find.text('Title'));
      await tester.pump();

      // Pump until halfway through the animation.
      await tester.pump(const Duration(milliseconds: 125));
      await expectLater(
        find.byType(CupertinoExpansionTile),
        matchesGoldenFile('expansion_tile.default.forward.png'),
      );

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CupertinoExpansionTile),
        matchesGoldenFile('expansion_tile.default.expanded.png'),
      );

      await tester.tap(find.text('Title'));
      await tester.pump();

      // Pump until halfway through the animation.
      await tester.pump(const Duration(milliseconds: 125));
      await expectLater(
        find.byType(CupertinoExpansionTile),
        matchesGoldenFile('expansion_tile.default.reverse.png'),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('Expansion animation in scroll mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: RepaintBoundary(
            child: CupertinoExpansionTile(
              title: Text('Title'),
              transitionMode: ExpansionTileTransitionMode.scroll,
              child: SizedBox(height: 50.0, child: ColoredBox(color: Color(0xffff0000))),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Title'));
    await tester.pump();

    // Pump until halfway through the animation.
    await tester.pump(const Duration(milliseconds: 125));
    await expectLater(
      find.byType(CupertinoExpansionTile),
      matchesGoldenFile('expansion_tile.scroll_mode.forward.png'),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    await tester.pump();

    // Pump until halfway through the animation.
    await tester.pump(const Duration(milliseconds: 125));
    await expectLater(
      find.byType(CupertinoExpansionTile),
      matchesGoldenFile('expansion_tile.scroll_mode.reverse.png'),
    );
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
