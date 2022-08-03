// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'selectable_region_test.dart';

void main() {
  if (!kIsWeb) {
    return;
  }
  html.Element? element;
  final RegisterViewFactory originalFactory = WebSelectableRegionContextMenu.factory;
  WebSelectableRegionContextMenu.factory = (String viewType, Object Function(int viewId) fn, {bool isVisible = true}) {
    element = fn(0) as html.Element;
    html.document.body!.append(element!);
  };
  // This force register the dom element.
  WebSelectableRegionContextMenu(child: const Placeholder());
  WebSelectableRegionContextMenu.factory = originalFactory;

  test('DOM element is set up correctly', () async {
    expect(element, isNotNull);
    expect(element!.style.width, '100%');
    expect(element!.style.height, '100%');
    expect(element!.classes.length, 1);
    final String className = element!.classes.first;

    expect(html.document.head!.children, isNotEmpty);
    bool foundStyle = false;
    for (final html.Element element in html.document.head!.children) {
      if (element is! html.StyleElement) {
        continue;
      }
      final html.CssStyleSheet sheet = element.sheet! as html.CssStyleSheet;
      foundStyle = sheet.rules!.any((html.CssRule rule) => rule.cssText!.contains(className));
    }
    expect(foundStyle, isTrue);
  });

  testWidgets('right click can trigger select word', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    final UniqueKey spy = UniqueKey();
    await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: focusNode,
            selectionControls: materialTextSelectionControls,
            child: SelectionSpy(key: spy),
          ),
        )
    );
    expect(element, isNotNull);

    focusNode.requestFocus();
    await tester.pump();

    // Dispatch right click.
    element!.dispatchEvent(
      html.MouseEvent(
        'mousedown',
        button: 2,
        clientX: 200,
        clientY: 300,
      ),
    );
    final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
    expect(renderSelectionSpy.events, isNotEmpty);

    SelectWordSelectionEvent? selectWordEvent;
    for (final SelectionEvent event in renderSelectionSpy.events) {
      if (event is SelectWordSelectionEvent) {
        selectWordEvent = event;
        break;
      }
    }
    expect(selectWordEvent, isNotNull);
    expect((selectWordEvent!.globalPosition.dx - 200).abs() < precisionErrorTolerance, isTrue);
    expect((selectWordEvent.globalPosition.dy - 300).abs() < precisionErrorTolerance, isTrue);
  }, skip: !kIsWeb);
}
