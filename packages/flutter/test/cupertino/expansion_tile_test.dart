// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// reduced-test-set:
//   This file is run as part of a reduced test set in CI on Mac and Windows
//   machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Duration expansionDuration = Duration(milliseconds: 250);
  const Duration infinitesimalDuration = Duration(microseconds: 1);
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

  testWidgets('Controller can set the tile to be initially expanded', (WidgetTester tester) async {
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

    controller.expand();
    await tester.pump();

    expect(controller.isExpanded, isTrue);
    expect(find.text('Content'), findsOneWidget);

    await tester.tap(find.text('Title'));
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
    await tester.pump();
    await tester.pump(expansionDuration + infinitesimalDuration);
    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Inner'));
    await tester.pump();
    await tester.pump(expansionDuration + infinitesimalDuration);
    expect(find.text('Content'), findsOneWidget);

    await tester.tap(find.text('Inner'));
    await tester.pump();
    await tester.pump(expansionDuration + infinitesimalDuration);
    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Outer'));
    await tester.pump();
    await tester.pump(expansionDuration + infinitesimalDuration);
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('Default expansion animation and icon rotation', (WidgetTester tester) async {
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
    await tester.pump(expansionDuration ~/ 2);
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
    await tester.pump(expansionDuration ~/ 2);
    await expectLater(
      find.byType(CupertinoExpansionTile),
      matchesGoldenFile('expansion_tile.default.reverse.png'),
    );
  });

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
    await tester.pump(expansionDuration ~/ 2);
    await expectLater(
      find.byType(CupertinoExpansionTile),
      matchesGoldenFile('expansion_tile.scroll_mode.forward.png'),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    await tester.pump();

    // Pump until halfway through the animation.
    await tester.pump(expansionDuration ~/ 2);
    await expectLater(
      find.byType(CupertinoExpansionTile),
      matchesGoldenFile('expansion_tile.scroll_mode.reverse.png'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('Nested CupertinoListTile Semantics', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    addTearDown(controller.dispose);
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            const CupertinoExpansionTile(
              title: Text('First Expansion Tile'),
              child: SizedBox(height: 50.0),
            ),
            CupertinoExpansionTile(
              controller: controller,
              title: const Text('Second Expansion Tile'),
              child: const SizedBox(height: 50.0),
            ),
          ],
        ),
      ),
    );

    controller.expand();
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(CupertinoListTile).first),
      matchesSemantics(
        hasTapAction: true,
        label: 'First Expansion Tile',
        textDirection: TextDirection.ltr,
      ),
    );

    expect(
      tester.getSemantics(find.byType(CupertinoListTile).last),
      matchesSemantics(
        hasTapAction: true,
        label: 'Second Expansion Tile',
        textDirection: TextDirection.ltr,
      ),
    );
    handle.dispose();
  });

  testWidgets('Semantics with the onTapHint is an ancestor of CupertinoListTile', (
    WidgetTester tester,
  ) async {
    final ExpansibleController controller = ExpansibleController();
    addTearDown(controller.dispose);
    final SemanticsHandle handle = tester.ensureSemantics();
    const DefaultCupertinoLocalizations localizations = DefaultCupertinoLocalizations();

    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            const CupertinoExpansionTile(
              title: Text('First Expansion Tile'),
              child: SizedBox(height: 100, width: 100),
            ),
            CupertinoExpansionTile(
              controller: controller,
              title: const Text('Second Expansion Tile'),
              child: const SizedBox(height: 100, width: 100),
            ),
          ],
        ),
      ),
    );

    controller.expand();
    await tester.pumpAndSettle();

    SemanticsNode semantics = tester.getSemantics(
      find
          .ancestor(of: find.byType(CupertinoListTile).first, matching: find.byType(Semantics))
          .first,
    );
    expect(semantics, isNotNull);
    // The onTapHint is passed to semantics properties's hintOverrides.
    expect(semantics.hintOverrides, isNotNull);
    // The hint should be the opposite of the current state.
    // The first CupertinoExpansionTile is collapsed, so the hint should be
    // "double tap to expand".
    expect(semantics.hintOverrides!.onTapHint, localizations.expansionTileCollapsedTapHint);

    semantics = tester.getSemantics(
      find
          .ancestor(of: find.byType(CupertinoListTile).last, matching: find.byType(Semantics))
          .first,
    );

    expect(semantics, isNotNull);
    // The onTapHint is passed to semantics properties's hintOverrides.
    expect(semantics.hintOverrides, isNotNull);
    // The hint should be the opposite of the current state.
    // The second CupertinoExpansionTile is expanded, so the hint should be
    // "double tap to collapse".
    expect(semantics.hintOverrides!.onTapHint, localizations.expansionTileExpandedTapHint);
    handle.dispose();
  });

  testWidgets(
    'Semantics hint for iOS and macOS',
    (WidgetTester tester) async {
      final ExpansibleController controller = ExpansibleController();
      addTearDown(controller.dispose);
      final SemanticsHandle handle = tester.ensureSemantics();
      const DefaultCupertinoLocalizations localizations = DefaultCupertinoLocalizations();

      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              const CupertinoExpansionTile(
                title: Text('First Expansion Tile'),
                child: SizedBox(height: 100, width: 100),
              ),
              CupertinoExpansionTile(
                controller: controller,
                title: const Text('Second Expansion Tile'),
                child: const SizedBox(height: 100, width: 100),
              ),
            ],
          ),
        ),
      );

      controller.expand();
      await tester.pumpAndSettle();

      SemanticsNode semantics = tester.getSemantics(
        find
            .ancestor(of: find.byType(CupertinoListTile).first, matching: find.byType(Semantics))
            .first,
      );

      expect(semantics, isNotNull);
      expect(
        semantics.hint,
        '${localizations.expandedHint}\n ${localizations.expansionTileCollapsedHint}',
      );

      semantics = tester.getSemantics(
        find
            .ancestor(of: find.byType(CupertinoListTile).last, matching: find.byType(Semantics))
            .first,
      );

      expect(semantics, isNotNull);
      expect(
        semantics.hint,
        '${localizations.collapsedHint}\n ${localizations.expansionTileExpandedHint}',
      );
      handle.dispose();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );
}
