// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../text.dart' show findRenderEditable, globalize, textOffsetToPosition;

void main() {

  // Returns true iff the button is visually enabled.
  bool appearsEnabled(WidgetTester tester, String text) {
    final CupertinoButton button = tester.widget<CupertinoButton>(

      find.ancestor(
        of: find.text(text),
        matching: find.byType(CupertinoButton),
      ),
    );
    // Disabled buttons have no opacity change when pressed.
    return button.pressedOpacity < 1.0;
  }

  group('canSelectAll', () {
    Widget createEditableText({
      Key key,
      String text,
      TextSelection selection,
    }) {
      final TextEditingController controller = TextEditingController(text: text)
        ..selection = selection ?? const TextSelection.collapsed(offset: -1);
      return CupertinoApp(
        home: EditableText(
          key: key,
          controller: controller,
          focusNode: FocusNode(),
          style: const TextStyle(),
          cursorColor: const Color.fromARGB(0, 0, 0, 0),
          backgroundCursorColor: const Color.fromARGB(0, 0, 0, 0),
        ),
      );
    }

    testWidgets('should return false when there is no text', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(key: key));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState), false);
    });

    testWidgets('should return true when there is text and collapsed selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState), true);
    });

    testWidgets('should return false when there is text and partial uncollapsed selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
        selection: const TextSelection(baseOffset: 1, extentOffset: 2),
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState), false);
    });

    testWidgets('should return false when there is text and full selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
        selection: const TextSelection(baseOffset: 0, extentOffset: 3),
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState), false);
    });
  });

  group('cupertino handles', () {
    testWidgets('draws transparent handle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(RepaintBoundary(
        child: CupertinoTheme(
          data: const CupertinoThemeData(
            primaryColor: Color(0x550000AA),
          ),
          child: Builder(
            builder: (BuildContext context) {
              return Container(
                color: CupertinoColors.white,
                height: 800,
                width: 800,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 250),
                  child: FittedBox(
                    child: cupertinoTextSelectionControls.buildHandle(
                      context,
                      TextSelectionHandleType.right,
                      10.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ));

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('text_selection.handle.transparent.png'),
      );
    });
  });

  group('Text selection menu overflow (iOS)', () {
    testWidgets('All menu items show when they fit.', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(text: 'abc def ghi');
      await tester.pumpWidget(CupertinoApp(
        home: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(800.0, 600.0)),
              child: Center(
                child: CupertinoTextField(
                  controller: controller,
                ),
              ),
            ),
          ),
      ));

      // Initially, the menu isn't shown at all.
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsNothing);

      // Long press on an empty space to show the selection menu.
      await tester.longPressAt(textOffsetToPosition(tester, 4));
      await tester.pump();
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsNothing);

      // Double tap to select a word and show the full selection menu.
      final Offset textOffset = textOffsetToPosition(tester, 1);
      await tester.tapAt(textOffset);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tapAt(textOffset);
      await tester.pumpAndSettle();

      // The full menu is shown without the navigation buttons.
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsNothing);
    }, skip: isBrowser, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

    testWidgets('When a menu item doesn\'t fit, a second page is used.', (WidgetTester tester) async {
      // Set the screen size to more narrow, so that Select All can't fit.
      tester.binding.window.physicalSizeTestValue = const Size(800, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final TextEditingController controller = TextEditingController(text: 'abc def ghi');
      await tester.pumpWidget(CupertinoApp(
        home: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(800.0, 600.0)),
              child: Center(
                child: CupertinoTextField(
                  controller: controller,
                ),
              ),
            ),
          ),
      ));

      // Initially, the menu isn't shown at all.
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsNothing);

      // Double tap to select a word and show the selection menu.
      final Offset textOffset = textOffsetToPosition(tester, 1);
      await tester.tapAt(textOffset);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tapAt(textOffset);
      await tester.pumpAndSettle();

      // The full menu is shown without the navigation buttons.
      // The last button is missing, and a next button is shown.
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);

      // Tapping the next button shows the overflowing button.
      await tester.tap(find.text('▶'));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsOneWidget);
      expect(appearsEnabled(tester, '◀'), true);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), false);

      // Tapping the back button shows the first page again.
      await tester.tap(find.text('◀'));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);
    }, skip: isBrowser, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

  /*
    testWidgets('A smaller menu bumps more items to the overflow menu.', (WidgetTester tester) async {
      // Set the screen size to more narrow, so that Copy and Paste can't fit.
      tester.binding.window.physicalSizeTestValue = const Size(680, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final TextEditingController controller = TextEditingController(text: 'abc def ghi');
      await tester.pumpWidget(CupertinoApp(
        home: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(800.0, 600.0)),
              child: Center(
                child: CupertinoTextField(
                  controller: controller,
                ),
              ),
            ),
          ),
      ));

      // Initially, the menu isn't shown at all.
      expect(find.byType(CupertinoButton), findsNothing);
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsNothing);

      // Double tap to select a word and show the selection menu.
      final Offset textOffset = textOffsetToPosition(tester, 1);
      await tester.tapAt(textOffset);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tapAt(textOffset);
      await tester.pumpAndSettle();

      // The full menu is shown without the navigation buttons.
      // The last button is missing, and a next button is shown.
      expect(find.byType(CupertinoButton), findsNWidgets(2));
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);

      // Tapping the next button shows Copy.
      await tester.tap(find.text('▶'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoButton), findsNWidgets(3));
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsOneWidget);
      expect(appearsEnabled(tester, '◀'), true);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);

      // Tapping the next button again shows Paste.
      await tester.tap(find.text('▶'));
      await tester.pumpAndSettle();
      // TODO(justinmc): Fails here, paste is missing.
      expect(find.byType(CupertinoButton), findsNWidgets(3));
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsOneWidget);
      expect(appearsEnabled(tester, '◀'), true);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), false);

      // Tapping the back button shows the second page again.
      await tester.tap(find.text('◀'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoButton), findsNWidgets(3));
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsOneWidget);
      expect(appearsEnabled(tester, '◀'), true);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);

      // Tapping the back button again shows the first page again.
      await tester.tap(find.text('◀'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoButton), findsNWidgets(2));
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);
    }, skip: isBrowser, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

    testWidgets('When the menu renders below the text, the overflow menu back button is at the top.', (WidgetTester tester) async {
      // Set the screen size to more narrow, so that Select All can't fit.
      tester.binding.window.physicalSizeTestValue = const Size(1000, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final TextEditingController controller = TextEditingController(text: 'abc def ghi');
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800.0, 600.0)),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                child: TextField(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      ));

      // Initially, the menu isn't shown at all.
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.byType(IconButton), findsNothing);

      // Long press to show the menu.
      final Offset textOffset = textOffsetToPosition(tester, 1);
      await tester.longPressAt(textOffset);
      await tester.pump();

      // The last button is missing, and a more button is shown.
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);
      expect(find.byType(IconButton), findsOneWidget);
      final Offset cutOffset = tester.getTopLeft(find.text('Cut'));

      // Tapping the button shows the overflow menu.
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);

      // The back button is at the top of the overflow menu.
      final Offset selectAllOffset = tester.getTopLeft(find.text('Select All'));
      final Offset moreOffset = tester.getTopLeft(find.byType(IconButton));
      expect(moreOffset.dy, lessThan(selectAllOffset.dy));

      // The overflow menu grows downward.
      expect(selectAllOffset.dy, greaterThan(cutOffset.dy));

      // Tapping the back button shows the selection menu again.
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);
      expect(find.byType(IconButton), findsOneWidget);
    }, skip: isBrowser, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

    testWidgets('When the menu items change, the menu is closed and _closedWidth reset.', (WidgetTester tester) async {
      // Set the screen size to more narrow, so that Select All can't fit.
      tester.binding.window.physicalSizeTestValue = const Size(1000, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final TextEditingController controller = TextEditingController(text: 'abc def ghi');
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800.0, 600.0)),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                child: TextField(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      ));

      // Initially, the menu isn't shown at all.
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.byType(IconButton), findsNothing);

      // Tap to place the cursor and tap again to show the menu without a
      // selection.
      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pumpAndSettle();
      final RenderEditable renderEditable = findRenderEditable(tester);
      final List<TextSelectionPoint> endpoints = globalize(
        renderEditable.getEndpointsForSelection(controller.selection),
        renderEditable,
      );
      expect(endpoints.length, 1);
      final Offset handlePos = endpoints[0].point + const Offset(0.0, 1.0);
      await tester.tapAt(handlePos, pointer: 7);
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);

      // Tap Select All and measure the usual position of Cut, without
      // _closedWidth having been used yet.
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      final Offset cutOffset = tester.getTopLeft(find.text('Cut'));

      // Tap to clear the selection.
      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.byType(IconButton), findsNothing);

      // Long press to show the menu.
      await tester.longPressAt(textOffsetToPosition(tester, 1));
      await tester.pump();

      // The last button is missing, and a more button is shown.
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);
      expect(find.byType(IconButton), findsOneWidget);

      // Tapping the button shows the overflow menu.
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);

      // Tapping Select All changes the menu items so that there is no no longer
      // any overflow.
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      final Offset newCutOffset = tester.getTopLeft(find.text('Cut'));
      expect(newCutOffset, equals(cutOffset));
    }, skip: isBrowser, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));
    */
  });
}
