// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'clipboard_utils.dart';
import 'editable_text_utils.dart';

void main() {
  final MockClipboard mockClipboard = MockClipboard();
  TestWidgetsFlutterBinding.ensureInitialized()
    .defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, mockClipboard.handleMethodCall);

  setUp(() async {
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  testWidgets('Builds the correct button items per-platform', (WidgetTester tester) async {
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
                return EditableTextContextMenuButtonItemsBuilder(
                  editableTextState: editableTextState,
                  builder: (BuildContext context, List<ContextMenuButtonItem> buttonItems) {
                    buttonTypes = buttonItems
                      .map((ContextMenuButtonItem buttonItem) => buttonItem.type)
                      .toSet();
                    return const SizedBox.shrink();
                  },
                );
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
}
