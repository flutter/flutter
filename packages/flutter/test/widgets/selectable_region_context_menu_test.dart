// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser') // This file contains web-only library.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import 'web_platform_view_registry_utils.dart';

extension on web.HTMLCollection {
  Iterable<web.Element?> get iterable =>
      Iterable<web.Element?>.generate(length, (int index) => item(index));
}

extension on web.CSSRuleList {
  Iterable<web.CSSRule?> get iterable =>
      Iterable<web.CSSRule?>.generate(length, (int index) => item(index));
}

bool _browserContextMenuEnabled() {
  // TODO(Renzo-Olivares): Remove this when the web context menu
  // for Android and iOS is re-enabled.
  // See: https://github.com/flutter/flutter/issues/177123.
  return kIsWeb &&
      !<TargetPlatform>{TargetPlatform.android, TargetPlatform.iOS}.contains(defaultTargetPlatform);
}

void main() {
  late FakePlatformViewRegistry fakePlatformViewRegistry;

  setUp(() {
    removeAllStyleElements();
    fakePlatformViewRegistry = FakePlatformViewRegistry();
    PlatformSelectableRegionContextMenu.debugOverrideRegisterViewFactory =
        fakePlatformViewRegistry.registerViewFactory;
  });

  tearDown(() {
    PlatformSelectableRegionContextMenu.debugOverrideRegisterViewFactory = null;
    PlatformSelectableRegionContextMenu.debugResetRegistry();
  });

  testWidgets(
    'DOM element is set up correctly',
    (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();

      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            selectionControls: EmptyTextSelectionControls(),
            child: const Placeholder(),
          ),
        ),
      );

      final element = fakePlatformViewRegistry.getViewById(currentViewId + 1) as web.HTMLElement;

      expect(element, isNotNull);
      expect(element.style.width, '100%');
      expect(element.style.height, '100%');
      expect(element.classList.length, 1);

      final int numberOfStyleElements = getNumberOfStyleElements();
      expect(numberOfStyleElements, 1);
    },
    skip: !_browserContextMenuEnabled(), // [intended]
  );

  testWidgets(
    'only one <style> is inserted into the DOM',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            children: <Widget>[
              SelectableRegion(
                selectionControls: EmptyTextSelectionControls(),
                child: const Placeholder(),
              ),
              SelectableRegion(
                selectionControls: EmptyTextSelectionControls(),
                child: const Placeholder(),
              ),
              SelectableRegion(
                selectionControls: EmptyTextSelectionControls(),
                child: const Placeholder(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      final int numberOfStyleElements = getNumberOfStyleElements();
      expect(numberOfStyleElements, 1);
    },
    skip: !_browserContextMenuEnabled(), // [intended]
  );

  testWidgets(
    'right click can trigger select word',
    (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final spy = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: focusNode,
            selectionControls: materialTextSelectionControls,
            child: SelectionSpy(key: spy),
          ),
        ),
      );

      final element = fakePlatformViewRegistry.getViewById(currentViewId + 1) as web.HTMLElement;
      expect(element, isNotNull);

      focusNode.requestFocus();
      await tester.pump();

      // Dispatch right click.
      element.dispatchEvent(
        web.MouseEvent('mousedown', web.MouseEventInit(button: 2, clientX: 200, clientY: 300)),
      );
      final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(
        find.byKey(spy),
      );
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
    },
    skip: !_browserContextMenuEnabled(), // [intended]
  );

  // Regression test for https://github.com/flutter/flutter/issues/157579
  testWidgets(
    'prevents default action of mousedown events',
    (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();

      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            selectionControls: emptyTextSelectionControls,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      final element = fakePlatformViewRegistry.getViewById(currentViewId + 1) as web.HTMLElement;
      expect(element, isNotNull);

      for (var i = 0; i <= 4; i++) {
        final event = web.MouseEvent(
          'mousedown',
          web.MouseEventInit(button: i, clientX: 200, clientY: 300, cancelable: true),
        );
        element.dispatchEvent(event);
        expect(event.defaultPrevented, isTrue);
      }
    },
    skip: !_browserContextMenuEnabled(), // [intended]
  );
}

void removeAllStyleElements() {
  final List<web.Element?> styles = web.document.head!.children.iterable.toList();
  for (final element in styles) {
    if (element!.tagName == 'STYLE') {
      element.remove();
    }
  }
}

int getNumberOfStyleElements() {
  expect(web.document.head!.children.iterable, isNotEmpty);

  var count = 0;
  for (final web.Element? element in web.document.head!.children.iterable) {
    expect(element, isNotNull);
    if (element!.tagName != 'STYLE') {
      continue;
    }
    final web.CSSRuleList? rules = (element as web.HTMLStyleElement).sheet?.rules;
    if (rules != null) {
      if (rules.iterable.any(
        (web.CSSRule? rule) => rule!.cssText.contains('web-selectable-region-context-menu'),
      )) {
        count++;
      }
    }
  }
  return count;
}

class SelectionSpy extends LeafRenderObjectWidget {
  const SelectionSpy({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSelectionSpy(SelectionContainer.maybeOf(context));
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {}
}

class RenderSelectionSpy extends RenderProxyBox with Selectable, SelectionRegistrant {
  RenderSelectionSpy(SelectionRegistrar? registrar) {
    this.registrar = registrar;
  }

  final Set<VoidCallback> listeners = <VoidCallback>{};
  List<SelectionEvent> events = <SelectionEvent>[];

  @override
  List<Rect> get boundingBoxes => _boundingBoxes;
  final List<Rect> _boundingBoxes = <Rect>[];

  @override
  void performLayout() {
    _boundingBoxes.add(Offset.zero & (size = computeDryLayout(constraints)));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

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
  SelectedContentRange? getSelection() {
    return null;
  }

  @override
  int get contentLength => 1;

  @override
  final SelectionGeometry value = const SelectionGeometry(
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

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {}
}
