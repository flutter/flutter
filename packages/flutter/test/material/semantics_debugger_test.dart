// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SemanticsDebugger slider', (WidgetTester tester) async {
    var value = 0.75;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: SemanticsDebugger(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MediaQuery(
                data: MediaQueryData.fromView(tester.view),
                child: Material(
                  child: Center(
                    child: Slider(
                      value: value,
                      onChanged: (double newValue) {
                        value = newValue;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // The fling below must be such that the velocity estimation examines an
    // offset greater than the kTouchSlop. Too slow or too short a distance, and
    // it won't trigger. The actual distance moved doesn't matter since this is
    // interpreted as a gesture by the semantics debugger and sent to the widget
    // as a semantic action that always moves by 10% of the complete track.
    await tester.fling(
      find.byType(Slider),
      const Offset(-100.0, 0.0),
      2000.0,
      warnIfMissed: false,
    ); // hitting the debugger
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(value, equals(0.65));
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(value, equals(0.70));
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets('SemanticsDebugger checkbox', (WidgetTester tester) async {
    final Key keyTop = UniqueKey();
    final Key keyBottom = UniqueKey();

    bool? valueTop = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SemanticsDebugger(
          child: Material(
            child: ListView(
              children: <Widget>[
                Checkbox(
                  key: keyTop,
                  value: valueTop,
                  onChanged: (bool? newValue) {
                    valueTop = newValue;
                  },
                ),
                Checkbox(key: keyBottom, value: false, onChanged: null),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(keyTop), warnIfMissed: false); // hitting the debugger
    expect(valueTop, isTrue);
    valueTop = false;
    expect(valueTop, isFalse);

    await tester.tap(find.byKey(keyBottom), warnIfMissed: false); // hitting the debugger
    expect(valueTop, isFalse);
  });

  testWidgets('SemanticsDebugger checkbox message', (WidgetTester tester) async {
    final Key checkbox = UniqueKey();
    final Key checkboxUnchecked = UniqueKey();
    final Key checkboxDisabled = UniqueKey();
    final Key checkboxDisabledUnchecked = UniqueKey();
    final Key debugger = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SemanticsDebugger(
          key: debugger,
          child: Material(
            child: ListView(
              children: <Widget>[
                Semantics(
                  container: true,
                  key: checkbox,
                  child: Checkbox(value: true, onChanged: (bool? _) {}),
                ),
                Semantics(
                  container: true,
                  key: checkboxUnchecked,
                  child: Checkbox(value: false, onChanged: (bool? _) {}),
                ),
                Semantics(
                  container: true,
                  key: checkboxDisabled,
                  child: const Checkbox(value: true, onChanged: null),
                ),
                Semantics(
                  container: true,
                  key: checkboxDisabledUnchecked,
                  child: const Checkbox(value: false, onChanged: null),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      _getMessageShownInSemanticsDebugger(
        widgetKey: checkbox,
        debuggerKey: debugger,
        tester: tester,
      ),
      'checked',
    );
    expect(
      _getMessageShownInSemanticsDebugger(
        widgetKey: checkboxUnchecked,
        debuggerKey: debugger,
        tester: tester,
      ),
      'unchecked',
    );
    expect(
      _getMessageShownInSemanticsDebugger(
        widgetKey: checkboxDisabled,
        debuggerKey: debugger,
        tester: tester,
      ),
      'checked; disabled',
    );
    expect(
      _getMessageShownInSemanticsDebugger(
        widgetKey: checkboxDisabledUnchecked,
        debuggerKey: debugger,
        tester: tester,
      ),
      'unchecked; disabled',
    );
  });

  // TODO(rizwan-saleem): Move onTap semantics to EditableText so this test
  // can move to the widgets layer.
  // Tracking issue: https://github.com/flutter/flutter/issues/181873
  testWidgets('SemanticsDebugger textfield', (WidgetTester tester) async {
    final textField = UniqueKey();
    final debugger = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: SemanticsDebugger(
          key: debugger,
          child: Material(child: TextField(key: textField)),
        ),
      ),
    );

    final dynamic semanticsDebuggerPainter = _getSemanticsDebuggerPainter(
      debuggerKey: debugger,
      tester: tester,
    );
    final RenderObject renderTextfield = tester.renderObject(
      find.descendant(of: find.byKey(textField), matching: find.byType(Semantics)).first,
    );

    expect(
      // ignore: avoid_dynamic_calls
      semanticsDebuggerPainter.getMessage(renderTextfield.debugSemantics),
      'textfield',
    );
  });
}

String _getMessageShownInSemanticsDebugger({
  required Key widgetKey,
  required Key debuggerKey,
  required WidgetTester tester,
}) {
  final dynamic semanticsDebuggerPainter = _getSemanticsDebuggerPainter(
    debuggerKey: debuggerKey,
    tester: tester,
  );
  // ignore: avoid_dynamic_calls
  return semanticsDebuggerPainter.getMessage(
        tester.renderObject(find.byKey(widgetKey)).debugSemantics,
      )
      as String;
}

dynamic _getSemanticsDebuggerPainter({required Key debuggerKey, required WidgetTester tester}) {
  final customPaint =
      tester
              .widgetList(
                find.descendant(of: find.byKey(debuggerKey), matching: find.byType(CustomPaint)),
              )
              .first
          as CustomPaint;
  final dynamic semanticsDebuggerPainter = customPaint.foregroundPainter;
  expect(semanticsDebuggerPainter.runtimeType.toString(), '_SemanticsDebuggerPainter');
  return semanticsDebuggerPainter;
}
