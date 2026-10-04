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

  test('Tappable adds and removes listener on update', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());

    // Initial state: Tappable and Enabled
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isButton: true, isEnabled: ui.Tristate.isTrue),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    expectSemanticsTree(owner(), '<sem role="button" flt-tappable></sem>');

    // Scan for flt-tappable attribute in DOM
    final DomElement? element0 = owner().semanticsHost.querySelector('[flt-tappable]');
    expect(element0, isNotNull);

    // DISABLED -> Should remove flt-tappable
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isButton: true, isEnabled: ui.Tristate.isFalse),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    // When disabled, Tappable behavior removes flt-tappable
    expectSemanticsTree(owner(), '<sem role="button" aria-disabled="true"></sem>');
    expect(owner().semanticsHost.querySelector('[flt-tappable]'), isNull);

    // ENABLED again -> Should add flt-tappable
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isButton: true, isEnabled: ui.Tristate.isTrue),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();
    expectSemanticsTree(owner(), '<sem role="button" flt-tappable></sem>');
    expect(owner().semanticsHost.querySelector('[flt-tappable]'), isNotNull);

    semantics().semanticsEnabled = false;
  });

  test('Tappable behavior stops listening when not tappable even if enabled', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());

    // Initial state: Tappable and Enabled
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isButton: true, isEnabled: ui.Tristate.isTrue),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();
    expectSemanticsTree(owner(), '<sem role="button" flt-tappable></sem>');

    // Make NOT Tappable (remove hasTap, but keep isButton? isButton usually implies tappable but technically hasTap is the action)
    // Actually SemanticButton adds Tappable unconditionally now, but Tappable checks semanticsObject.isTappable.
    // semanticsObject.isTappable returns true if it has any tap-related actions or flags.

    // Let's remove hasTap action.
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isButton: true, isEnabled: ui.Tristate.isTrue),
      hasTap: false, // No tap action
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    // Should NOT have flt-tappable because isTappable should be false (assuming no other tappable flags/actions)
    // Note: isButton might imply some accessibility role but Tappable behavior checks semanticsObject.isTappable.
    expectSemanticsTree(owner(), '<sem role="button"></sem>');
    expect(owner().semanticsHost.querySelector('[flt-tappable]'), isNull);

    semantics().semanticsEnabled = false;
  });

  test('GenericRole starts untappable and becomes tappable', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());

    // Initial state: GenericRole (no specific role), Untappable
    // Use ID 1 to avoid conflict with previous test if state leaks (though setUp resets semantics)
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isEnabled: ui.Tristate.isTrue),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    // Should NOT have flt-tappable
    expectSemanticsTree(owner(), '<sem></sem>');
    expect(owner().semanticsHost.querySelector('[flt-tappable]'), isNull);

    // Update to be Tappable
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(isEnabled: ui.Tristate.isTrue),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    // Should NOW have flt-tappable
    expectSemanticsTree(owner(), '<sem flt-tappable></sem>');
    expect(owner().semanticsHost.querySelector('[flt-tappable]'), isNotNull);

    semantics().semanticsEnabled = false;
  });
}
