// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_api_samples/material/selectable_region/selectable_region.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('The icon can be selected with the text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SelectableRegionExampleApp(),
    );
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text('Select this icon').first,
        matching: find.byType(RichText),
      ),
    );

    final Rect paragraphRect = tester.getRect(find.text('Select this icon').first);
    final TestGesture gesture = await tester.startGesture(
      paragraphRect.centerLeft,
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();

    final Rect iconRect = tester.getRect(find.byIcon(Icons.key));
    await gesture.moveTo(iconRect.bottomRight);
    await tester.pump();

    expect(
      paragraph.selections.first,
      const TextSelection(baseOffset: 0, extentOffset: 16),
    );
    final example.RenderSelectableAdapter renderSelectableAdapter = tester.renderObject(
      find.byRenderObjectType(example.RenderSelectableAdapter),
    );
    expect(
      renderSelectableAdapter.value,
      const SelectionGeometry(
        status: SelectionStatus.uncollapsed,
        hasContent: true,
        startSelectionPoint: SelectionPoint(
          localPosition: Offset(-10, 40),
          lineHeight: 50,
          handleType: TextSelectionHandleType.left,
        ),
        endSelectionPoint: SelectionPoint(
          localPosition: Offset(40, 40),
          lineHeight: 50,
          handleType: TextSelectionHandleType.right,
        ),
        selectionRects: <Rect>[Rect.fromLTRB(-10, -10, 40, 40)],
      ),
    );
    expect(
      renderSelectableAdapter.getSelectedContent(),
      const SelectedContent(plainText: 'Custom Text'),
    );
    await gesture.up();
  });
}

class _RenderObjectTypeWidgetFinder extends MatchFinder {
  _RenderObjectTypeWidgetFinder(this.renderObjectType, { super.skipOffstage });

  final Type renderObjectType;

  @override
  String get description => 'type "$renderObjectType"';

  @override
  bool matches(Element candidate) {
    return candidate.renderObject.runtimeType == renderObjectType;
  }
}

extension on CommonFinders {
    Finder byRenderObjectType(Type renderObjectType, { bool skipOffstage = true }) => _RenderObjectTypeWidgetFinder(renderObjectType, skipOffstage: skipOffstage);
}
