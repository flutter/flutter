// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Offset textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
  final Offset localOffset = paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
  return paragraph.localToGlobal(localOffset);
}

Offset globalize(Offset point, RenderBox box) {
  return box.localToGlobal(point);
}

void main() {
  testWidgets('can get selected content', (WidgetTester tester) async {
    final UniqueKey spy = UniqueKey();
    await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: SelectionSpy(key: spy),
          ),
        )
    );
    final SelectableRegionState state = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
    expect(state.getSelectedContent()!.plainText, renderSelectionSpy.getSelectedContent()!.plainText);
  });

  testWidgets('can select-all', (WidgetTester tester) async {
    final UniqueKey spy = UniqueKey();
    await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: SelectionSpy(key: spy),
          ),
        )
    );
    final SelectableRegionState state = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    state.selectAll();
    final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
    expect(renderSelectionSpy.events.length, 2);
    expect(renderSelectionSpy.events[0], isA<ClearSelectionEvent>());
    expect(renderSelectionSpy.events[1], isA<SelectAllSelectionEvent>());
  });

  testWidgets('select all with text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectableRegion(
          focusNode: FocusNode(),
          selectionControls: materialTextSelectionControls,
          child: Column(
            children: const <Widget>[
              Text('How are you?'),
              Text('Good, and you?'),
              Text('Fine, thank you.'),
            ],
          ),
        ),
      ),
    );
    final SelectableRegionState state = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    state.selectAll();

    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 16));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 12));
  });

  testWidgets('mouse can select multiple widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectableRegion(
          focusNode: FocusNode(),
          selectionControls: materialTextSelectionControls,
          child: Column(
            children: const <Widget>[
              Text('How are you?'),
              Text('Good, and you?'),
              Text('Fine, thank you.'),
            ],
          ),
        ),
      ),
    );

    final SelectableRegionState state = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
    state.selectStartTo(offset: textOffsetToPosition(paragraph1, 2));
    await tester.pump();


    state.selectEndTo(offset: textOffsetToPosition(paragraph1, 4));
    await tester.pump();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
    state.selectEndTo(offset: textOffsetToPosition(paragraph2, 5));
    await tester.pump();
    // Should select the rest of paragraph 1.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
    state.selectEndTo(offset: textOffsetToPosition(paragraph3, 6));
    await tester.pump();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
  });

  testWidgets('touch long press sends select-word event', (WidgetTester tester) async {
    final UniqueKey spy = UniqueKey();
    await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: SelectionSpy(key: spy),
          ),
        )
    );
    final SelectableRegionState state = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
    renderSelectionSpy.events.clear();
    state.selectWordAt(offset: const Offset(200.0, 200.0));
    expect(renderSelectionSpy.events.length, 1);
    expect(renderSelectionSpy.events[0], isA<SelectWordSelectionEvent>());
    final SelectWordSelectionEvent selectionEvent = renderSelectionSpy.events[0] as SelectWordSelectionEvent;
    expect(selectionEvent.globalPosition, const Offset(200.0, 200.0));
  });

  testWidgets('clears selection when loses focus', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: SelectableRegion(
          focusNode: node,
          selectionControls: materialTextSelectionControls,
          child: Column(
            children: const <Widget>[
              Text('How are you?'),
              Text('Good, and you?'),
              Text('Fine, thank you.'),
            ],
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    final SelectableRegionState state = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    state.selectAll();
    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 16));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 12));

    node.unfocus();
    await tester.pump();
    expect(paragraph3.selections.isEmpty, isTrue);
    expect(paragraph2.selections.isEmpty, isTrue);
    expect(paragraph1.selections.isEmpty, isTrue);
  });

  testWidgets('widget span can copy correctly', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    const String line1 = 'How are you?';
    const String line2 = 'Good, and you?';
    const String line3 = 'Fine, thank you.';
    await tester.pumpWidget(
      MaterialApp(
        home: SelectableRegion(
          focusNode: node,
          selectionControls: materialTextSelectionControls,
          child: const Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: line1),
                WidgetSpan(child: Text(line2)),
                TextSpan(text: line3),
              ],
            )
          ),
        ),
      ),
    );
    final SelectableRegionState state = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    state.selectAll();
    expect(state.getSelectedContent()!.plainText, '$line1$line2$line3');
  });
}

class SelectionSpy extends LeafRenderObjectWidget {
  const SelectionSpy({
  super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSelectionSpy(
      SelectionRegistrarScope.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) { }
}

class RenderSelectionSpy extends RenderProxyBox
    with Selectable, SelectionRegistrant {
  RenderSelectionSpy(
      SelectionRegistrar? registrar,
      ) {
    this.registrar = registrar;
  }

  final Set<VoidCallback> listeners = <VoidCallback>{};
  List<SelectionEvent> events = <SelectionEvent>[];

  @override
  void addListener(VoidCallback listener) => listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => listeners.remove(listener);

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    events.add(event);
    return SelectionResult.end;
  }

  @override
  SelectedContent? getSelectedContent() {
    return const SelectedContent(plainText: 'content');
  }

  @override
  SelectionGeometry get value => _value;
  SelectionGeometry _value = SelectionGeometry(
    hasContent: true,
    status: SelectionStatus.uncollapsed,
    startSelectionPoint: const SelectionPoint(
      localPosition: Offset.zero,
      lineHeight: 0.0,
      handleType: TextSelectionHandleType.left,
    ),
    endSelectionPoint: const SelectionPoint(
      localPosition: Offset.zero,
      lineHeight: 0.0,
      handleType: TextSelectionHandleType.left,
    ),
  );
  set value(SelectionGeometry other) {
    if (other == _value)
      return;
    _value = other;
    for (final VoidCallback callback in listeners) {
      callback();
    }
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) { }
}
