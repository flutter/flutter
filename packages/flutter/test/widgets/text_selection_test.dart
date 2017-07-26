// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/mockito.dart';

void main() {
  testWidgets('build handles', (WidgetTester tester) async {
    TextSelectionOverlay overlayUnderTest;
    final MockRenderEditable mockRenderEditable = new MockRenderEditable();
    final MockTextSelectionControls mockTextSelectionControls =
        new MockTextSelectionControls();
    final GlobalKey startingHandleKey = new GlobalKey();
    final GlobalKey endingHandleKey = new GlobalKey();

    when(mockRenderEditable.getEndpointsForSelection(typed(any)))
        .thenReturn(<TextSelectionPoint>[
          const TextSelectionPoint(const Offset(10.0, 0.0), TextDirection.ltr),
          const TextSelectionPoint(const Offset(30.0, 0.0), TextDirection.ltr),
        ]);
    final double renderTextLineHeight = 15.0;
    when(mockRenderEditable.preferredLineHeight).thenReturn(renderTextLineHeight);
    when(mockTextSelectionControls.buildHandle(
      typed(any),
      typed(any),
      // Expect the line height passed back.
      renderTextLineHeight)
    ).thenAnswer((Invocation invocation) {
      final TextSelectionHandleType calledHandleType = invocation.positionalArguments[1];
      if (calledHandleType == TextSelectionHandleType.left)
        return new Container(key: startingHandleKey);
      if (calledHandleType == TextSelectionHandleType.right)
        return new Container(key: endingHandleKey);
      fail('Unexpected TextSelectionHandleType');
    });

    BuildContext overlayContext;
    await tester.pumpWidget(
      new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) {
              overlayContext = context;
              return new Container();
            }
          ),
        ],
      ),
    );

    overlayUnderTest = new TextSelectionOverlay(
      context: overlayContext,
      value: const TextEditingValue(
        text: 'blah blah blah',
        selection: const TextSelection(baseOffset: 2, extentOffset: 7),
      ),
      layerLink: new LayerLink(),
      renderObject: mockRenderEditable,
      selectionControls: mockTextSelectionControls,
    );

    overlayUnderTest.showHandles();

    await tester.pump();

    expect(find.byKey(startingHandleKey), findsOneWidget);
    expect(find.byKey(endingHandleKey), findsOneWidget);

    overlayUnderTest.dispose();
  });
}

class MockRenderEditable extends Mock implements RenderEditable {}

class MockTextSelectionControls extends Mock implements TextSelectionControls {}
