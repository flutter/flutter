// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'handleMetricsChanged does not scheduleForcedFrame unless there a registered renderView with a child',
    () async {
      expect(SchedulerBinding.instance.hasScheduledFrame, false);
      RendererBinding.instance.handleMetricsChanged();
      expect(SchedulerBinding.instance.hasScheduledFrame, false);

      RendererBinding.instance.addRenderView(RendererBinding.instance.renderView);
      RendererBinding.instance.handleMetricsChanged();
      expect(SchedulerBinding.instance.hasScheduledFrame, false);

      RendererBinding.instance.renderView.child = RenderLimitedBox();
      RendererBinding.instance.handleMetricsChanged();
      expect(SchedulerBinding.instance.hasScheduledFrame, true);

      RendererBinding.instance.removeRenderView(RendererBinding.instance.renderView);
    },
  );

  test('debugDumpSemantics prints explanation when semantics are unavailable', () {
    RendererBinding.instance.addRenderView(RendererBinding.instance.renderView);
    final DebugPrintCallback oldDebugPrint = debugPrint;
    final log = <String?>[];
    try {
      debugPrint = (String? message, {int? wrapWidth}) {
        log.add(message);
      };
      debugDumpSemanticsTree();
      expect(log, hasLength(1));
      expect(log.single, startsWith('Semantics not generated'));
      expect(
        log.single,
        endsWith(
          'For performance reasons, the framework only generates semantics when asked to do so by the platform.\n'
          'Usually, platforms only ask for semantics when assistive technologies (like screen readers) are running.\n'
          'To generate semantics, try turning on an assistive technology (like VoiceOver or TalkBack) on your device.',
        ),
      );
    } finally {
      debugPrint = oldDebugPrint;
      RendererBinding.instance.removeRenderView(RendererBinding.instance.renderView);
    }
  });

  test('root pipeline owner cannot manage root node', () {
    final RenderObject rootNode = RenderProxyBox();
    expect(
      () => RendererBinding.instance.rootPipelineOwner.rootNode = rootNode,
      throwsA(
        isFlutterError.having(
          (FlutterError e) => e.message,
          'message',
          contains('Cannot set a rootNode on the default root pipeline owner.'),
        ),
      ),
    );
  });

  testWidgets('semanticsNodeGlobalRect returns null for unknown views and nodes', (
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
      expect(SemanticsBinding.instance.semanticsNodeGlobalRect(999, node.id), isNull);
      expect(SemanticsBinding.instance.semanticsNodeGlobalRect(tester.view.viewId, -1), isNull);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('semanticsNodeGlobalRect returns transformed logical rect', (
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
        SemanticsBinding.instance.semanticsNodeGlobalRect(tester.view.viewId, node.id),
        rectMoreOrLessEquals(const Rect.fromLTWH(40.0, 20.0, 100.0, 50.0)),
      );
    } finally {
      handle.dispose();
    }
  });
}
