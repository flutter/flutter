// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sends the framework's system-fonts-changed platform message.
Future<void> _sendSystemFontsChange(WidgetTester tester) {
  const data = <String, dynamic>{'type': 'fontsChange'};
  return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/system',
    SystemChannels.system.codec.encodeMessage(data),
    (ByteData? response) {},
  );
}

/// Verifies that system-font changes defer relayout to transient callbacks.
Future<void> _verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(
  WidgetTester tester,
  RenderObject renderObject,
) async {
  assert(!renderObject.debugNeedsLayout);

  await _sendSystemFontsChange(tester);

  final animation = Completer<bool>();
  tester.binding.scheduleFrameCallback((Duration timeStamp) {
    animation.complete(renderObject.debugNeedsLayout);
  });

  // The fonts change does not mark the render object as needing layout
  // immediately.
  expect(renderObject.debugNeedsLayout, isFalse);
  await tester.pump();
  expect(await animation.future, isTrue);
}

void main() {
  testWidgets('RenderParagraph relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: Text('text widget')),
    );
    final RenderObject renderObject = tester.renderObject(find.text('text widget'));
    await _verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, renderObject);
  });

  testWidgets(
    'Safe to query a RelayoutWhenSystemFontsChangeMixin for text layout after system fonts changes',
    (WidgetTester tester) async {
      final child = _RenderCustomRelayoutWhenSystemFontsChange();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WidgetToRenderBoxAdapter(renderBox: child),
        ),
      );
      await _verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, child);
      expect(child.hasValidTextLayout, isTrue);
    },
  );

  testWidgets('Banner repaint upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Banner(
        message: 'message',
        location: BannerLocation.topStart,
        textDirection: TextDirection.ltr,
        layoutDirection: TextDirection.ltr,
      ),
    );
    await _sendSystemFontsChange(tester);
    final RenderObject renderObject = tester.renderObject(find.byType(Banner));
    expect(renderObject.debugNeedsPaint, isTrue);
  });

  // Regression test for https://github.com/flutter/flutter/issues/151873
  testWidgets('System fonts update during non-idle scheduler phase does not assert', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: Text('Hello')),
    );

    // Simulate a fontsChange system message arriving during a non-idle
    // scheduler phase (e.g. midFrameMicrotasks on web when fonts load
    // asynchronously). Previously this caused an assertion failure in
    // _scheduleSystemFontsUpdate because it assumed the scheduler was idle.
    tester.binding.scheduleFrameCallback((Duration timeStamp) {
      // We're now inside transientCallbacks phase (not idle).
      // Trigger a fonts change notification from here.
      _sendSystemFontsChange(tester);
    });

    // Pump to execute the frame callback. This should not throw.
    await tester.pump();

    // Pump again to let the scheduled frame callback run.
    await tester.pump();

    // Verify the text widget still renders correctly after the fonts update.
    expect(find.text('Hello'), findsOneWidget);
  });
}

class _RenderCustomRelayoutWhenSystemFontsChange extends RenderBox
    with RelayoutWhenSystemFontsChangeMixin {
  bool hasValidTextLayout = false;

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    hasValidTextLayout = false;
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    hasValidTextLayout = true;
  }
}
