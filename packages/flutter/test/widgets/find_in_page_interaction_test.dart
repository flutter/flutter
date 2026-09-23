// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp({
  required Widget child,
  FindInPageController? controller,
  bool enableSelection = false,
  bool enableFind = true,
  ValueChanged<SelectedContent?>? onSelectionChanged,
}) {
  return WidgetsApp(
    color: const Color(0xFF0B57D0),
    builder: (BuildContext context, Widget? navigator) {
      return Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) {
              return FindInPageScope(
                enableSelection: enableSelection,
                enableFind: enableFind,
                controller: controller,
                child: SelectableRegion(
                  selectionControls: emptyTextSelectionControls,
                  onSelectionChanged: onSelectionChanged,
                  child: child,
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

void main() {
  group('Find-in-Page Non-Golden Interaction & State-Machine Tests', () {
    testWidgets(
      '1. Incremental typing ("flu" -> "flut" -> "flu") preserves active match anchor and advances forward in reading order',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildTestApp(
            controller: controller,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('0: flute prelude'),
                Text('1: fluid dynamics'),
                Text('2: fluke occurrence'),
                Text('3: flutter framework'),
              ],
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
        final controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildTestApp(
            controller: controller,
            child: const Column(
              children: <Widget>[Text('Alpha Dart'), Text('Beta Dart'), Text('Gamma Dart')],
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
        // Part A: enableSelection: true (transfers active match into SelectableRegion selection).
        final selectableController = FindInPageController();
        addTearDown(selectableController.dispose);

        await tester.pumpWidget(
          _buildTestApp(
            enableSelection: true,
            controller: selectableController,
            child: const Column(
              children: <Widget>[Text('First Skwasm item'), Text('Second Skwasm item')],
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
        final findOnlyController = FindInPageController();
        addTearDown(findOnlyController.dispose);

        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF0B57D0),
            onGenerateRoute: (RouteSettings settings) {
              return PageRouteBuilder<void>(
                pageBuilder:
                    (
                      BuildContext context,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                    ) {
                      return SelectableRegion.findOnly(
                        findController: findOnlyController,
                        child: const Column(
                          children: <Widget>[
                            Text('First Impeller item'),
                            Text('Second Impeller item'),
                          ],
                        ),
                      );
                    },
              );
            },
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
        final controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildTestApp(
            enableSelection: true,
            controller: controller,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Line 0: CanvasKit renderer'),
                Text('Line 1: CanvasKit pipeline'),
                Text('Line 2: CanvasKit compositor'),
              ],
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
        final controller = FindInPageController();
        addTearDown(controller.dispose);

        var dynamicLine = 'Status: healthy';
        var showThirdLine = true;
        late StateSetter outerSetState;

        await tester.pumpWidget(
          _buildTestApp(
            controller: controller,
            child: StatefulBuilder(
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
        expect(controller.activeMatchIndex, 3);
        outerSetState(() {
          showThirdLine = false;
        });
        await tester.pumpAndSettle();

        expect(controller.matchCount, 3);
        expect(controller.activeMatchIndex, 2);
      },
    );

    testWidgets(
      '6. Viewport scroll invariants: zero scroll jitter when activeMatch is already visible, and dual-axis (2D) auto-scroll when off-screen',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        final verticalController = ScrollController();
        final horizontalController = ScrollController();
        addTearDown(controller.dispose);
        addTearDown(verticalController.dispose);
        addTearDown(horizontalController.dispose);

        await tester.binding.setSurfaceSize(const Size(400, 300));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildTestApp(
            controller: controller,
            child: SingleChildScrollView(
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
      final controller = FindInPageController(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.f4): FindNextMatchIntent(),
          SingleActivator(LogicalKeyboardKey.f4, shift: true): FindPreviousMatchIntent(),
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildTestApp(
          controller: controller,
          child: const Column(
            children: <Widget>[Text('Alpha token'), Text('Beta token'), Text('Gamma token')],
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

    testWidgets(
      '8. Clicking FindBar Next/Prev/Aa/X buttons when enableSelection: true preserves FindBar focus, avoids background selection leaks, and fires onSelectionChanged on close',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        addTearDown(controller.dispose);
        final recordedSelections = <String?>[];

        await tester.pumpWidget(
          _buildTestApp(
            enableSelection: true,
            controller: controller,
            onSelectionChanged: (SelectedContent? content) {
              recordedSelections.add(content?.plainText);
            },
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Alpha Engine token'),
                Text('Beta Engine token'),
                Text('Gamma engine token'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.open(initialQuery: 'Engine');
        await tester.pumpAndSettle();

        final EditableText findInput = tester.widget<EditableText>(
          find.descendant(
            of: find.byType(SelectableRegionFindBar),
            matching: find.byType(EditableText),
          ),
        );
        expect(findInput.focusNode.hasFocus, isTrue);
        expect(controller.matchCount, 3);
        expect(controller.activeMatchIndex, 0);

        // Click '↓' (next match) button with mouse while enableSelection: true.
        // FindBar EditableText MUST retain focus so subsequent Enter key events still work.
        await tester.tap(find.text('↓', findRichText: true));
        await tester.pumpAndSettle();
        expect(controller.activeMatchIndex, 1);
        expect(findInput.focusNode.hasFocus, isTrue);

        // Click 'Aa' (case-sensitive toggle) -> matches drop from 3 to 2 ('Alpha Engine', 'Beta Engine').
        await tester.tap(find.text('Aa', findRichText: true));
        await tester.pumpAndSettle();
        expect(controller.caseSensitive, isTrue);
        expect(controller.matchCount, 2);
        expect(controller.activeMatchIndex, 1);
        expect(findInput.focusNode.hasFocus, isTrue);

        // Click '×' (close) button with mouse -> closes FindBar, selects active match ('Engine' in Beta),
        // and fires SelectableRegion.onSelectionChanged!
        await tester.tap(find.text('×', findRichText: true));
        await tester.pumpAndSettle();
        expect(controller.isOpen, isFalse);
        expect(recordedSelections, contains('Engine'));
      },
    );

    testWidgets(
      r'9. Unicode case-insensitive search handles length-changing characters (Turkish dotted İ -> i\u0307) without RangeError or offset drift',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildTestApp(
            enableSelection: true,
            controller: controller,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[Text('İstanbul İİİ flutter'), Text('Emoji 🚀🔥 flutter')],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 'İ'.toLowerCase() is 2 UTF-16 code units ('i\u0307'), whereas 'İ' is 1 code unit.
        // Searching for 'flutter' at the end of 'İstanbul İİİ flutter' must NOT throw RangeError
        // and must highlight the exact UTF-16 range 13..20 ('flutter').
        controller.open(initialQuery: 'flutter');
        await tester.pumpAndSettle();

        expect(controller.matchCount, 2);
        expect(controller.matches[0].text, 'flutter');
        expect(
          controller.matches[0].range,
          const SelectedContentRange(startOffset: 13, endOffset: 20),
        );
        expect(controller.matches[1].text, 'flutter');
      },
    );

    testWidgets(
      '10. Multi-line Text.rich with inline WidgetSpan orders matches in true visual reading order',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.binding.setSurfaceSize(const Size(320, 300));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildTestApp(
            controller: controller,
            child: const SizedBox(
              width: 280,
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: 'Start token1 '),
                    WidgetSpan(child: Text('Inline token2 chip')),
                    TextSpan(
                      text: ' and a long trailing sentence that wraps onto the second line with token3 at the end.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.open(initialQuery: 'token');
        await tester.pumpAndSettle();

        expect(controller.matchCount, 3);
        // Match 0 is in fragment 0 ('Start token1 '), Match 1 is in WidgetSpan ('Inline token2 chip'),
        // and Match 2 is in fragment 1 on the wrapped second line ('... token3 at the end.').
        expect(
          controller.matches.map((SelectableSearchMatch m) => m.selectable.getPlainText()).toList(),
          <String>[
            'Start token1 ',
            'Inline token2 chip',
            ' and a long trailing sentence that wraps onto the second line with token3 at the end.',
          ],
        );
      },
    );

    testWidgets(
      '11. Descendant EditableText(autofocus: true) inside SelectableRegion retains primary autofocus on mount',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        final childFocusNode = FocusNode(debugLabel: 'ChildEditableText');
        final childTextController = TextEditingController();
        addTearDown(controller.dispose);
        addTearDown(childFocusNode.dispose);
        addTearDown(childTextController.dispose);

        await tester.pumpWidget(
          _buildTestApp(
            enableSelection: true,
            controller: controller,
            child: Column(
              children: <Widget>[
                const Text('Searchable header text'),
                EditableText(
                  controller: childTextController,
                  focusNode: childFocusNode,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
                  cursorColor: const Color(0xFF000000),
                  backgroundCursorColor: const Color(0xFF888888),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // SelectableRegion must NOT steal or discard childFocusNode's autofocus request.
        expect(childFocusNode.hasPrimaryFocus, isTrue);
      },
    );

    testWidgets(
      '12. Selection seeding with leading whitespace anchors to selected occurrence and re-focuses FindBar when already open',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildTestApp(
            enableSelection: true,
            controller: controller,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[Text('Row 0: WasmGC engine'), Text('Row 1: WasmGC runtime')],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open FindBar initially with 'Row'.
        controller.open(initialQuery: 'Row');
        await tester.pumpAndSettle();
        expect(controller.query, 'Row');

        // Now select ' WasmGC ' (with leading and trailing spaces, offset 6..14) in Row 1,
        // which also moves focus away from the FindBar.
        final SelectableRegionState regionState = tester.state<SelectableRegionState>(
          find.byType(SelectableRegion),
        );
        final List<Selectable> leaves = regionState.selectionDelegate.getLeafSelectables();
        regionState.selectionDelegate.selectRangeForSelectable(
          leaves[1],
          const SelectedContentRange(startOffset: 6, endOffset: 14),
        );
        regionState.widget.focusNode?.requestFocus();
        await tester.pump();

        // Invoke controller.open() (Cmd+F) while FindBar is already open.
        controller.open();
        await tester.pumpAndSettle();

        expect(controller.query, 'WasmGC');
        expect(controller.activeMatchIndex, 1);
        final EditableText findInput = tester.widget<EditableText>(
          find.descendant(
            of: find.byType(SelectableRegionFindBar),
            matching: find.byType(EditableText),
          ),
        );
        expect(findInput.focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      '13. FindInPageController detach, enableFind: false toggle, and dispose clean up highlights cleanly',
      (WidgetTester tester) async {
        final controller1 = FindInPageController();
        final controller2 = FindInPageController();
        addTearDown(controller2.dispose);

        var activeController = controller1;
        var enableFind = true;
        late StateSetter outerSetState;

        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF0B57D0),
            builder: (BuildContext context, Widget? navigator) {
              return Overlay(
                initialEntries: <OverlayEntry>[
                  OverlayEntry(
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          outerSetState = setState;
                          return FindInPageScope(
                            controller: activeController,
                            enableFind: enableFind,
                            child: SelectableRegion(
                              selectionControls: emptyTextSelectionControls,
                              child: const Text('Persistent highlight check'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        controller1.open(initialQuery: 'highlight');
        await tester.pumpAndSettle();
        expect(controller1.matchCount, 1);

        // Swap controller1 -> controller2 and dispose controller1.
        outerSetState(() {
          activeController = controller2;
        });
        await tester.pumpAndSettle();
        controller1.dispose();

        // Now open controller2 and toggle enableFind -> false while open.
        controller2.open(initialQuery: 'highlight');
        await tester.pumpAndSettle();
        expect(controller2.isOpen, isTrue);

        outerSetState(() {
          enableFind = false;
        });
        await tester.pumpAndSettle();

        expect(controller2.isOpen, isFalse);
        expect(find.byType(SelectableRegionFindBar), findsNothing);
      },
    );

    testWidgets(
      '14. DefaultSelectionStyle searchHighlightColor/activeSearchHighlightColor, open()/close() selection orthogonality, and alwaysNeedsCompositing optimization',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        addTearDown(controller.dispose);
        SelectedContent? currentSelection;

        const customPassive = Color(0x5500FF00);
        const customActive = Color(0xAAFF00FF);

        await tester.pumpWidget(
          DefaultSelectionStyle(
            searchHighlightColor: customPassive,
            activeSearchHighlightColor: customActive,
            child: _buildTestApp(
              enableSelection: true,
              controller: controller,
              onSelectionChanged: (SelectedContent? content) {
                currentSelection = content;
              },
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[Text('Line one target word\nLine two target word')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify DefaultSelectionStyle colors propagate to RenderParagraph and alwaysNeedsCompositing is false when unselected!
        final RenderParagraph firstParagraph = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text('Line one target word\nLine two target word'),
            matching: find.byType(RichText),
          ),
        );
        expect(firstParagraph.searchHighlightColor, customPassive);
        expect(firstParagraph.activeSearchHighlightColor, customActive);
        expect(firstParagraph.alwaysNeedsCompositing, isFalse);

        // 2. Select all (multi-line selection across both lines) and verify open() clears the multi-line selection!
        final SelectableRegionState regionState = tester.state<SelectableRegionState>(
          find.byType(SelectableRegion),
        );
        regionState.selectAll();
        await tester.pumpAndSettle();
        expect(currentSelection?.plainText, contains('\n'));
        expect(firstParagraph.alwaysNeedsCompositing, isTrue);

        controller.open(initialQuery: 'target');
        await tester.pumpAndSettle();
        expect(currentSelection, isNull);
        expect(firstParagraph.alwaysNeedsCompositing, isFalse);

        // 3. Make a manual selection while the FindBar is open, then call close() -> manual selection is preserved!
        regionState.selectAll();
        await tester.pumpAndSettle();
        expect(currentSelection?.plainText, contains('Line one target word'));

        controller.close();
        await tester.pumpAndSettle();
        expect(currentSelection?.plainText, contains('Line one target word'));
      },
    );

    testWidgets(
      '15. Viewport Scanner Mode (scannerCacheExtent) prevents ListView match-count drop (26 -> 12) when scrolling down and finds unmounted top WidgetSpan when searching upward from bottom',
      (WidgetTester tester) async {
        final controller = FindInPageController();
        final scrollController = ScrollController();
        addTearDown(controller.dispose);
        addTearDown(scrollController.dispose);

        await tester.binding.setSurfaceSize(const Size(400, 300));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildTestApp(
            enableSelection: true,
            controller: controller,
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                controller: scrollController,
                cacheExtent: 250.0,
                itemCount: 26,
                itemExtent: 120.0,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(text: 'Header '),
                            WidgetSpan(child: Text('Top WidgetSpan needle')),
                          ],
                        ),
                      ),
                    );
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Row #$index needle item'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final RenderViewport viewport = tester.renderObject<RenderViewport>(find.byType(Viewport));
        expect(viewport.cacheExtent, 250.0);

        // Part A (Harry's scenario): Open FindBar at top with 'needle'.
        // Scanner Mode expands cacheExtent so all 26 items are laid out and discovered!
        controller.open(initialQuery: 'needle');
        await tester.pumpAndSettle();
        expect(viewport.cacheExtent, FindInPageController.defaultScannerCacheExtent);
        expect(controller.matchCount, 26);
        expect(controller.activeMatchIndex, 0);

        // Step all the way down to match 26 (index 25) at the bottom of the 3,120px ListView.
        for (var i = 1; i < 26; i++) {
          controller.nextMatch();
          await tester.pumpAndSettle();
          // Match count MUST remain 26 (never dropping to 12 as top items scroll past 250px)!
          expect(controller.matchCount, 26);
          expect(controller.activeMatchIndex, i);
        }
        expect(scrollController.offset, greaterThan(2400.0));

        // Pressing nextMatch() on match 26 / 26 MUST wrap around to match 1 (index 0) at the very top!
        controller.nextMatch();
        await tester.pumpAndSettle();
        expect(controller.matchCount, 26);
        expect(controller.activeMatchIndex, 0);
        expect(scrollController.offset, lessThan(50.0));

        // Close FindBar -> restores original cacheExtent (250.0).
        controller.close();
        await tester.pumpAndSettle();
        expect(viewport.cacheExtent, 250.0);

        // Part B (David's scenario): Scroll to the very bottom while FindBar is CLOSED.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(scrollController.offset, greaterThan(2700.0));
        // Confirm that with cacheExtent: 250.0, item 0 ('Top WidgetSpan needle') is unmounted!
        expect(find.text('Top WidgetSpan needle'), findsNothing);

        // Now open FindBar at the bottom searching upward for 'WidgetSpan'!
        controller.open(initialQuery: 'WidgetSpan');
        await tester.pumpAndSettle();

        // Scanner Mode lays out the off-screen top items, finds 'WidgetSpan' at index 0,
        // and scrolls the ListView all the way UP to the top!
        expect(controller.matchCount, 1);
        expect(controller.activeMatchIndex, 0);
        expect(scrollController.offset, lessThan(50.0));
        expect(find.text('Top WidgetSpan needle'), findsOneWidget);

        controller.close();
        await tester.pumpAndSettle();
        expect(viewport.cacheExtent, 250.0);
      },
    );
  });
}
