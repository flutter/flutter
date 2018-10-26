// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

void main() {
  testWidgets('InkWell gestures control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: InkWell(
              onTap: () {
                log.add('tap');
              },
              onDoubleTap: () {
                log.add('double-tap');
              },
              onLongPress: () {
                log.add('long-press');
              },
              onTapDown: (TapDownDetails details) {
                log.add('tap-down');
              },
              onTapCancel: () {
                log.add('tap-cancel');
              },
            ),
          ),
        )
      )
    );

    await tester.tap(find.byType(InkWell), pointer: 1);

    expect(log, isEmpty);

    await tester.pump(const Duration(seconds: 1));

    expect(log, equals(<String>['tap-down', 'tap']));
    log.clear();

    await tester.tap(find.byType(InkWell), pointer: 2);
    await tester.tap(find.byType(InkWell), pointer: 3);

    expect(log, equals(<String>['tap-cancel', 'double-tap']));
    log.clear();

    await tester.longPress(find.byType(InkWell), pointer: 4);

    expect(log, equals(<String>['tap-down', 'tap-cancel', 'long-press']));

    log.clear();
    TestGesture gesture = await tester.startGesture(tester.getRect(find.byType(InkWell)).center);
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['tap-down']));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    log.clear();
    gesture = await tester.startGesture(tester.getRect(find.byType(InkWell)).center);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0.0, 200.0));
    await gesture.cancel();
    expect(log, equals(<String>['tap-down', 'tap-cancel']));
  });

  testWidgets('long-press and tap on disabled should not throw', (WidgetTester tester) async {
    await tester.pumpWidget(const Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: InkWell(),
        ),
      )
    ));
    await tester.tap(find.byType(InkWell), pointer: 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.longPress(find.byType(InkWell), pointer: 1);
    await tester.pump(const Duration(seconds: 1));
  });

  group('feedback', () {
    FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
    });

    tearDown(() {
      feedback?.dispose();
    });

    testWidgets('enabled (default)', (WidgetTester tester) async {
      await tester.pumpWidget(Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: InkWell(
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);

      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 2);
      expect(feedback.hapticCount, 0);

      await tester.longPress(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 2);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('disabled', (WidgetTester tester) async {
      await tester.pumpWidget(Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: InkWell(
              onTap: () {},
              onLongPress: () {},
              enableFeedback: false,
            ),
          ),
        )
      ));
      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);

      await tester.longPress(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);
    });
  });

  testWidgets('splashing survives scrolling when keep-alive is enabled', (WidgetTester tester) async {
    Future<void> runTest(bool keepAlive) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: CompositedTransformFollower( // forces a layer, which makes the paints easier to separate out
              link: LayerLink(),
              child: ListView(
                addAutomaticKeepAlives: keepAlive,
                children: <Widget>[
                  Container(height: 500.0, child: InkWell(onTap: () { }, child: const Placeholder())),
                  Container(height: 500.0),
                  Container(height: 500.0),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.renderObject<RenderProxyBox>(find.byType(PhysicalModel)).child, isNot(paints..circle()));
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.renderObject<RenderProxyBox>(find.byType(PhysicalModel)).child, paints..circle());
      await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.drag(find.byType(ListView), const Offset(0.0, 1000.0));
      await tester.pump(const Duration(milliseconds: 10));
      expect(
        tester.renderObject<RenderProxyBox>(find.byType(PhysicalModel)).child,
        keepAlive ? (paints..circle()) : isNot(paints..circle()),
      );
    }
    await runTest(true);
    await runTest(false);
  });

  testWidgets('excludeFromSemantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: InkWell(
          onTap: () { },
          child: const Text('Button'),
        ),
      ),
    ));
    expect(semantics, includesNodeWith(label: 'Button', actions: <SemanticsAction>[SemanticsAction.tap]));

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: InkWell(
          onTap: () { },
          child: const Text('Button'),
          excludeFromSemantics: true,
        ),
      ),
    ));
    expect(semantics, isNot(includesNodeWith(label: 'Button', actions: <SemanticsAction>[SemanticsAction.tap])));

    semantics.dispose();
  });
}
