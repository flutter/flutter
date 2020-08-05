// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';

void main() {

  // The "can be constructed" tests that follow are primarily to ensure that any
  // animations started by the progress indicators are stopped at dispose() time.

  testWidgets('LinearProgressIndicator(value: 0.0) can be constructed and has empty semantics by default', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: LinearProgressIndicator(value: 0.0),
          ),
        ),
      ),
    );

    expect(tester.getSemantics(find.byType(LinearProgressIndicator)), matchesSemantics());
    handle.dispose();
  });

  testWidgets('LinearProgressIndicator(value: null) can be constructed and has empty semantics by default', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: LinearProgressIndicator(value: null),
          ),
        ),
      ),
    );

    expect(tester.getSemantics(find.byType(LinearProgressIndicator)), matchesSemantics());
    handle.dispose();
  });

  testWidgets('LinearProgressIndicator custom minHeight', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: LinearProgressIndicator(value: 0.25, minHeight: 2.0),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 200.0, 2.0))
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 50.0, 2.0)),
    );
  });

  testWidgets('LinearProgressIndicator paint (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: LinearProgressIndicator(value: 0.25),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 200.0, 4.0))
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 50.0, 4.0)),
    );

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('LinearProgressIndicator paint (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: LinearProgressIndicator(value: 0.25),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 200.0, 4.0))
        ..rect(rect: const Rect.fromLTRB(150.0, 0.0, 200.0, 4.0)),
    );

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('LinearProgressIndicator indeterminate (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: LinearProgressIndicator(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    final double animationValue = const Interval(0.0, 750.0 / 1800.0, curve: Cubic(0.2, 0.0, 0.8, 1.0))
      .transform(300.0 / 1800.0);

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 200.0, 4.0))
        ..rect(rect: Rect.fromLTRB(0.0, 0.0, animationValue * 200.0, 4.0)),
    );

    expect(tester.binding.transientCallbackCount, 1);
  });

  testWidgets('LinearProgressIndicator paint (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: LinearProgressIndicator(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    final double animationValue = const Interval(0.0, 750.0 / 1800.0, curve: Cubic(0.2, 0.0, 0.8, 1.0))
      .transform(300.0 / 1800.0);

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 200.0, 4.0))
        ..rect(rect: Rect.fromLTRB(200.0 - animationValue * 200.0, 0.0, 200.0, 4.0)),
    );

    expect(tester.binding.transientCallbackCount, 1);
  });

  testWidgets('LinearProgressIndicator with colors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: LinearProgressIndicator(
              value: 0.25,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.black,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 200.0, 4.0))
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 50.0, 4.0), color: Colors.white),
    );
  });

  testWidgets('CircularProgressIndicator(value: 0.0) can be constructed and has value semantics by default', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CircularProgressIndicator(value: 0.0),
        ),
      ),
    );

    expect(tester.getSemantics(find.byType(CircularProgressIndicator)), matchesSemantics(
      value: '0%',
      textDirection: TextDirection.ltr,
    ));
    handle.dispose();
  });

  testWidgets('CircularProgressIndicator(value: null) can be constructed and has empty semantics by default', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const Center(
        child: CircularProgressIndicator(value: null),
      ),
    );

    expect(tester.getSemantics(find.byType(CircularProgressIndicator)), matchesSemantics());
    handle.dispose();
  });

  testWidgets('LinearProgressIndicator causes a repaint when it changes', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(children: const <Widget>[LinearProgressIndicator(value: 0.0)]),
    ));
    final List<Layer> layers1 = tester.layers;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(children: const <Widget>[LinearProgressIndicator(value: 0.5)])),
    );
    final List<Layer> layers2 = tester.layers;
    expect(layers1, isNot(equals(layers2)));
  });

  testWidgets('CircularProgressIndicator stoke width', (WidgetTester tester) async {
    await tester.pumpWidget(const CircularProgressIndicator());

    expect(find.byType(CircularProgressIndicator), paints..arc(strokeWidth: 4.0));

    await tester.pumpWidget(const CircularProgressIndicator(strokeWidth: 16.0));

    expect(find.byType(CircularProgressIndicator), paints..arc(strokeWidth: 16.0));
  });

  testWidgets('CircularProgressIndicator paint background color', (WidgetTester tester) async {
    const Color green = Color(0xFF00FF00);
    const Color blue = Color(0xFF0000FF);

    await tester.pumpWidget(const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(blue),
    ));

    expect(find.byType(CircularProgressIndicator), paintsExactlyCountTimes(#drawArc, 1));
    expect(find.byType(CircularProgressIndicator), paints..arc(color: blue));

    await tester.pumpWidget(const CircularProgressIndicator(
      backgroundColor: green,
      valueColor: AlwaysStoppedAnimation<Color>(blue),
    ));

    expect(find.byType(CircularProgressIndicator), paintsExactlyCountTimes(#drawArc, 2));
    expect(find.byType(CircularProgressIndicator), paints..arc(color: green)..arc(color: blue));
  });

  testWidgets('Indeterminate RefreshProgressIndicator keeps spinning until end of time (approximate)', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/13782

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200.0,
            child: RefreshProgressIndicator(),
          ),
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(const Duration(seconds: 5));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(const Duration(days: 9999));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('Determinate CircularProgressIndicator stops the animator', (WidgetTester tester) async {
    double progressValue;
    StateSetter setState;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              setState = setter;
              return CircularProgressIndicator(value: progressValue);
            }
          ),
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);

    setState(() { progressValue = 1.0; });
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.hasRunningAnimations, isFalse);

    setState(() { progressValue = null; });
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('LinearProgressIndicator with height 12.0', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 12.0,
            child: LinearProgressIndicator(value: 0.25),
          ),
        ),
      ),
    );
    expect(
        find.byType(LinearProgressIndicator),
        paints
          ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 12.0))
          ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 25.0, 12.0)),
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('LinearProgressIndicator with a height less than the minimum', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 3.0,
            child: LinearProgressIndicator(value: 0.25),
          ),
        ),
      ),
    );
    expect(
        find.byType(LinearProgressIndicator),
        paints
          ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 3.0))
          ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 25.0, 3.0)),
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('LinearProgressIndicator with default height', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 4.0,
            child: LinearProgressIndicator(value: 0.25),
          ),
        ),
      ),
    );
    expect(
        find.byType(LinearProgressIndicator),
        paints
          ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 4.0))
          ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 25.0, 4.0)),
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('LinearProgressIndicator can be made accessible', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final GlobalKey key = GlobalKey();
    const String label = 'Label';
    const String value = '25%';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LinearProgressIndicator(
          key: key,
          value: 0.25,
          semanticsLabel: label,
          semanticsValue: value,
        ),
      ),
    );

    expect(tester.getSemantics(find.byKey(key)), matchesSemantics(
      textDirection: TextDirection.ltr,
      label: label,
      value: value,
    ));

    handle.dispose();
  });

  testWidgets('LinearProgressIndicator that is determinate gets default a11y value', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final GlobalKey key = GlobalKey();
    const String label = 'Label';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LinearProgressIndicator(
          key: key,
          value: 0.25,
          semanticsLabel: label,
        ),
      ),
    );

    expect(tester.getSemantics(find.byKey(key)), matchesSemantics(
      textDirection: TextDirection.ltr,
      label: label,
      value: '25%',
    ));

    handle.dispose();
  });

  testWidgets('LinearProgressIndicator that is determinate does not default a11y value when label is null', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LinearProgressIndicator(
          key: key,
          value: 0.25,
        ),
      ),
    );

    expect(tester.getSemantics(find.byKey(key)), matchesSemantics());

    handle.dispose();
  });

  testWidgets('LinearProgressIndicator that is indeterminate does not default a11y value', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final GlobalKey key = GlobalKey();
    const String label = 'Progress';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LinearProgressIndicator(
          key: key,
          value: 0.25,
          semanticsLabel: label,
        ),
      ),
    );

    expect(tester.getSemantics(find.byKey(key)), matchesSemantics(
      textDirection: TextDirection.ltr,
      label: label,
    ));

    handle.dispose();
  });

  testWidgets('CircularProgressIndicator can be made accessible', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final GlobalKey key = GlobalKey();
    const String label = 'Label';
    const String value = '25%';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CircularProgressIndicator(
          key: key,
          value: 0.25,
          semanticsLabel: label,
          semanticsValue: value,
        ),
      ),
    );

    expect(tester.getSemantics(find.byKey(key)), matchesSemantics(
      textDirection: TextDirection.ltr,
      label: label,
      value: value,
    ));

    handle.dispose();
  });

  testWidgets('RefreshProgressIndicator can be made accessible', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final GlobalKey key = GlobalKey();
    const String label = 'Label';
    const String value = '25%';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RefreshProgressIndicator(
          key: key,
          semanticsLabel: label,
          semanticsValue: value,
        ),
      ),
    );

    expect(tester.getSemantics(find.byKey(key)), matchesSemantics(
      textDirection: TextDirection.ltr,
      label: label,
      value: value,
    ));


    handle.dispose();
  });

  testWidgets('Indeterminate CircularProgressIndicator uses expected animation', (WidgetTester tester) async {
    final AnimationSheetBuilder animationSheet = AnimationSheetBuilder(frameSize: const Size(40, 40));

    await tester.pumpFrames(animationSheet.record(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: CircularProgressIndicator(),
        ),
      ),
    ), const Duration(seconds: 2));

    tester.binding.setSurfaceSize(animationSheet.sheetSize());

    final Widget display = await animationSheet.display();
    await tester.pumpWidget(display);

    await expectLater(
      find.byWidget(display),
      matchesGoldenFile('material.circular_progress_indicator.indeterminate.png'),
    );
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/42767
}
