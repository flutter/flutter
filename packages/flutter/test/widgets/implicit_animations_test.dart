// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockOnEndFunction {
  int called = 0;

  void handler() {
    called++;
  }
}

const Duration animationDuration = Duration(milliseconds:1000);
const Duration additionalDelay = Duration(milliseconds:1);

void main() {
  late MockOnEndFunction mockOnEndFunction;
  const Key switchKey = Key('switchKey');

  setUp(() {
    mockOnEndFunction = MockOnEndFunction();
  });

  testWidgets('BoxConstraintsTween control test', (WidgetTester tester) async {
    final BoxConstraintsTween tween = BoxConstraintsTween(
      begin: BoxConstraints.tight(const Size(20.0, 50.0)),
      end: BoxConstraints.tight(const Size(10.0, 30.0)),
    );
    final BoxConstraints result = tween.lerp(0.25);
    expect(result.minWidth, 17.5);
    expect(result.maxWidth, 17.5);
    expect(result.minHeight, 45.0);
    expect(result.maxHeight, 45.0);
  });

  testWidgets('DecorationTween control test', (WidgetTester tester) async {
    final DecorationTween tween = DecorationTween(
      begin: const BoxDecoration(color: Color(0xFF00FF00)),
      end: const BoxDecoration(color: Color(0xFFFFFF00)),
    );
    final BoxDecoration result = tween.lerp(0.25) as BoxDecoration;
    expect(result.color, const Color(0xFF3FFF00));
  });

  testWidgets('EdgeInsetsTween control test', (WidgetTester tester) async {
    final EdgeInsetsTween tween = EdgeInsetsTween(
      begin: const EdgeInsets.symmetric(vertical: 50.0),
      end: const EdgeInsets.only(top: 10.0, bottom: 30.0),
    );
    final EdgeInsets result = tween.lerp(0.25);
    expect(result.left, 0.0);
    expect(result.right, 0.0);
    expect(result.top, 40.0);
    expect(result.bottom, 45.0);
  });

  testWidgets('Matrix4Tween control test', (WidgetTester tester) async {
    final Matrix4Tween tween = Matrix4Tween(
      begin: Matrix4.translationValues(10.0, 20.0, 30.0),
      end: Matrix4.translationValues(14.0, 24.0, 34.0),
    );
    final Matrix4 result = tween.lerp(0.25);
    expect(result, equals(Matrix4.translationValues(11.0, 21.0, 31.0)));
  });

  testWidgets('AnimatedContainer onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedContainer(
            padding: EdgeInsets.zero,
            duration: const Duration(seconds: 2),
            onEnd: increment,
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedContainer(
            padding: const EdgeInsets.all(8.0),
            duration: const Duration(seconds: 2),
            onEnd: increment,
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedPadding onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedPadding(
            padding: EdgeInsets.zero,
            duration: const Duration(seconds: 2),
            onEnd: increment,
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedPadding(
            padding: const EdgeInsets.all(8.0),
            duration: const Duration(seconds: 2),
            onEnd: increment,
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedAlign onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedAlign(
            alignment: Alignment.center,
            duration: const Duration(seconds: 2),
            onEnd: increment,
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedAlign(
            alignment: Alignment.topCenter,
            duration: const Duration(seconds: 2),
            onEnd: increment,
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedPositioned onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedPositioned(
            left: 0.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedPositioned(
            left: 8.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedPositionedDirectional onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            AnimatedPositionedDirectional(
              start: 0.0,
              duration: const Duration(seconds: 2),
              onEnd: increment,
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            AnimatedPositionedDirectional(
              start: 8.0,
              duration: const Duration(seconds: 2),
              onEnd: increment,
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

   testWidgets('AnimatedSlide onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedSlide(
            offset: Offset.zero,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedSlide(
            offset: const Offset(8.0, 8.0),
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedSlide transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedSlide(
            offset: Offset.zero,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
    Offset translation() => findBuiltValue<AnimatedSlide, FractionalTranslation>(tester).translation;

    await tester.pump(const Duration(seconds: 1));
    expect(translation(), Offset.zero);

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedSlide(
            offset: Offset(8.0, 8.0),
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(translation(), const Offset(4.0, 4.0));

    await tester.pump(const Duration(seconds: 1));
    expect(translation(), const Offset(8.0, 8.0));
  });

  testWidgets('AnimatedScale onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedScale(
            scale: 1.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedScale(
            scale: 2.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedScale transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedScale(
            scale: 1.0,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
    double? scale() => MatrixUtils.getAsScale(findBuiltValue<AnimatedScale, Transform>(tester).transform);

    await tester.pump(const Duration(seconds: 1));
    expect(scale(), 1.0);

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedScale(
            scale: 2.0,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(scale(), 1.5);

    await tester.pump(const Duration(seconds: 1));
    expect(scale(), 2.0);
  });

  testWidgets('AnimatedRotation onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedRotation(
            turns: 0.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedRotation(
            turns: 1.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedRotation transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedRotation(
            turns: 0.0,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
    Matrix4 transform() => findBuiltValue<AnimatedRotation, Transform>(tester).transform;
    Matrix4 rotated(double turns) => Transform.rotate(angle: turns * 2 * math.pi).transform;

    await tester.pump(const Duration(seconds: 1));
    expect(transform(), rotated(0.0));

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedRotation(
            turns: 1.0,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(transform(), rotated(0.5));

    await tester.pump(const Duration(seconds: 1));
    expect(transform(), rotated(1.0));
  });

  testWidgets('AnimatedOpacity onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedOpacity(
            opacity: 0.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedOpacity transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedOpacity(
            opacity: 0.0,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    double opacity() => findBuiltValue<AnimatedOpacity, Opacity>(tester).opacity;

    await tester.pump(const Duration(seconds: 1));
    expect(opacity(), 0.0);

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(opacity(), 0.5);

    await tester.pump(const Duration(seconds: 1));
    expect(opacity(), 1.0);
  });

  testWidgets('AnimatedFractionallySizedBox onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedFractionallySizedBox(
            heightFactor: 1.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedFractionallySizedBox(
            heightFactor: 0.5,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedFractionallySizedBox transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedFractionallySizedBox(
            heightFactor: 1.0,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    double? heightFactor() => findBuiltValue<AnimatedFractionallySizedBox, FractionallySizedBox>(tester).heightFactor;

    await tester.pump(const Duration(seconds: 1));
    expect(heightFactor(), 1.0);

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedFractionallySizedBox(
            heightFactor: 0.5,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(heightFactor(), 0.75);


    await tester.pump(const Duration(seconds: 1));
    expect(heightFactor(), 0.5);
  });

  testWidgets('SliverAnimatedOpacity onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(slivers: <Widget>[
          SliverAnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ]),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(slivers: <Widget>[
          SliverAnimatedOpacity(
            opacity: 0.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ]),
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('SliverAnimatedOpacity transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(slivers: <Widget>[
          SliverAnimatedOpacity(
            opacity: 1.0,
            duration: Duration(seconds: 2),
            sliver: SliverToBoxAdapter(
              child: Text('a'),
            ),
          ),
        ]),
      ),
    );

    double opacity() => findBuiltValue<SliverAnimatedOpacity, SliverOpacity>(tester).opacity;

    await tester.pump(const Duration(seconds: 1));
    expect(opacity(), 1.0);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(slivers: <Widget>[
          SliverAnimatedOpacity(
            opacity: 0.5,
            duration: Duration(seconds: 2),
            sliver: SliverToBoxAdapter(
              child: Text('a'),
            ),
          ),
        ]),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(opacity(), 0.75);


    await tester.pump(const Duration(seconds: 1));
    expect(opacity(), 0.5);
  });

  testWidgets('AnimatedDefaultTextStyle onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedDefaultTextStyle(
            style: const TextStyle(letterSpacing: 0.0),
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedDefaultTextStyle(
            style: const TextStyle(letterSpacing: 1.0),
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedDefaultTextStyle transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedDefaultTextStyle(
            style: TextStyle(letterSpacing: 0.0),
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    double? letterSpacing() => findBuiltValue<AnimatedDefaultTextStyle, DefaultTextStyle>(tester).style.letterSpacing;

    await tester.pump(const Duration(seconds: 1));
    expect(letterSpacing(), 0.0);

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedDefaultTextStyle(
            style: TextStyle(letterSpacing: 1.0),
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(letterSpacing(), 0.5);


    await tester.pump(const Duration(seconds: 1));
    expect(letterSpacing(), 1.0);
  });

  testWidgets('AnimatedPhysicalModel onEnd callback test', (WidgetTester tester) async {
    int counter = 0;
    void increment() => counter += 1;

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedPhysicalModel(
            color: Colors.black,
            shadowColor: Colors.black,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedPhysicalModel(
            color: Colors.black,
            shadowColor: Colors.black,
            elevation: 1.0,
            duration: const Duration(seconds: 2),
            onEnd: increment,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(0));

    await tester.pump(const Duration(seconds: 1));
    expect(counter, equals(1));
  });

  testWidgets('AnimatedPhysicalModel transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedPhysicalModel(
            color: Colors.black,
            shadowColor: Colors.black,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    double elevation() => findBuiltValue<AnimatedPhysicalModel, PhysicalModel>(tester).elevation;

    await tester.pump(const Duration(seconds: 1));
    expect(elevation(), 0.0);

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          AnimatedPhysicalModel(
            color: Colors.black,
            shadowColor: Colors.black,
            elevation: 1.0,
            duration: Duration(seconds: 2),
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(elevation(), 0.5);

    await tester.pump(const Duration(seconds: 1));
    expect(elevation(), 1.0);
  });

  testWidgets('TweenAnimationBuilder onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestTweenAnimationBuilderWidgetState(),
      ),
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);

    await tapTest2and3(tester, widgetFinder, mockOnEndFunction);
  });

  testWidgets('AnimatedTheme onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedThemeWidgetState(),
      ),
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);

    await tapTest2and3(tester, widgetFinder, mockOnEndFunction);
  });

  group('Verify that default args match non-animated variants', () {
    const Widget child = SizedBox.shrink();
    const Color color = Color(0x00000000);

    testWidgets('PhysicalModel default args', (WidgetTester tester) async {
      const AnimatedPhysicalModel animatedPhysicalModel = AnimatedPhysicalModel(
        duration: Duration.zero,
        color: color,
        shadowColor: color,
        child: child,
      );
      const PhysicalModel physicalModel = PhysicalModel(
        color: color,
        shadowColor: color,
        child: child,
      );
      expect(identical(animatedPhysicalModel.shape, physicalModel.shape), isTrue);
      expect(identical(animatedPhysicalModel.clipBehavior, physicalModel.clipBehavior), isTrue);
      expect(identical(animatedPhysicalModel.borderRadius, physicalModel.borderRadius), isTrue);
    });
    // TODO(nate-thegrate): add every class!
  });
}

Future<void> tapTest2and3(WidgetTester tester, Finder widgetFinder,
    MockOnEndFunction mockOnEndFunction) async {
  await tester.tap(widgetFinder);

  await tester.pump();
  await tester.pump(animationDuration + additionalDelay);
  expect(mockOnEndFunction.called, 2);

  await tester.tap(widgetFinder);

  await tester.pump();
  await tester.pump(animationDuration + additionalDelay);
  expect(mockOnEndFunction.called, 3);
}

Widget wrap({required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      child: Center(child: child),
    ),
  );
}

abstract class RebuildCountingState<T extends StatefulWidget> extends State<T> {
  int builds = 0;
}

class TestAnimatedWidget extends StatefulWidget {
  const TestAnimatedWidget({
    super.key,
    this.callback,
    required this.switchKey,
    required this.state,
  });
  final VoidCallback? callback;
  final Key switchKey;
  final State<StatefulWidget> state;

  @override
  State<StatefulWidget> createState() => state; // ignore: no_logic_in_create_state, this test predates the lint
}

abstract class _TestAnimatedWidgetState extends RebuildCountingState<TestAnimatedWidget> {
  bool toggle = false;
  final Widget child = const Placeholder();
  final Duration duration = animationDuration;

  void onChanged(bool v) {
    setState(() {
      toggle = v;
    });
  }

  Widget getAnimatedWidget();

  @override
  Widget build(BuildContext context) {
    builds++;
    final Widget animatedWidget = getAnimatedWidget();

    return Stack(
      children: <Widget>[
        animatedWidget,
        Switch(key: widget.switchKey, value: toggle, onChanged: onChanged),
      ],
    );
  }
}

Built findBuiltValue<Animated, Built extends Widget>(WidgetTester tester) {
  final Finder built = find.descendant(
    of: find.byType(Animated),
    matching: find.byType(Built),
  );
  return tester.widget<Built>(built);
}

class _TestTweenAnimationBuilderWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return TweenAnimationBuilder<double>(
      tween: toggle ? Tween<double>(begin: 1, end: 2) : Tween<double>(begin: 2, end: 1),
      duration: duration,
      onEnd: widget.callback,
      child: child,
      builder: (BuildContext context, double? size, Widget? child) {
        return SizedBox(
          width: size,
          height: size,
          child: child,
        );
      },
    );
  }
}

class _TestAnimatedThemeWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedTheme(
      data: toggle ? ThemeData.dark() : ThemeData.light(),
      duration: duration,
      onEnd: widget.callback,
      child: child,
    );
  }
}
