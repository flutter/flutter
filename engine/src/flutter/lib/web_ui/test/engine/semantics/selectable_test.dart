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

  test(
    'Selectable behavior adds/removes aria-current based on isSelectable flag for img role',
    () async {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      final tester = SemanticsTester(owner());

      // Initial state: Image, NOT selectable
      // SemanticImage adds Selectable behavior in constructor.
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(isImage: true, isEnabled: ui.Tristate.isTrue),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      // Should be an img
      expectSemanticsTree(owner(), '<sem role="img"></sem>');
      expect(owner().semanticsHost.querySelector('[aria-current]'), isNull);

      // Make Selectable (hasSelectedState = true)
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(
          isImage: true,
          isEnabled: ui.Tristate.isTrue,
          isSelected: ui.Tristate.isFalse, // implies hasSelectedState
        ),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      // Should now have aria-current="false"
      expectSemanticsTree(owner(), '<sem role="img" aria-current="false"></sem>');
      expect(owner().semanticsHost.querySelector('[aria-current]'), isNotNull);

      // Select it
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(
          isImage: true,
          isEnabled: ui.Tristate.isTrue,
          isSelected: ui.Tristate.isTrue, // implies hasSelectedState
        ),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      expectSemanticsTree(owner(), '<sem role="img" aria-current="true"></sem>');

      // Make NOT Selectable again hiding "hasSelectedState" by setting isSelected to none
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(
          isImage: true,
          isEnabled: ui.Tristate.isTrue,
          // hasSelectedState removed (default is Tristate.none)
        ),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      // Should remove aria-current
      expectSemanticsTree(owner(), '<sem role="img"></sem>');
      expect(owner().semanticsHost.querySelector('[aria-current]'), isNull);

      semantics().semanticsEnabled = false;
    },
  );

  test(
    'Selectable behavior adds/removes aria-selected based on isSelectable flag for tab role',
    () async {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      final tester = SemanticsTester(owner());

      // Initial state: Tab, Selectable but NOT selected
      // SemanticTab adds Selectable behavior in constructor?
      // Let's assume we can just use GenericRole or manually constructed node with role tab?
      // Actually SemanticRole.tab exists?
      // Let's check constructor or how to spawn it.
      // UpdateNode with role: ui.SemanticsRole.tab should do it if mapping exists.
      // The test helper `updateNode` takes `role`.

      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.tab,
        flags: const ui.SemanticsFlags(
          isEnabled: ui.Tristate.isTrue,
          isSelected: ui.Tristate.isFalse, // implies hasSelectedState (selectable)
        ),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      // Should be a tab
      expectSemanticsTree(owner(), '<sem role="tab" aria-selected="false"></sem>');
      expect(owner().semanticsHost.querySelector('[aria-selected="false"]'), isNotNull);

      // Select it
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.tab,
        flags: const ui.SemanticsFlags(
          isEnabled: ui.Tristate.isTrue,
          isSelected: ui.Tristate.isTrue,
        ),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      // Should be selected
      expectSemanticsTree(owner(), '<sem role="tab" aria-selected="true"></sem>');
      expect(owner().semanticsHost.querySelector('[aria-selected="true"]'), isNotNull);

      // Make NOT Selectable
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.tab,
        flags: const ui.SemanticsFlags(isEnabled: ui.Tristate.isTrue),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      // Should remove aria-selected
      expectSemanticsTree(owner(), '<sem role="tab"></sem>');
      expect(owner().semanticsHost.querySelector('[aria-current]'), isNull);
      expect(owner().semanticsHost.querySelector('[aria-selected]'), isNull);

      semantics().semanticsEnabled = false;
    },
  );
}
