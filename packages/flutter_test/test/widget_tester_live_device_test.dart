// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final _MockLiveTestWidgetsFlutterBinding binding = _MockLiveTestWidgetsFlutterBinding();

  testWidgets('Should print message on pointer events', (WidgetTester tester) async {
    final List<String?> printedMessages = <String?>[];

    int invocations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GestureDetector(
            onTap: () {
              invocations++;
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );

    final Size windowCenter = tester.binding.window.physicalSize /
        tester.binding.window.devicePixelRatio /
        2;
    final double windowCenterX = windowCenter.width;
    final double windowCenterY = windowCenter.height;

    final Offset widgetCenter = tester.getRect(find.byType(Text)).center;
    expect(widgetCenter.dx, windowCenterX);
    expect(widgetCenter.dy, windowCenterY);

    await binding.collectDebugPrints(printedMessages, () async {
      await tester.tap(find.byType(Text));
    });
    await tester.pump();
    expect(invocations, 0);

    expect(printedMessages, equals('''
Some possible finders for the widgets at Offset(400.0, 300.0):
  find.text('Test')
  find.widgetWithText(RawGestureDetector, 'Test')
  find.byType(GestureDetector)
  find.byType(Center)
  find.widgetWithText(IgnorePointer, 'Test')
  find.byType(FadeTransition)
  find.byType(FractionalTranslation)
  find.byType(SlideTransition)
  find.widgetWithText(PrimaryScrollController, 'Test')
  find.widgetWithText(PageStorage, 'Test')
  find.widgetWithText(Offstage, 'Test')
'''.trim().split('\n')));
    printedMessages.clear();

    await binding.collectDebugPrints(printedMessages, () async {
      await tester.tapAt(const Offset(1, 1));
    });
    expect(printedMessages, equals('''
Some possible finders for the widgets at Offset(1.0, 1.0):
  find.byType(MouseRegion)
  find.byType(ExcludeSemantics)
  find.byType(BlockSemantics)
  find.byType(ModalBarrier)
  find.byType(Overlay)
'''.trim().split('\n')));
  });
}

class _MockLiveTestWidgetsFlutterBinding extends LiveTestWidgetsFlutterBinding {
  @override
  TestBindingEventSource get pointerEventSource => TestBindingEventSource.device;

  List<String?>? _storeDebugPrints;

  @override
  DebugPrintCallback get debugPrintOverride {
    return _storeDebugPrints == null
        ? super.debugPrintOverride
        : ((String? message, { int? wrapWidth }) => _storeDebugPrints!.add(message));
  }

  // Execute `task` while redirecting [debugPrint] to appending to `store`.
  Future<void> collectDebugPrints(List<String?>? store, AsyncValueGetter<void> task) async {
    _storeDebugPrints = store;
    try {
      await task();
    } finally {
      _storeDebugPrints = null;
    }
  }
}
