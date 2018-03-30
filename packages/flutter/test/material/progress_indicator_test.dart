// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';

void main() {

  // The "can be constructed" tests that follow are primarily to ensure that any
  // animations started by the progress indicators are stopped at dispose() time.

  testWidgets('LinearProgressIndicator(value: 0.0) can be constructed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const Center(
          child: const SizedBox(
            width: 200.0,
            child: const LinearProgressIndicator(value: 0.0),
          ),
        ),
      ),
    );
  });

  testWidgets('LinearProgressIndicator(value: null) can be constructed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: const Center(
          child: const SizedBox(
            width: 200.0,
            child: const LinearProgressIndicator(value: null),
          ),
        ),
      ),
    );
  });

  testWidgets('LinearProgressIndicator paint (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const Center(
          child: const SizedBox(
            width: 200.0,
            child: const LinearProgressIndicator(value: 0.25),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: new Rect.fromLTRB(0.0, 0.0, 200.0, 6.0))
        ..rect(rect: new Rect.fromLTRB(0.0, 0.0, 50.0, 6.0))
    );

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('LinearProgressIndicator paint (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: const Center(
          child: const SizedBox(
            width: 200.0,
            child: const LinearProgressIndicator(value: 0.25),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: new Rect.fromLTRB(0.0, 0.0, 200.0, 6.0))
        ..rect(rect: new Rect.fromLTRB(150.0, 0.0, 200.0, 6.0))
    );

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('LinearProgressIndicator indeterminate (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const Center(
          child: const SizedBox(
            width: 200.0,
            child: const LinearProgressIndicator(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    final double animationValue = const Interval(0.0, 750.0 / 1800.0, curve: const Cubic(0.2, 0.0, 0.8, 1.0))
      .transform(300.0 / 1800.0);

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: new Rect.fromLTRB(0.0, 0.0, 200.0, 6.0))
        ..rect(rect: new Rect.fromLTRB(0.0, 0.0, animationValue * 200.0, 6.0))
    );

    expect(tester.binding.transientCallbackCount, 1);
  });

  testWidgets('LinearProgressIndicator paint (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: const Center(
          child: const SizedBox(
            width: 200.0,
            child: const LinearProgressIndicator(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    final double animationValue = const Interval(0.0, 750.0 / 1800.0, curve: const Cubic(0.2, 0.0, 0.8, 1.0))
      .transform(300.0 / 1800.0);

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: new Rect.fromLTRB(0.0, 0.0, 200.0, 6.0))
        ..rect(rect: new Rect.fromLTRB(200.0 - animationValue * 200.0, 0.0, 200.0, 6.0))
    );

    expect(tester.binding.transientCallbackCount, 1);
  });

  testWidgets('LinearProgressIndicator with colors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const Center(
          child: const SizedBox(
            width: 200.0,
            child: const LinearProgressIndicator(
              value: 0.25,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.black,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        ..rect(rect: new Rect.fromLTRB(0.0, 0.0, 200.0, 6.0))
        ..rect(rect: new Rect.fromLTRB(0.0, 0.0, 50.0, 6.0), color: Colors.white)
    );
  });

  testWidgets('CircularProgressIndicator(value: 0.0) can be constructed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const CircularProgressIndicator(value: 0.0)
      )
    );
  });

  testWidgets('CircularProgressIndicator(value: null) can be constructed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const CircularProgressIndicator(value: null)
      )
    );
  });

  testWidgets('LinearProgressIndicator causes a repaint when it changes', (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new ListView(children: const <Widget>[const LinearProgressIndicator(value: 0.0)]),
    ));
    final List<Layer> layers1 = tester.layers;
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new ListView(children: const <Widget>[const LinearProgressIndicator(value: 0.5)])),
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

}
