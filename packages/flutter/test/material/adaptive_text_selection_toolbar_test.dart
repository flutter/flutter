// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/clipboard_utils.dart';
import '../widgets/editable_text_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockClipboard mockClipboard = MockClipboard();
  TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, mockClipboard.handleMethodCall);

  testWidgets('Builds the right toolbar on each platform, including web, and shows buttonItems', (WidgetTester tester) async {
    const String buttonText = 'Click me';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveTextSelectionToolbar.buttonItems(
              primaryAnchor: Offset.zero,
              buttonItems: <ContextMenuButtonItem>[
                ContextMenuButtonItem(
                  label: buttonText,
                  onPressed: () {
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text(buttonText), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(find.byType(TextSelectionToolbar), findsOneWidget);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
        break;
      case TargetPlatform.iOS:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsOneWidget);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
        break;
      case TargetPlatform.macOS:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsOneWidget);
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsOneWidget);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
        break;
    }
  },
    variant: TargetPlatformVariant.all(),
    skip: isBrowser, // [intended] see https://github.com/flutter/flutter/issues/108382
  );

  testWidgets('Can build children directly as well', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveTextSelectionToolbar(
              primaryAnchor: Offset.zero,
              children: <Widget>[
                Container(key: key),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(key), findsOneWidget);
  });

  group('buttonItems', () {
    testWidgets('Builds the correct button items per-platform', (WidgetTester tester) async {
      // Fill the clipboard so that the Paste option is available in the text
      // selection menu.
      await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));

      Set<ContextMenuButtonType> buttonTypes = <ContextMenuButtonType>{};
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EditableText(
                controller: controller,
                backgroundCursorColor: Colors.grey,
                focusNode: FocusNode(),
                style: const TextStyle(),
                cursorColor: Colors.red,
                selectionControls: materialTextSelectionHandleControls,
                contextMenuBuilder: (
                  BuildContext context,
                  EditableTextState editableTextState,
                  Offset primaryOffset,
                  [Offset? secondaryOffset]
                ) {
                  final List<ContextMenuButtonItem> buttonItems =
                      AdaptiveTextSelectionToolbar.getEditableTextButtonItems(
                        editableTextState,
                      );
                  buttonTypes = buttonItems
                    .map((ContextMenuButtonItem buttonItem) => buttonItem.type)
                    .toSet();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      final EditableTextState state =
          tester.state<EditableTextState>(find.byType(EditableText));

      // With no text in the field.
      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pump();
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(buttonTypes, isNot(contains(ContextMenuButtonType.cut)));
      expect(buttonTypes, isNot(contains(ContextMenuButtonType.copy)));
      expect(buttonTypes, contains(ContextMenuButtonType.paste));
      expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));

      // With text but no selection.
      controller.text = 'lorem ipsum';
      await tester.pump();

      expect(buttonTypes, isNot(contains(ContextMenuButtonType.cut)));
      expect(buttonTypes, isNot(contains(ContextMenuButtonType.copy)));
      expect(buttonTypes, contains(ContextMenuButtonType.paste));

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(buttonTypes, contains(ContextMenuButtonType.selectAll));
          break;
        case TargetPlatform.macOS:
          expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));
          break;
      }

      // With text and selection.
      controller.value = controller.value.copyWith(
        selection: const TextSelection(
          baseOffset: 0,
          extentOffset: 'lorem'.length,
        ),
      );
      await tester.pump();

      expect(buttonTypes, contains(ContextMenuButtonType.cut));
      expect(buttonTypes, contains(ContextMenuButtonType.copy));
      expect(buttonTypes, contains(ContextMenuButtonType.paste));

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(buttonTypes, contains(ContextMenuButtonType.selectAll));
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));
          break;
      }
    },
      variant: TargetPlatformVariant.all(),
      skip: kIsWeb, // [intended]
    );
  });
}
