// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgets('Listeners are called when semantics are turned on with ensureSemantics', (
    WidgetTester tester,
  ) async {
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);

    final status = <bool>[];
    void listener() {
      status.add(SemanticsBinding.instance.semanticsEnabled);
    }

    SemanticsBinding.instance.addSemanticsEnabledListener(listener);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);

    final SemanticsHandle handle1 = SemanticsBinding.instance.ensureSemantics();
    expect(status.single, isTrue);
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
    status.clear();

    final SemanticsHandle handle2 = SemanticsBinding.instance.ensureSemantics();
    expect(status, isEmpty); // Listener didn't fire again.
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    expect(tester.binding.platformDispatcher.semanticsEnabled, isFalse);
    tester.binding.platformDispatcher.semanticsEnabledTestValue = true;
    expect(tester.binding.platformDispatcher.semanticsEnabled, isTrue);
    tester.binding.platformDispatcher.clearSemanticsEnabledTestValue();
    expect(tester.binding.platformDispatcher.semanticsEnabled, isFalse);
    expect(status, isEmpty); // Listener didn't fire again.
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    handle1.dispose();
    expect(status, isEmpty); // Listener didn't fire.
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    handle2.dispose();
    expect(status.single, isFalse);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
  }, semanticsEnabled: false);

  testWidgets('Listeners are called when semantics are turned on by platform', (
    WidgetTester tester,
  ) async {
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);

    final status = <bool>[];
    void listener() {
      status.add(SemanticsBinding.instance.semanticsEnabled);
    }

    SemanticsBinding.instance.addSemanticsEnabledListener(listener);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);

    tester.binding.platformDispatcher.semanticsEnabledTestValue = true;
    expect(status.single, isTrue);
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
    status.clear();

    final SemanticsHandle handle = SemanticsBinding.instance.ensureSemantics();
    handle.dispose();
    expect(status, isEmpty); // Listener didn't fire.
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    tester.binding.platformDispatcher.clearSemanticsEnabledTestValue();
    expect(status.single, isFalse);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
  }, semanticsEnabled: false);

  testWidgets('SemanticsBinding.ensureSemantics triggers creation of semantics owner.', (
    WidgetTester tester,
  ) async {
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
    expect(tester.binding.pipelineOwner.semanticsOwner, isNull);

    final SemanticsHandle handle = SemanticsBinding.instance.ensureSemantics();
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
    expect(tester.binding.pipelineOwner.semanticsOwner, isNotNull);

    handle.dispose();
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
    expect(tester.binding.pipelineOwner.semanticsOwner, isNull);
  }, semanticsEnabled: false);

  test('SemanticsHandle dispatches memory events', () async {
    await expectLater(
      await memoryEvents(
        () => SemanticsBinding.instance.ensureSemantics().dispose(),
        SemanticsHandle,
      ),
      areCreateAndDispose,
    );
  });

  testWidgets('getRectOfSemanticsNodeInViewCoordinates asserts for unknown views and nodes', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(label: 'target', child: const SizedBox(width: 100.0, height: 50.0)),
        ),
      );

      final SemanticsNode node = tester.semantics.find(find.bySemanticsLabel('target'));
      final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner!;

      expect(owner.getSemanticsNode(node.id), same(node));
      expect(
        () => SemanticsBinding.instance.getRectOfSemanticsNodeInViewCoordinates(999, node.id),
        throwsAssertionError,
      );
      expect(
        () => SemanticsBinding.instance.getRectOfSemanticsNodeInViewCoordinates(
          tester.view.viewId,
          -1,
        ),
        throwsAssertionError,
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('getRectOfSemanticsNodeInViewCoordinates returns transformed logical rect', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(800.0, 600.0);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: const Offset(40.0, 20.0),
              child: Semantics(label: 'target', child: const SizedBox(width: 100.0, height: 50.0)),
            ),
          ),
        ),
      );

      final SemanticsNode node = tester.semantics.find(find.bySemanticsLabel('target'));

      expect(
        SemanticsBinding.instance.getRectOfSemanticsNodeInViewCoordinates(
          tester.view.viewId,
          node.id,
        ),
        rectMoreOrLessEquals(const Rect.fromLTWH(40.0, 20.0, 100.0, 50.0)),
      );
    } finally {
      handle.dispose();
    }
  });
}
