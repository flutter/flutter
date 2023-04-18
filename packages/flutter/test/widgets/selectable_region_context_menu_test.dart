// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: undefined_class, undefined_getter, undefined_setter

@TestOn('browser') // This file contains web-only library.
library;

import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  html.Element? element;
  final RegisterViewFactory originalFactory = PlatformSelectableRegionContextMenu.registerViewFactory;
  PlatformSelectableRegionContextMenu.registerViewFactory = (final String viewType, final Object Function(int viewId) fn, {final bool isVisible = true}) {
    element = fn(0) as html.Element;
    // The element needs to be attached to the document body to receive mouse
    // events.
    html.document.body!.append(element!);
  };
  // This force register the dom element.
  PlatformSelectableRegionContextMenu(child: const Placeholder());
  PlatformSelectableRegionContextMenu.registerViewFactory = originalFactory;

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
      foundStyle = sheet.rules!.any((final html.CssRule rule) => rule.cssText!.contains(className));
    }
    expect(foundStyle, isTrue);
  });

  testWidgets('right click can trigger select word', (final WidgetTester tester) async {
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
  });
}

class SelectionSpy extends LeafRenderObjectWidget {
  const SelectionSpy({
    super.key,
  });

  @override
  RenderObject createRenderObject(final BuildContext context) {
    return RenderSelectionSpy(
      SelectionContainer.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(final BuildContext context, covariant final RenderObject renderObject) { }
}

class RenderSelectionSpy extends RenderProxyBox
    with Selectable, SelectionRegistrant {
  RenderSelectionSpy(
      final SelectionRegistrar? registrar,
      ) {
    this.registrar = registrar;
  }

  final Set<VoidCallback> listeners = <VoidCallback>{};
  List<SelectionEvent> events = <SelectionEvent>[];

  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  Size computeDryLayout(final BoxConstraints constraints) {
    _size = Size(constraints.maxWidth, constraints.maxHeight);
    return _size;
  }

  @override
  void addListener(final VoidCallback listener) => listeners.add(listener);

  @override
  void removeListener(final VoidCallback listener) => listeners.remove(listener);

  @override
  SelectionResult dispatchSelectionEvent(final SelectionEvent event) {
    events.add(event);
    return SelectionResult.end;
  }

  @override
  SelectedContent? getSelectedContent() {
    return const SelectedContent(plainText: 'content');
  }

  @override
  SelectionGeometry get value => _value;
  SelectionGeometry _value = const SelectionGeometry(
    hasContent: true,
    status: SelectionStatus.uncollapsed,
    startSelectionPoint: SelectionPoint(
      localPosition: Offset.zero,
      lineHeight: 0.0,
      handleType: TextSelectionHandleType.left,
    ),
    endSelectionPoint: SelectionPoint(
      localPosition: Offset.zero,
      lineHeight: 0.0,
      handleType: TextSelectionHandleType.left,
    ),
  );
  set value(final SelectionGeometry other) {
    if (other == _value) {
      return;
    }
    _value = other;
    for (final VoidCallback callback in listeners) {
      callback();
    }
  }

  @override
  void pushHandleLayers(final LayerLink? startHandle, final LayerLink? endHandle) { }
}
