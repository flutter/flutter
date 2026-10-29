// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../../common/test_initialization.dart';
import 'semantics_tester.dart';

DateTime _testTime = DateTime(2018, 12, 17);

EngineSemantics semantics() => EngineSemantics.instance;
EngineSemanticsOwner owner() => EnginePlatformDispatcher.instance.implicitView!.semantics;

void main() {
  internalBootstrapBrowserTest(() {
    return testMain;
  });
}

Future<void> testMain() async {
  await bootstrapAndRunApp(withImplicitView: true);
  setUp(() {
    EngineSemantics.debugResetSemantics();
  });

  test('SemanticScrollable transitions from non-scrollable to scrollable', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());

    // Initial state: Generic node, NOT scrollable
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(
        isEnabled: ui.Tristate.isTrue,
        // No scroll container flags
      ),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 100),
    );
    tester.apply();

    // Should NOT have flt-semantics-scroll-overflow
    expectSemanticsTree(owner(), '<sem></sem>');
    expect(owner().semanticsHost.querySelector('flt-semantics-scroll-overflow'), isNull);

    // Make it Vertical Scrollable
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isEnabled: ui.Tristate.isTrue, hasImplicitScrolling: true),
      scrollChildren: 10,
      scrollIndex: 0,
      scrollExtentMin: 0.0,
      scrollExtentMax: 500.0,
      scrollPosition: 0.0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 100),
      hasScrollUp: true,
      hasScrollDown: true,
    );
    tester.apply();

    // Now it should be a scrollable and have the overflow element.
    expectSemanticsTree(
      owner(),
      '<sem role="group"><flt-semantics-scroll-overflow></flt-semantics-scroll-overflow></sem>',
    );
    expect(owner().semanticsHost.querySelector('flt-semantics-scroll-overflow'), isNotNull);

    // Transition back to NON-scrollable provided (remove actions)
    // BUT keep hasImplicitScrolling: true so it stays as SemanticScrollable role
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isEnabled: ui.Tristate.isTrue, hasImplicitScrolling: true),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 100),
      // Implicitly actions = 0 (no scroll flags set)
    );
    tester.apply();

    // Should still have role="group" (from SemanticScrollable)
    expectSemanticsTree(owner(), '<sem role="group"></sem>');
    // Should NOT have overflow element because it cannot scroll
    expect(owner().semanticsHost.querySelector('flt-semantics-scroll-overflow'), isNull);

    // Verify it is indeed SemanticScrollable
    expect(tester.getSemanticsObject(0).semanticRole, isA<SemanticScrollable>());

    semantics().semanticsEnabled = false;
  });

  // Regression test for https://github.com/flutter/flutter/issues/195469.
  //
  // When a scrollable list shrinks until its content fits the viewport, the
  // framework drops the scroll actions and the node stops being scrollable.
  // The stale DOM scroll offset and the scroll adjustments derived from it
  // must be reset, otherwise the semantics elements stay shifted and DOM hit
  // tests (e.g. clicks, screen reader hit tests) land on the wrong rows.
  test('resets stale scroll offset when a vertical scrollable stops scrolling', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    addTearDown(() async {
      semantics().semanticsEnabled = false;
    });

    final tester = SemanticsTester(owner());

    // A 400px viewport containing rows that are 40px tall, matching the
    // repro from the issue.
    const viewportExtent = 400.0;
    const rowExtent = 40.0;

    List<SemanticsNodeUpdate> buildRows(int rowCount, double scrollOffset) {
      return <SemanticsNodeUpdate>[
        for (var i = 0; i < rowCount; i++)
          tester.updateNode(
            id: i + 1,
            hasTap: true,
            rect: const ui.Rect.fromLTRB(0, 0, viewportExtent, rowExtent),
            transform: Matrix4.translationValues(0, rowExtent * i - scrollOffset, 0).toFloat64(),
          ),
      ];
    }

    void updateList(int rowCount, double scrollOffset, {required bool canScroll}) {
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
        hasScrollUp: canScroll,
        hasScrollDown: canScroll,
        scrollChildren: rowCount,
        scrollIndex: 0,
        scrollExtentMin: 0,
        scrollExtentMax: canScroll ? rowCount * rowExtent - viewportExtent : 0,
        scrollPosition: scrollOffset,
        rect: const ui.Rect.fromLTRB(0, 0, viewportExtent, viewportExtent),
        children: buildRows(rowCount, scrollOffset),
      );
      tester.apply();
    }

    // 20 rows x 40px = 800px of content in a 400px viewport.
    updateList(20, 0, canScroll: true);

    final SemanticsObject list = tester.getSemanticsObject(0);
    final DomElement listElement = list.element;
    expect(listElement.scrollTop, 0);

    // Scroll 300px. The framework echoes the new offset as scrollPosition and
    // the engine applies it to the DOM element's scrollTop.
    updateList(20, 300, canScroll: true);
    expect(listElement.scrollTop, 300);
    expect(list.verticalScrollAdjustment, 300.0);

    // While scrolled, the semantics DOM agrees with the painted content: row
    // 12 (id 13) is painted at viewport y=180..220.
    expect(domDocument.elementFromPoint(200, 190), tester.getSemanticsObject(13).element);

    // Shrink the list to 8 rows (320px < 400px viewport). The framework drops
    // the scroll actions so the node stops being scrollable.
    updateList(8, 0, canScroll: false);

    // The leftover scroll offset and adjustment must be cleared.
    expect(list.verticalScrollAdjustment, 0.0);
    expect(listElement.scrollTop, 0);

    // Row 4 (id 5) is painted at viewport y=160..200; a hit test at that point
    // must resolve to its node, not a stale-offset sibling.
    expect(domDocument.elementFromPoint(200, 180), tester.getSemanticsObject(5).element);
  });

  test('resets stale scroll offset when a horizontal scrollable stops scrolling', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    addTearDown(() async {
      semantics().semanticsEnabled = false;
    });

    final tester = SemanticsTester(owner());

    const viewportExtent = 400.0;
    const columnExtent = 40.0;

    List<SemanticsNodeUpdate> buildColumns(int columnCount, double scrollOffset) {
      return <SemanticsNodeUpdate>[
        for (var i = 0; i < columnCount; i++)
          tester.updateNode(
            id: i + 1,
            hasTap: true,
            rect: const ui.Rect.fromLTRB(0, 0, columnExtent, viewportExtent),
            transform: Matrix4.translationValues(columnExtent * i - scrollOffset, 0, 0).toFloat64(),
          ),
      ];
    }

    void updateColumns(int columnCount, double scrollOffset, {required bool canScroll}) {
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
        hasScrollLeft: canScroll,
        hasScrollRight: canScroll,
        scrollChildren: columnCount,
        scrollIndex: 0,
        scrollExtentMin: 0,
        scrollExtentMax: canScroll ? columnCount * columnExtent - viewportExtent : 0,
        scrollPosition: scrollOffset,
        rect: const ui.Rect.fromLTRB(0, 0, viewportExtent, viewportExtent),
        children: buildColumns(columnCount, scrollOffset),
      );
      tester.apply();
    }

    // 20 columns x 40px = 800px of content in a 400px viewport.
    updateColumns(20, 0, canScroll: true);

    final SemanticsObject list = tester.getSemanticsObject(0);
    final DomElement listElement = list.element;
    expect(listElement.scrollLeft, 0);

    // Scroll 300px via the DOM, like a real browser scroll gesture would.
    final ui.SemanticsActionEventCallback? previousActionEventHandler =
        ui.PlatformDispatcher.instance.onSemanticsActionEvent;
    addTearDown(() {
      ui.PlatformDispatcher.instance.onSemanticsActionEvent = previousActionEventHandler;
    });
    final scrollAction = Completer<ui.SemanticsActionEvent>();
    ui.PlatformDispatcher.instance.onSemanticsActionEvent = scrollAction.complete;
    listElement.scrollLeft = 300;
    await scrollAction.future;
    expect(list.horizontalScrollAdjustment, 300.0);

    // The framework echoes the new offset and the updated column positions.
    updateColumns(20, 300, canScroll: true);

    // Column 12 (id 13) is painted at viewport x=180..220.
    expect(domDocument.elementFromPoint(190, 200), tester.getSemanticsObject(13).element);

    // Shrink to 8 columns: no more scroll actions.
    updateColumns(8, 0, canScroll: false);

    expect(list.horizontalScrollAdjustment, 0.0);
    expect(listElement.scrollLeft, 0);
    expect(domDocument.elementFromPoint(180, 200), tester.getSemanticsObject(5).element);
  });
}
