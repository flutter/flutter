// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  final _MockLiveTestWidgetsFlutterBinding binding = _MockLiveTestWidgetsFlutterBinding();

  testWidgets('Should print message on pointer events', (WidgetTester tester) async {
    final List<String?> printedMessages = <String?>[];
    binding.storeDebugPrints = printedMessages;

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

    await tester.tap(find.byType(Text));
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

    binding.storeDebugPrints = null;
  });
}

class _MockLiveTestWidgetsFlutterBinding extends LiveTestWidgetsFlutterBinding {
  @override
  TestBindingEventSource get pointerEventSource => TestBindingEventSource.device;

  List<String?>? storeDebugPrints;

  @override
  DebugPrintCallback get debugPrintOverride {
    return storeDebugPrints == null ?
      super.debugPrintOverride :
      ((String? message, { int? wrapWidth }) => storeDebugPrints!.add(message));
  }
}
