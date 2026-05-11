// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'clipboard_utils.dart';
import 'editable_text_tester.dart';
import 'editable_text_utils.dart';
import 'widgets_app_tester.dart';

void main() {
  const kGreyColor = Color(0xFFAAAAAA);
  const kRedColor = Color(0xFFFF0000);
  final mockClipboard = MockClipboard();
  TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    mockClipboard.handleMethodCall,
  );

  setUp(() async {
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  testWidgets('Hides and shows only a single menu', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();
    late final BuildContext context;

    await tester.pumpWidget(
      TestWidgetsApp(
        home: Builder(
          builder: (BuildContext localContext) {
            context = localContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(find.byKey(key1), findsNothing);
    expect(find.byKey(key2), findsNothing);

    final controller1 = ContextMenuController();
    await tester.pump();
    expect(find.byKey(key1), findsNothing);
    expect(find.byKey(key2), findsNothing);

    controller1.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return Placeholder(key: key1);
      },
    );
    await tester.pump();

    expect(find.byKey(key1), findsOneWidget);
    expect(find.byKey(key2), findsNothing);

    // Showing the same thing again does nothing and is not an error.
    controller1.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return Placeholder(key: key1);
      },
    );
    await tester.pump();

    expect(tester.takeException(), null);
    expect(find.byKey(key1), findsOneWidget);
    expect(find.byKey(key2), findsNothing);

    // Showing a new menu hides the first.
    final controller2 = ContextMenuController();
    controller2.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return Placeholder(key: key2);
      },
    );
    await tester.pump();

    expect(find.byKey(key1), findsNothing);
    expect(find.byKey(key2), findsOneWidget);

    controller2.remove();
    await tester.pump();

    expect(find.byKey(key1), findsNothing);
    expect(find.byKey(key2), findsNothing);
  });

  testWidgets('A menu can be hidden and then reshown', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    late final BuildContext context;

    await tester.pumpWidget(
      TestWidgetsApp(
        home: Builder(
          builder: (BuildContext localContext) {
            context = localContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(find.byKey(key1), findsNothing);

    final controller = ContextMenuController();
    addTearDown(controller.remove);

    // Instantiating the controller does not shown it.
    await tester.pump();
    expect(find.byKey(key1), findsNothing);

    controller.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return Placeholder(key: key1);
      },
    );
    await tester.pump();

    expect(find.byKey(key1), findsOneWidget);

    controller.remove();
    await tester.pump();

    expect(find.byKey(key1), findsNothing);

    controller.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return Placeholder(key: key1);
      },
    );
    await tester.pump();

    expect(find.byKey(key1), findsOneWidget);
  });

  testWidgets('markNeedsBuild causes the builder to update', (WidgetTester tester) async {
    var buildCount = 0;
    late final BuildContext context;

    await tester.pumpWidget(
      TestWidgetsApp(
        home: Builder(
          builder: (BuildContext localContext) {
            context = localContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final controller = ContextMenuController();
    controller.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        buildCount++;
        return const Placeholder();
      },
    );
    expect(buildCount, 0);
    await tester.pump();
    expect(buildCount, 1);

    controller.markNeedsBuild();
    expect(buildCount, 1);
    await tester.pump();
    expect(buildCount, 2);

    controller.remove();
  });

  testWidgets(
    'Calling show when a built-in widget is already showing its context menu hides the built-in menu',
    (WidgetTester tester) async {
      final GlobalKey builtInKey = GlobalKey();
      final GlobalKey directKey = GlobalKey();
      late final BuildContext context;

      final textEditingController = TextEditingController();
      addTearDown(textEditingController.dispose);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext localContext) {
              context = localContext;
              return EditableText(
                controller: textEditingController,
                backgroundCursorColor: kGreyColor,
                focusNode: focusNode,
                style: const TextStyle(),
                cursorColor: kRedColor,
                selectionControls: testTextSelectionHandleControls,
                contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                  return Placeholder(key: builtInKey);
                },
              );
            },
          ),
        ),
      );

      expect(find.byKey(builtInKey), findsNothing);
      expect(find.byKey(directKey), findsNothing);

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pump();
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(find.byKey(builtInKey), findsOneWidget);
      expect(find.byKey(directKey), findsNothing);

      final controller = ContextMenuController();
      controller.show(
        context: context,
        contextMenuBuilder: (BuildContext context) {
          return Placeholder(key: directKey);
        },
      );
      await tester.pump();

      expect(find.byKey(builtInKey), findsNothing);
      expect(find.byKey(directKey), findsOneWidget);
      expect(controller.isShown, isTrue);

      // And showing the built-in menu hides the directly shown menu.
      expect(state.showToolbar(), isTrue);
      await tester.pump();

      expect(find.byKey(builtInKey), findsOneWidget);
      expect(find.byKey(directKey), findsNothing);
      expect(controller.isShown, isFalse);

      // Calling remove on the hidden ContextMenuController does not hide the
      // built-in menu.
      controller.remove();
      await tester.pump();

      expect(find.byKey(builtInKey), findsOneWidget);
      expect(find.byKey(directKey), findsNothing);
      expect(controller.isShown, isFalse);

      state.hideToolbar();
      await tester.pump();
      expect(find.byKey(builtInKey), findsNothing);
      expect(find.byKey(directKey), findsNothing);
      expect(controller.isShown, isFalse);
    },
    // [intended] no Flutter-drawn text selection toolbar on web.
    skip: isContextMenuProvidedByPlatform,
  );

  testWidgets('ContextMenuController.show updates in-place', (WidgetTester tester) async {
    final controller = ContextMenuController();
    addTearDown(ContextMenuController.removeAny);

    await tester.pumpWidget(TestWidgetsApp(home: Container()));

    final BuildContext context = tester.element(find.byType(Container));

    // Show the menu with value 1.
    controller.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return const _StatefulMenu(value: 1);
      },
    );
    await tester.pump();

    expect(find.text('Initial: 1, Current: 1'), findsOneWidget);

    // Show the menu again with value 2.
    controller.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return const _StatefulMenu(value: 2);
      },
    );
    await tester.pump();

    // If it updates in-place, the state is preserved, so initialValue is still 1.
    // If it recreates the entry, the state is lost, so initialValue becomes 2.
    expect(find.text('Initial: 1, Current: 2'), findsOneWidget);

    controller.remove();
    await tester.pump();
  });

  testWidgets('ContextMenuController.show after remove creates a new overlay entry', (
    WidgetTester tester,
  ) async {
    final controller = ContextMenuController();
    addTearDown(ContextMenuController.removeAny);

    await tester.pumpWidget(TestWidgetsApp(home: Container()));

    final BuildContext context = tester.element(find.byType(Container));

    controller.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return const _StatefulMenu(value: 1);
      },
    );
    await tester.pump();

    expect(find.text('Initial: 1, Current: 1'), findsOneWidget);

    controller.remove();
    await tester.pump();

    expect(find.text('Initial: 1, Current: 1'), findsNothing);

    // After remove, show should create a fresh overlay entry (not update in-place).
    controller.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return const _StatefulMenu(value: 2);
      },
    );
    await tester.pump();

    // State is fresh (not preserved from the first show), so initialValue is 2.
    expect(find.text('Initial: 2, Current: 2'), findsOneWidget);

    controller.remove();
    await tester.pump();
  });
}

class _StatefulMenu extends StatefulWidget {
  const _StatefulMenu({required this.value});
  final int value;
  @override
  State<_StatefulMenu> createState() => _StatefulMenuState();
}

class _StatefulMenuState extends State<_StatefulMenu> {
  late int initialValue;
  @override
  void initState() {
    super.initState();
    initialValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Initial: $initialValue, Current: ${widget.value}',
      textDirection: TextDirection.ltr,
    );
  }
}
