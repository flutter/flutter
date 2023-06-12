import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('creates a focus node and disposes it', (tester) async {
    late FocusNode focusNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusNode = useFocusNode();
        return Container();
      }),
    );

    expect(focusNode, isA<FocusNode>());
    // ignore: invalid_use_of_protected_member
    expect(focusNode.hasListeners, isFalse);

    final previousValue = focusNode;

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusNode = useFocusNode();
        return Container();
      }),
    );

    expect(previousValue, focusNode);
    // ignore: invalid_use_of_protected_member
    expect(focusNode.hasListeners, isFalse);

    await tester.pumpWidget(Container());

    expect(
      // ignore: invalid_use_of_protected_member
      () => focusNode.hasListeners,
      throwsAssertionError,
    );
  });

  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useFocusNode();
        return const SizedBox();
      }),
    );

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useFocusNode: FocusNode#00000\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('default values matches with FocusNode', (tester) async {
    final official = FocusNode();

    late FocusNode focusNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusNode = useFocusNode();
        return Container();
      }),
    );

    expect(focusNode.debugLabel, official.debugLabel);
    expect(focusNode.onKey, official.onKey);
    expect(focusNode.skipTraversal, official.skipTraversal);
    expect(focusNode.canRequestFocus, official.canRequestFocus);
    expect(focusNode.descendantsAreFocusable, official.descendantsAreFocusable);
  });

  testWidgets('has all the FocusNode parameters', (tester) async {
    KeyEventResult onKey(FocusNode node, RawKeyEvent event) =>
        KeyEventResult.ignored;

    KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) =>
        KeyEventResult.ignored;

    late FocusNode focusNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusNode = useFocusNode(
          debugLabel: 'Foo',
          onKey: onKey,
          onKeyEvent: onKeyEvent,
          skipTraversal: true,
          canRequestFocus: false,
          descendantsAreFocusable: false,
        );
        return Container();
      }),
    );

    expect(focusNode.debugLabel, 'Foo');
    expect(focusNode.onKey, onKey);
    expect(focusNode.onKeyEvent, onKeyEvent);
    expect(focusNode.skipTraversal, true);
    expect(focusNode.canRequestFocus, false);
    expect(focusNode.descendantsAreFocusable, false);
  });

  testWidgets('handles parameter change', (tester) async {
    KeyEventResult onKey(FocusNode node, RawKeyEvent event) =>
        KeyEventResult.ignored;
    KeyEventResult onKey2(FocusNode node, RawKeyEvent event) =>
        KeyEventResult.ignored;

    KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) =>
        KeyEventResult.ignored;
    KeyEventResult onKeyEvent2(FocusNode node, KeyEvent event) =>
        KeyEventResult.ignored;

    late FocusNode focusNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusNode = useFocusNode(
          debugLabel: 'Foo',
          onKey: onKey,
          onKeyEvent: onKeyEvent,
          skipTraversal: true,
          canRequestFocus: false,
          descendantsAreFocusable: false,
        );

        return Container();
      }),
    );

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusNode = useFocusNode(
          debugLabel: 'Bar',
          onKey: onKey2,
          onKeyEvent: onKeyEvent2,
        );

        return Container();
      }),
    );

    expect(focusNode.onKey, onKey2);
    expect(focusNode.onKeyEvent, onKeyEvent2);
    expect(focusNode.debugLabel, 'Bar');
    expect(focusNode.skipTraversal, false);
    expect(focusNode.canRequestFocus, true);
    expect(focusNode.descendantsAreFocusable, true);
  });
}
