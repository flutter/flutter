// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

Future<void> verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(
  WidgetTester tester,
  RenderObject renderObject,
) async {
  assert(!renderObject.debugNeedsLayout);

  const data = <String, dynamic>{'type': 'fontsChange'};
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/system',
    SystemChannels.system.codec.encodeMessage(data),
    (ByteData? data) {},
  );

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

// Registers Ahem as `family`, as an app does when it loads a font at runtime.
// Text in `family` falls back to the test font until then. Ahem's ascent is
// 0.8 em and the test font's is 0.75 em, so the alphabetic baseline of text with
// a font size of 20 moves from 15 to 16 once Ahem loads.
Future<void> loadAhemAs(String family) async {
  const FileSystem fs = LocalFileSystem();
  const Platform platform = LocalPlatform();
  final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT']);

  final File font = flutterRoot.childFile(
    fs.path.join('packages', 'flutter_tools', 'static', 'Ahem.ttf'),
  );

  final bytes = Future<ByteData>.value(font.readAsBytesSync().buffer.asByteData());

  await (FontLoader(family)..addFont(bytes)).load();
}

void main() {
  testWidgets('RenderParagraph relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('text widget')));
    final RenderObject renderObject = tester.renderObject(find.text('text widget'));
    await verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, renderObject);
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
      const data = <String, dynamic>{'type': 'fontsChange'};
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/system',
        SystemChannels.system.codec.encodeMessage(data),
        (ByteData? data) {},
      );
      expect(child.hasValidTextLayout, isTrue);
    },
  );

  testWidgets('RenderEditable relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SelectableText('text widget')));

    final EditableTextState state = tester.state(find.byType(EditableText));
    await verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, state.renderEditable);
  });

  // Regression test for https://github.com/flutter/flutter/issues/195134.
  testWidgets(
    'RenderParagraph dry baseline uses a font registered after the first layout',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Text(
              'text widget',
              style: TextStyle(fontFamily: 'AhemForParagraph', fontSize: 20),
            ),
          ),
        ),
      );
      final RenderParagraph paragraph = tester.renderObject(find.text('text widget'));
      const constraints = BoxConstraints(maxWidth: 300);
      expect(paragraph.getDryBaseline(constraints, TextBaseline.alphabetic), 15.0);

      await tester.runAsync(() => loadAhemAs('AhemForParagraph'));
      await tester.pump();

      expect(
        paragraph.getDryBaseline(constraints, TextBaseline.alphabetic),
        moreOrLessEquals(16.0, epsilon: 0.001),
      );
    },
    skip: isBrowser, // Loads a font file from the Flutter SDK.
  );

  // Regression test for https://github.com/flutter/flutter/issues/195134.
  testWidgets(
    'RenderEditable dry baseline uses a font registered after the first layout',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'text widget');
      addTearDown(controller.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              child: EditableText(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(fontFamily: 'AhemForEditable', fontSize: 20),
                cursorColor: const Color(0xFF000000),
                backgroundCursorColor: const Color(0xFF000000),
              ),
            ),
          ),
        ),
      );
      final EditableTextState state = tester.state(find.byType(EditableText));
      final RenderEditable editable = state.renderEditable;
      const constraints = BoxConstraints(maxWidth: 300);
      expect(editable.getDryBaseline(constraints, TextBaseline.alphabetic), 15.0);

      await tester.runAsync(() => loadAhemAs('AhemForEditable'));
      await tester.pump();

      expect(
        editable.getDryBaseline(constraints, TextBaseline.alphabetic),
        moreOrLessEquals(16.0, epsilon: 0.001),
      );
    },
    skip: isBrowser, // Loads a font file from the Flutter SDK.
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
    const data = <String, dynamic>{'type': 'fontsChange'};
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
      (ByteData? data) {},
    );
    final RenderObject renderObject = tester.renderObject(find.byType(Banner));
    expect(renderObject.debugNeedsPaint, isTrue);
  });

  testWidgets('CupertinoDatePicker reset cache upon system fonts change - date time mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(home: CupertinoDatePicker(onDateTimeChanged: (DateTime dateTime) {})),
    );
    final dynamic state = tester.state(find.byType(CupertinoDatePicker));
    // ignore: avoid_dynamic_calls
    final cache = state.estimatedColumnWidths as Map<int, double>;
    expect(cache.isNotEmpty, isTrue);
    const data = <String, dynamic>{'type': 'fontsChange'};
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
      (ByteData? data) {},
    );
    // Cache should be cleaned.
    expect(cache.isEmpty, isTrue);
    final Element element = tester.element(find.byType(CupertinoDatePicker));
    expect(element.dirty, isTrue);
  });

  testWidgets('CupertinoDatePicker reset cache upon system fonts change - date mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (DateTime dateTime) {},
        ),
      ),
    );
    final dynamic state = tester.state(find.byType(CupertinoDatePicker));
    // ignore: avoid_dynamic_calls
    final cache = state.estimatedColumnWidths as Map<int, double>;
    // Simulates font missing.
    cache.clear();
    const data = <String, dynamic>{'type': 'fontsChange'};
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
      (ByteData? data) {},
    );
    // Cache should be replenished
    expect(cache.isNotEmpty, isTrue);
    final Element element = tester.element(find.byType(CupertinoDatePicker));
    expect(element.dirty, isTrue);
  });

  testWidgets('CupertinoDatePicker reset cache upon system fonts change - time mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(home: CupertinoTimerPicker(onTimerDurationChanged: (Duration d) {})),
    );
    final dynamic state = tester.state(find.byType(CupertinoTimerPicker));
    // Simulates wrong metrics due to font missing.
    // ignore: avoid_dynamic_calls
    state.numberLabelWidth = 0.0;
    // ignore: avoid_dynamic_calls
    state.numberLabelHeight = 0.0;
    // ignore: avoid_dynamic_calls
    state.numberLabelBaseline = 0.0;
    const data = <String, dynamic>{'type': 'fontsChange'};
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
      (ByteData? data) {},
    );
    // Metrics should be refreshed
    // ignore: avoid_dynamic_calls
    expect(state.numberLabelWidth, lessThan(46.0 + precisionErrorTolerance));
    // ignore: avoid_dynamic_calls
    expect(state.numberLabelHeight, lessThan(23.0 + precisionErrorTolerance));
    // ignore: avoid_dynamic_calls
    expect(state.numberLabelBaseline, lessThan(18.400070190429688 + precisionErrorTolerance));
    final Element element = tester.element(find.byType(CupertinoTimerPicker));
    expect(element.dirty, isTrue);
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
    const data = <String, dynamic>{'type': 'fontsChange'};
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
      (ByteData? data) {},
    );
    final RenderObject renderObject = tester.renderObject(
      find.byWidgetPredicate(
        (Widget widget) => widget.runtimeType.toString() == '_RangeSliderRenderObjectWidget',
      ),
    );
    await verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, renderObject);
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
    await verifyMarkedNeedsLayoutDuringTransientCallbacksPhase(tester, renderObject);
  });

  // Regression test for https://github.com/flutter/flutter/issues/151873
  testWidgets('System fonts update during non-idle scheduler phase does not assert', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Hello')));

    // Simulate a fontsChange system message arriving during a non-idle
    // scheduler phase (e.g. midFrameMicrotasks on web when fonts load
    // asynchronously). Previously this caused an assertion failure in
    // _scheduleSystemFontsUpdate because it assumed the scheduler was idle.
    tester.binding.scheduleFrameCallback((Duration timeStamp) {
      // We're now inside transientCallbacks phase (not idle).
      // Trigger a fonts change notification from here.
      const data = <String, dynamic>{'type': 'fontsChange'};
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/system',
        SystemChannels.system.codec.encodeMessage(data),
        (ByteData? data) {},
      );
    });

    // Pump to execute the frame callback. This should not throw.
    await tester.pump();

    // Pump again to let the scheduled frame callback run.
    await tester.pump();

    // Verify the text widget still renders correctly after the fonts update.
    expect(find.text('Hello'), findsOneWidget);
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
    const data = <String, dynamic>{'type': 'fontsChange'};
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
      (ByteData? data) {},
    );
    final Finder customPaintFinder = find.descendant(
      of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_Dial'),
      matching: find.byType(CustomPaint),
    );
    final RenderObject renderObject = tester.renderObject(customPaintFinder);
    expect(renderObject.debugNeedsPaint, isTrue);
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
