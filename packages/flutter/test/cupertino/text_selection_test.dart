// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/editable_text_utils.dart' show textOffsetToPosition;

class MockClipboard {
  Object _clipboardData = <String, dynamic>{
    'text': null,
  };

  Future<dynamic> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = methodCall.arguments! as Object;
        break;
    }
  }
}

class _LongCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _LongCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<_LongCupertinoLocalizations> load(Locale locale) => _LongCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_LongCupertinoLocalizationsDelegate old) => false;

  @override
  String toString() => '_LongCupertinoLocalizations.delegate(en_US)';
}

class _LongCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _LongCupertinoLocalizations();

  @override
  String get cutButtonLabel => 'Cutttttttttttttttttttttttttttttttttttttttttttt';
  @override
  String get copyButtonLabel => 'Copyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy';
  @override
  String get pasteButtonLabel => 'Pasteeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
  @override
  String get selectAllButtonLabel => 'Select Allllllllllllllllllllllllllllllll';

  static Future<_LongCupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<_LongCupertinoLocalizations>(const _LongCupertinoLocalizations());
  }

  static const LocalizationsDelegate<CupertinoLocalizations> delegate = _LongCupertinoLocalizationsDelegate();
}

const _LongCupertinoLocalizations longLocalizations = _LongCupertinoLocalizations();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockClipboard mockClipboard = MockClipboard();
  SystemChannels.platform.setMockMethodCallHandler(mockClipboard.handleMethodCall);

  // Returns true iff the button is visually enabled.
  bool appearsEnabled(WidgetTester tester, String text) {
    final CupertinoButton button = tester.widget<CupertinoButton>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(CupertinoButton),
      ),
    );
    // Disabled buttons have no opacity change when pressed.
    return button.pressedOpacity! < 1.0;
  }

  group('canSelectAll', () {
    Widget createEditableText({
      Key? key,
      String? text,
      TextSelection? selection,
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
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState!), false);
    });

    testWidgets('should return true when there is text and collapsed selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState!), true);
    });

    testWidgets('should return false when there is text and partial uncollapsed selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
        selection: const TextSelection(baseOffset: 1, extentOffset: 2),
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState!), false);
    });

    testWidgets('should return false when there is text and full selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
        selection: const TextSelection(baseOffset: 0, extentOffset: 3),
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState!), false);
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

  // TODO(justinmc): https://github.com/flutter/flutter/issues/60145
  testWidgets('Paste always appears regardless of clipboard content on iOS', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            CupertinoTextField(
              controller: controller,
            ),
          ],
        ),
      ),
    );

    // Make sure the clipboard is empty to start.
    await Clipboard.setData(const ClipboardData(text: ''));

    // Double tap to select the first word.
    const int index = 4;
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pumpAndSettle();
    expect(controller.selection.isCollapsed, isFalse);
    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, 7);

    // Paste is showing even though clipboard is empty.
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Cut'), findsOneWidget);
    expect(find.descendant(
      of: find.byType(Overlay),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_TextSelectionHandleOverlay'),
    ), findsNWidgets(2));

    // Tap copy to add something to the clipboard and close the menu.
    await tester.tapAt(tester.getCenter(find.text('Copy')));
    await tester.pumpAndSettle();

    // The menu is gone, but the handles are visible on the existing selection.
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Cut'), findsNothing);
    expect(find.text('Paste'), findsNothing);
    expect(controller.selection.isCollapsed, isFalse);
    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, 7);
    expect(find.descendant(
      of: find.byType(Overlay),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_TextSelectionHandleOverlay'),
    ), findsNWidgets(2));

    // Double tap to show the menu again.
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pumpAndSettle();

    // Paste still shows.
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Cut'), findsOneWidget);
  },
    skip: isBrowser, // We do not use Flutter-rendered context menu on the Web
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }),
  );

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
      await tester.pumpAndSettle();
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
    },
      skip: isBrowser, // We do not use Flutter-rendered context menu on the Web
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }),
    );

    testWidgets('When a menu item doesn\'t fit, a second page is used.', (WidgetTester tester) async {
      // Set the screen size to more narrow, so that Paste can't fit.
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
    },
      skip: isBrowser, // We do not use Flutter-rendered context menu on the Web
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }),
    );

    testWidgets('A smaller menu puts each button on its own page.', (WidgetTester tester) async {
      // Set the screen size to more narrow, so that two buttons can't fit on
      // the same page.
      tester.binding.window.physicalSizeTestValue = const Size(640, 800);
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

      // Only the first button fits, and a next button is shown.
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
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);
    },
      skip: isBrowser, // We do not use Flutter-rendered context menu on the Web
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }),
    );

    testWidgets('Handles very long locale strings', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(text: 'abc def ghi');
      await tester.pumpWidget(CupertinoApp(
        locale: const Locale('en', 'us'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _LongCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
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
      expect(find.text(longLocalizations.cutButtonLabel), findsNothing);
      expect(find.text(longLocalizations.copyButtonLabel), findsNothing);
      expect(find.text(longLocalizations.pasteButtonLabel), findsNothing);
      expect(find.text(longLocalizations.selectAllButtonLabel), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsNothing);

      // Long press on an empty space to show the selection menu, with only the
      // paste button visible.
      await tester.longPressAt(textOffsetToPosition(tester, 4));
      await tester.pumpAndSettle();
      expect(find.text(longLocalizations.cutButtonLabel), findsNothing);
      expect(find.text(longLocalizations.copyButtonLabel), findsNothing);
      expect(find.text(longLocalizations.pasteButtonLabel), findsOneWidget);
      expect(find.text(longLocalizations.selectAllButtonLabel), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);

      // Tap next to go to the second and final page.
      await tester.tap(find.text('▶'));
      await tester.pumpAndSettle();
      expect(find.text(longLocalizations.cutButtonLabel), findsNothing);
      expect(find.text(longLocalizations.copyButtonLabel), findsNothing);
      expect(find.text(longLocalizations.pasteButtonLabel), findsNothing);
      expect(find.text(longLocalizations.selectAllButtonLabel), findsOneWidget);
      expect(find.text('◀'), findsOneWidget);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '◀'), true);
      expect(appearsEnabled(tester, '▶'), false);

      // Tap select all to show the full selection menu.
      await tester.tap(find.text(longLocalizations.selectAllButtonLabel));
      await tester.pumpAndSettle();

      // Only one button fits on each page.
      expect(find.text(longLocalizations.cutButtonLabel), findsOneWidget);
      expect(find.text(longLocalizations.copyButtonLabel), findsNothing);
      expect(find.text(longLocalizations.pasteButtonLabel), findsNothing);
      expect(find.text(longLocalizations.selectAllButtonLabel), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);

      // Tap next to go to the second page.
      await tester.tap(find.text('▶'));
      await tester.pumpAndSettle();
      expect(find.text(longLocalizations.cutButtonLabel), findsNothing);
      expect(find.text(longLocalizations.copyButtonLabel), findsOneWidget);
      expect(find.text(longLocalizations.pasteButtonLabel), findsNothing);
      expect(find.text(longLocalizations.selectAllButtonLabel), findsNothing);
      expect(find.text('◀'), findsOneWidget);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '◀'), true);
      expect(appearsEnabled(tester, '▶'), true);

      // Tap next to go to the third and final page.
      await tester.tap(find.text('▶'));
      await tester.pumpAndSettle();
      expect(find.text(longLocalizations.cutButtonLabel), findsNothing);
      expect(find.text(longLocalizations.copyButtonLabel), findsNothing);
      expect(find.text(longLocalizations.pasteButtonLabel), findsOneWidget);
      expect(find.text(longLocalizations.selectAllButtonLabel), findsNothing);
      expect(find.text('◀'), findsOneWidget);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '◀'), true);
      expect(appearsEnabled(tester, '▶'), false);

      // Tap back to go to the second page again.
      await tester.tap(find.text('◀'));
      await tester.pumpAndSettle();
      expect(find.text(longLocalizations.cutButtonLabel), findsNothing);
      expect(find.text(longLocalizations.copyButtonLabel), findsOneWidget);
      expect(find.text(longLocalizations.pasteButtonLabel), findsNothing);
      expect(find.text(longLocalizations.selectAllButtonLabel), findsNothing);
      expect(find.text('◀'), findsOneWidget);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '◀'), true);
      expect(appearsEnabled(tester, '▶'), true);

      // Tap back to go to the first page again.
      await tester.tap(find.text('◀'));
      await tester.pumpAndSettle();
      expect(find.text(longLocalizations.cutButtonLabel), findsOneWidget);
      expect(find.text(longLocalizations.copyButtonLabel), findsNothing);
      expect(find.text(longLocalizations.pasteButtonLabel), findsNothing);
      expect(find.text(longLocalizations.selectAllButtonLabel), findsNothing);
      expect(find.text('◀'), findsNothing);
      expect(find.text('▶'), findsOneWidget);
      expect(appearsEnabled(tester, '▶'), true);
    },
      skip: isBrowser, // We do not use Flutter-rendered context menu on the Web
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }),
    );
  });
}
