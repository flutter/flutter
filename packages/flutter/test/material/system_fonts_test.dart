// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  testWidgets('RenderEditable relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SelectableText('text widget')));

    final EditableTextState state = tester.state(find.byType(EditableText));
    await _verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, state.renderEditable);
  });

  testWidgets('RangeSlider relayout upon system fonts changes more than once', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RangeSlider(
            values: const RangeValues(0.0, 1.0),
            onChanged: (RangeValues values) {},
          ),
        ),
      ),
    );
    await _sendSystemFontsChange(tester);
    final RenderObject renderObject = tester.renderObject(
      find.byWidgetPredicate(
        (Widget widget) => widget.runtimeType.toString() == '_RangeSliderRenderObjectWidget',
      ),
    );
    await _verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, renderObject);
  });

  testWidgets('Slider relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: Slider(value: 0.0, onChanged: (double value) {})),
      ),
    );
    final RenderObject renderObject = tester.allRenderObjects
        .where(
          (RenderObject renderObject) => renderObject.runtimeType.toString() == '_RenderSlider',
        )
        .first;
    await _verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, renderObject);
  });

  testWidgets('TimePicker relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                      builder: (BuildContext context, Widget? child) {
                        return Directionality(
                          key: const Key('parent'),
                          textDirection: TextDirection.ltr,
                          child: child!,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    await _sendSystemFontsChange(tester);
    final Finder customPaintFinder = find.descendant(
      of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_Dial'),
      matching: find.byType(CustomPaint),
    );
    final RenderObject renderObject = tester.renderObject(customPaintFinder);
    expect(renderObject.debugNeedsPaint, isTrue);
  });
}
