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
}
