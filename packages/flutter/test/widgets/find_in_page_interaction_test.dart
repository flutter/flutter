// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Find-in-Page Non-Golden Interaction & State-Machine Tests', () {
    testWidgets(
      '1. Incremental typing ("flu" -> "flut" -> "flu") preserves active match anchor and advances forward in reading order',
      (WidgetTester tester) async {
        final FindInPageController controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: FindInPageScope(
              enableSelection: false,
              enableFind: true,
              controller: controller,
              child: const SelectionArea(
                child: Scaffold(
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('0: flute prelude'),
                      Text('1: fluid dynamics'),
                      Text('2: fluke occurrence'),
                      Text('3: flutter framework'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.open(initialQuery: 'flu');
        await tester.pumpAndSettle();

        expect(controller.matchCount, 4);
        expect(controller.activeMatchIndex, 0);

        // Step to the 4th match ("flutter framework", index 3).
        controller.nextMatch(); // index 1 ("fluid")
        controller.nextMatch(); // index 2 ("fluke")
        controller.nextMatch(); // index 3 ("flutter")
        await tester.pumpAndSettle();

        final Selectable flutterSelectable = controller.activeMatch!.selectable;
        expect(flutterSelectable.getPlainText(), '3: flutter framework');
        expect(controller.activeMatchIndex, 3);

        // Extend query from "flu" -> "flut" (as if typing 't').
        // "fluid" and "fluke" drop out; "flute" (index 0) and "flutter" (index 1) remain.
        // Active match MUST stay anchored on "3: flutter framework" (now index 1 of 2),
        // rather than jumping to index 0 ("flute") or clamping out of bounds.
        controller.query = 'flut';
        await tester.pumpAndSettle();

        expect(controller.matchCount, 2);
        expect(controller.activeMatchIndex, 1);
        expect(controller.activeMatch!.selectable, same(flutterSelectable));
        expect(controller.activeMatch!.text, 'flut');

        // Extend query from "flut" -> "flutt". Now only "3: flutter framework" matches (index 0 of 1).
        controller.query = 'flutt';
        await tester.pumpAndSettle();

        expect(controller.matchCount, 1);
        expect(controller.activeMatchIndex, 0);
        expect(controller.activeMatch!.selectable, same(flutterSelectable));

        // Backspace query from "flutt" -> "flu".
        // Active match MUST remain anchored on "3: flutter framework" (returning to index 3 of 4),
        // NOT yanking the user back to index 0 ("flute").
        controller.query = 'flu';
        await tester.pumpAndSettle();

        expect(controller.matchCount, 4);
        expect(controller.activeMatchIndex, 3);
        expect(controller.activeMatch!.selectable, same(flutterSelectable));

        // Now move active match to "2: fluke occurrence" (index 2 of 4) and type 't' ("flut").
        // Because "fluke" stops matching, the active match should advance forward in reading order
        // from leaf 2 ("fluke") to leaf 3 ("flutter", index 1 of 2) — NOT jump backward up to "flute" (leaf 0).
        controller.previousMatch();
        expect(controller.activeMatch!.selectable.getPlainText(), '2: fluke occurrence');

        controller.query = 'flut';
        await tester.pumpAndSettle();

        expect(controller.matchCount, 2);
        expect(controller.activeMatchIndex, 1);
        expect(controller.activeMatch!.selectable, same(flutterSelectable));
      },
    );

    testWidgets(
      '2. Built-in FindBar keyboard navigation: Enter, Shift+Enter, F3, Shift+F3, Ctrl+G, repeated open() SelectAll, and Escape',
      (WidgetTester tester) async {
        final FindInPageController controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: FindInPageScope(
              enableSelection: false,
              enableFind: true,
              controller: controller,
              child: const SelectionArea(
                child: Scaffold(
                  body: Column(
                    children: <Widget>[Text('Alpha Dart'), Text('Beta Dart'), Text('Gamma Dart')],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open FindBar and verify EditableText receives focus automatically.
        controller.open();
        await tester.pumpAndSettle();

        final EditableText findInput = tester.widget<EditableText>(
          find.descendant(
            of: find.byType(SelectableRegionFindBar),
            matching: find.byType(EditableText),
          ),
        );
        expect(findInput.focusNode.hasFocus, isTrue);

        // Type 'dart' directly into the focused FindBar input.
        await tester.enterText(
          find.descendant(
            of: find.byType(SelectableRegionFindBar),
            matching: find.byType(EditableText),
          ),
          'dart',
        );
        await tester.pumpAndSettle();

        expect(controller.query, 'dart');
        expect(controller.matchCount, 3);
        expect(controller.activeMatchIndex, 0);

        // Press Enter -> advances to match 1 (2 / 3).
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 1);

        // Press Enter -> advances to match 2 (3 / 3).
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 2);

        // Press Enter -> wraps around to match 0 (1 / 3).
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 0);

        // Press Shift+Enter -> steps backward, wrapping from 0 to 2 (3 / 3).
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 2);

        // Press F3 -> steps forward from 2 to 0.
        await tester.sendKeyEvent(LogicalKeyboardKey.f3);
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 0);

        // Press Shift+F3 -> steps backward from 0 to 2.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.f3);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 2);

        // Press Ctrl+G -> steps forward from 2 to 0.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 0);

        // Collapse selection in the FindBar input to the end, then invoke controller.open()
        // again (simulating repeated Cmd+F / Ctrl+F while FindBar is already open).
        // Verify FocusAndSelectAll selects 0..4 ('dart').
        findInput.controller.selection = const TextSelection.collapsed(offset: 4);
        controller.open();
        await tester.pumpAndSettle();
        expect(findInput.controller.selection, const TextSelection(baseOffset: 0, extentOffset: 4));

        // Press Escape -> closes the FindBar.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(controller.isOpen, isFalse);
        expect(find.byType(SelectableRegionFindBar), findsNothing);
      },
    );

    testWidgets(
      '3. Escape / close() selection handoff: selects active match when enableSelection: true, and leaves zero selection when enableSelection: false',
      (WidgetTester tester) async {
        // Part A: enableSelection: true (transfers active match into SelectionArea selection).
        final FindInPageController selectableController = FindInPageController();
        addTearDown(selectableController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: FindInPageScope(
              enableSelection: true,
              enableFind: true,
              controller: selectableController,
              child: const SelectionArea(
                child: Scaffold(
                  body: Column(
                    children: <Widget>[Text('First Skwasm item'), Text('Second Skwasm item')],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        selectableController.open(initialQuery: 'Skwasm');
        await tester.pumpAndSettle();
        selectableController.nextMatch(); // Select 2nd 'Skwasm' (index 1)
        await tester.pumpAndSettle();
        expect(selectableController.activeMatchIndex, 1);

        // Close via Escape key while FindBar has primary focus.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        final SelectableRegionState regionState = tester.state<SelectableRegionState>(
          find.byType(SelectableRegion),
        );
        expect(selectableController.isOpen, isFalse);
        expect(regionState.selectionDelegate.getSelectedContent()?.plainText, 'Skwasm');

        // Verify the 2nd RenderParagraph specifically owns the live selection.
        final RenderParagraph firstParagraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text('First Skwasm item'), matching: find.byType(RichText)),
        );
        final RenderParagraph secondParagraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text('Second Skwasm item'), matching: find.byType(RichText)),
        );
        expect(firstParagraph.selections, isEmpty);
        expect(
          secondParagraph.selections,
          contains(const TextSelection(baseOffset: 7, extentOffset: 13)),
        );

        // Part B: SelectableRegion.findOnly ("Find-Only" mode must NOT leave a stranded selection on close).
        final FindInPageController findOnlyController = FindInPageController();
        addTearDown(findOnlyController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: SelectableRegion.findOnly(
              findController: findOnlyController,
              child: const Scaffold(
                body: Column(
                  children: <Widget>[Text('First Impeller item'), Text('Second Impeller item')],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        findOnlyController.open(initialQuery: 'Impeller');
        await tester.pumpAndSettle();
        expect(findOnlyController.matchCount, 2);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        final SelectableRegionState findOnlyRegionState = tester.state<SelectableRegionState>(
          find.byType(SelectableRegion),
        );
        expect(findOnlyRegionState.selectionDelegate.getSelectedContent(), isNull);
        final RenderParagraph impellerParagraph = tester.renderObject<RenderParagraph>(
          find.text('First Impeller item'),
        );
        expect(impellerParagraph.selections, isEmpty);
        expect(findOnlyController.matchCount, 0);
      },
    );

    testWidgets(
      '4. Seeding query from current page selection on open(): populates FindBar with selected text and anchors activeMatchIndex to selected occurrence',
      (WidgetTester tester) async {
        final FindInPageController controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: FindInPageScope(
              enableSelection: true,
              enableFind: true,
              controller: controller,
              child: const SelectionArea(
                child: Scaffold(
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Line 0: CanvasKit renderer'),
                      Text('Line 1: CanvasKit pipeline'),
                      Text('Line 2: CanvasKit compositor'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select "CanvasKit" in the SECOND line ('Line 1: CanvasKit pipeline', offset 8..17).
        final SelectableRegionState regionState = tester.state<SelectableRegionState>(
          find.byType(SelectableRegion),
        );
        final MultiSelectableSelectionContainerDelegate delegate = regionState.selectionDelegate;
        final List<Selectable> leaves = delegate.getLeafSelectables();
        expect(leaves.length, 3);

        final bool selected = delegate.selectRangeForSelectable(
          leaves[1],
          const SelectedContentRange(startOffset: 8, endOffset: 17),
        );
        expect(selected, isTrue);
        expect(delegate.getSelectedContent()?.plainText, 'CanvasKit');

        // Invoke controller.open() without initialQuery (simulating Cmd+F while text is selected).
        controller.open();
        await tester.pumpAndSettle();

        // Verify query was seeded with 'CanvasKit' AND anchored to occurrence index 1 (Line 1), not index 0!
        expect(controller.isOpen, isTrue);
        expect(controller.query, 'CanvasKit');
        expect(controller.matchCount, 3);
        expect(controller.activeMatchIndex, 1);
        expect(controller.activeMatch!.selectable, same(leaves[1]));

        // Verify the FindBar's EditableText has 'CanvasKit' fully selected (0..9).
        final EditableText findInput = tester.widget<EditableText>(
          find.descendant(
            of: find.byType(SelectableRegionFindBar),
            matching: find.byType(EditableText),
          ),
        );
        expect(findInput.controller.selection, const TextSelection(baseOffset: 0, extentOffset: 9));
      },
    );

    testWidgets(
      '5. Live in-place Text mutation (setState) and widget removal while FindBar is open automatically recompute matches and highlights',
      (WidgetTester tester) async {
        final FindInPageController controller = FindInPageController();
        addTearDown(controller.dispose);

        String dynamicLine = 'Status: healthy';
        bool showThirdLine = true;
        late StateSetter outerSetState;

        await tester.pumpWidget(
          MaterialApp(
            home: FindInPageScope(
              enableSelection: false,
              enableFind: true,
              controller: controller,
              child: SelectionArea(
                child: Scaffold(
                  body: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      outerSetState = setState;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Header: initial timeout log'),
                          Text(dynamicLine, key: const ValueKey<String>('dynamic')),
                          if (showThirdLine) const Text('Footer: final timeout warning'),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.open(initialQuery: 'timeout');
        await tester.pumpAndSettle();

        expect(controller.matchCount, 2);
        expect(controller.activeMatchIndex, 0);

        // Step to the second match ('Footer: final timeout warning', index 1).
        controller.nextMatch();
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 1);

        // Mutate the middle Text widget in-place via setState to introduce two new 'timeout' matches!
        outerSetState(() {
          dynamicLine = 'Status: timeout retry and timeout abort';
        });
        await tester.pumpAndSettle();

        // Without closing or reopening the FindBar, matchCount must automatically update from 2 -> 4!
        expect(controller.matchCount, 4);
        expect(
          controller.matches.map((SelectableSearchMatch m) => m.selectable.getPlainText()).toList(),
          <String>[
            'Header: initial timeout log',
            'Status: timeout retry and timeout abort',
            'Status: timeout retry and timeout abort',
            'Footer: final timeout warning',
          ],
        );

        // Now remove the third line while it is the active match (index 3 of 4).
        controller.nextMatch(); // ensure we are on the last match ('Footer: final timeout warning')
        await tester.pumpAndSettle();
        outerSetState(() {
          showThirdLine = false;
        });
        await tester.pumpAndSettle();

        expect(controller.matchCount, 3);
        expect(controller.activeMatchIndex, inInclusiveRange(0, 2));
      },
    );

    testWidgets(
      '6. Viewport scroll invariants: zero scroll jitter when activeMatch is already visible, and dual-axis (2D) auto-scroll when off-screen',
      (WidgetTester tester) async {
        final FindInPageController controller = FindInPageController();
        final ScrollController verticalController = ScrollController();
        final ScrollController horizontalController = ScrollController();
        addTearDown(controller.dispose);
        addTearDown(verticalController.dispose);
        addTearDown(horizontalController.dispose);

        await tester.binding.setSurfaceSize(const Size(400, 300));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: FindInPageScope(
              enableSelection: false,
              enableFind: true,
              controller: controller,
              child: SelectionArea(
                child: Scaffold(
                  body: SingleChildScrollView(
                    controller: verticalController,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 24, child: Text('Visible Target Alpha')),
                          const SizedBox(height: 24, child: Text('Visible Target Beta')),
                          const SizedBox(height: 500),
                          SingleChildScrollView(
                            controller: horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: const Row(
                              children: <Widget>[SizedBox(width: 700), Text('Far 2D Target Omega')],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(verticalController.offset, 0.0);
        expect(horizontalController.offset, 0.0);

        // Open search for 'Target'. Match 0 ('Visible Target Alpha') is already visible at top.
        controller.open(initialQuery: 'Target');
        await tester.pumpAndSettle();

        expect(controller.matchCount, 3);
        expect(controller.activeMatchIndex, 0);
        expect(verticalController.offset, 0.0);
        expect(horizontalController.offset, 0.0);

        // Step to Match 1 ('Visible Target Beta'), which is ALSO already inside the 400x300 viewport.
        // Scroll offset MUST remain 0.0 (zero scroll jitter).
        controller.nextMatch();
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 1);
        expect(verticalController.offset, 0.0);
        expect(horizontalController.offset, 0.0);

        // Step to Match 2 ('Far 2D Target Omega'), which is off-screen both vertically (y > 548)
        // and horizontally (x > 700). Verify BOTH ScrollControllers scroll > 0 to reveal the match!
        controller.nextMatch();
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 2);
        expect(verticalController.offset, greaterThan(200.0));
        expect(horizontalController.offset, greaterThan(300.0));
      },
    );

    testWidgets('7. FindInPageController exposes overridable shortcuts and semantic actions', (
      WidgetTester tester,
    ) async {
      // Override default shortcuts: map F4 -> FindNextMatchIntent, Shift+F4 -> FindPreviousMatchIntent,
      // and omit F3 so F3 is a no-op.
      final FindInPageController controller = FindInPageController(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.f4): FindNextMatchIntent(),
          SingleActivator(LogicalKeyboardKey.f4, shift: true): FindPreviousMatchIntent(),
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FindInPageScope(
            enableSelection: false,
            enableFind: true,
            controller: controller,
            child: const SelectionArea(
              child: Scaffold(
                body: Column(
                  children: <Widget>[Text('Alpha token'), Text('Beta token'), Text('Gamma token')],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.open(initialQuery: 'token');
      await tester.pumpAndSettle();
      expect(controller.matchCount, 3);
      expect(controller.activeMatchIndex, 0);

      // F3 was omitted from custom shortcuts, so pressing F3 should NOT advance the match.
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      expect(controller.activeMatchIndex, 0);

      // Custom shortcut F4 advances to next match (index 1).
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();
      expect(controller.activeMatchIndex, 1);

      // Custom shortcut Shift+F4 returns to previous match (index 0).
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(controller.activeMatchIndex, 0);

      // Updating controller.shortcuts dynamically restores defaultFindBarShortcuts (including F3).
      controller.shortcuts = FindInPageController.defaultFindBarShortcuts;
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      expect(controller.activeMatchIndex, 1);
    });
  });
}
