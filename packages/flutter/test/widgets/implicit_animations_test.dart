// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedContainerWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('AnimatedPadding onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedPaddingWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('AnimatedAlign onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedAlignWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('AnimatedPositioned onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedPositionedWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('AnimatedPositionedDirectional onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedPositionedDirectionalWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('AnimatedOpacity onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedOpacityWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);
    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('AnimatedOpacity transition test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        switchKey: switchKey,
        state: _TestAnimatedOpacityWidgetState(),
      )
    ));

    final Finder switchFinder = find.byKey(switchKey);
    final FadeTransition opacityWidget = tester.widget<FadeTransition>(
      find.ancestor(
        of: find.byType(Placeholder),
        matching: find.byType(FadeTransition),
      ).first,
    );

    await tester.tap(switchFinder);
    await tester.pump();
    expect(opacityWidget.opacity.value, equals(0.0));

    await tester.pump(const Duration(milliseconds: 500));
    expect(opacityWidget.opacity.value, equals(0.5));
    await tester.pump(const Duration(milliseconds: 250));
    expect(opacityWidget.opacity.value, equals(0.75));
    await tester.pump(const Duration(milliseconds: 250));
    expect(opacityWidget.opacity.value, equals(1.0));
  });


  testWidgets('SliverAnimatedOpacity onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(TestAnimatedWidget(
      callback: mockOnEndFunction.handler,
      switchKey: switchKey,
      state: _TestSliverAnimatedOpacityWidgetState(),
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('SliverAnimatedOpacity transition test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        switchKey: switchKey,
        state: _TestSliverAnimatedOpacityWidgetState(),
      )
    ));

    final Finder switchFinder = find.byKey(switchKey);
    final SliverFadeTransition opacityWidget = tester.widget<SliverFadeTransition>(
      find.ancestor(
        of: find.byType(Placeholder),
        matching: find.byType(SliverFadeTransition),
      ).first,
    );

    await tester.tap(switchFinder);
    await tester.pump();
    expect(opacityWidget.opacity.value, equals(0.0));

    await tester.pump(const Duration(milliseconds: 500));
    expect(opacityWidget.opacity.value, equals(0.5));
    await tester.pump(const Duration(milliseconds: 250));
    expect(opacityWidget.opacity.value, equals(0.75));
    await tester.pump(const Duration(milliseconds: 250));
    expect(opacityWidget.opacity.value, equals(1.0));
  });

  testWidgets('AnimatedDefaultTextStyle onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedDefaultTextStyleWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('AnimatedPhysicalModel onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedPhysicalModelWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('TweenAnimationBuilder onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestTweenAnimationBuilderWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });

  testWidgets('AnimatedTheme onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      child: TestAnimatedWidget(
        callback: mockOnEndFunction.handler,
        switchKey: switchKey,
        state: _TestAnimatedThemeWidgetState(),
      )
    ));

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(additionalDelay);
    expect(mockOnEndFunction.called, 1);
  });
}

Widget wrap({required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      child: Center(child: child),
    ),
  );
}

class TestAnimatedWidget extends StatefulWidget {
  const TestAnimatedWidget({
    Key? key,
    this.callback,
    required this.switchKey,
    required this.state,
  }) : super(key: key);
  final VoidCallback? callback;
  final Key switchKey;
  final State<StatefulWidget> state;

  @override
  State<StatefulWidget> createState() => state; // ignore: no_logic_in_create_state, this test predates the lint
}

abstract class _TestAnimatedWidgetState extends State<TestAnimatedWidget> {
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
    final Widget animatedWidget = getAnimatedWidget();

    return Stack(
      children: <Widget>[
        animatedWidget,
        Switch(key: widget.switchKey, value: toggle, onChanged: onChanged),
      ],
    );
  }
}

class _TestAnimatedContainerWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedContainer(
      child: child,
      duration: duration,
      onEnd: widget.callback,
      width: toggle ? 10 : 20,
    );
  }
}

class _TestAnimatedPaddingWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedPadding(
      child: child,
      duration: duration,
      onEnd: widget.callback,
      padding:
      toggle ? const EdgeInsets.all(8.0) : const EdgeInsets.all(16.0),
    );
  }
}

class _TestAnimatedAlignWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedAlign(
      child: child,
      duration: duration,
      onEnd: widget.callback,
      alignment: toggle ? Alignment.topLeft : Alignment.bottomRight,
    );
  }
}

class _TestAnimatedPositionedWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedPositioned(
      child: child,
      duration: duration,
      onEnd: widget.callback,
      left: toggle ? 10 : 20,
    );
  }
}

class _TestAnimatedPositionedDirectionalWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedPositionedDirectional(
      child: child,
      duration: duration,
      onEnd: widget.callback,
      start: toggle ? 10 : 20,
    );
  }
}

class _TestAnimatedOpacityWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedOpacity(
      child: child,
      duration: duration,
      onEnd: widget.callback,
      opacity: toggle ? 1.0 : 0.0,
    );
  }
}

class _TestSliverAnimatedOpacityWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return SliverAnimatedOpacity(
      sliver: SliverToBoxAdapter(child: child),
      duration: duration,
      onEnd: widget.callback,
      opacity: toggle ? 1.0 : 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget animatedWidget = getAnimatedWidget();

    return Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            animatedWidget,
            SliverToBoxAdapter(
              child: Switch(
                key: widget.switchKey,
                value: toggle,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestAnimatedDefaultTextStyleWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedDefaultTextStyle(
      child: child,
      duration: duration,
      onEnd: widget.callback,
      style: toggle
        ? const TextStyle(fontStyle: FontStyle.italic)
        : const TextStyle(fontStyle: FontStyle.normal));
  }
}

class _TestAnimatedPhysicalModelWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedPhysicalModel(
      child: child,
      duration: duration,
      onEnd: widget.callback,
      color: toggle ? Colors.red : Colors.green,
      elevation: 0,
      shadowColor: Colors.blue,
      shape: BoxShape.rectangle,
    );
  }
}

class _TestTweenAnimationBuilderWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return TweenAnimationBuilder<double>(
      child: child,
      tween: Tween<double>(begin: 1, end: 2),
      duration: duration,
      onEnd: widget.callback,
      builder: (BuildContext context, double? size, Widget? child) {
        return Container(
          child: child,
          width: size,
          height: size,
        );
      },
    );
  }
}

class _TestAnimatedThemeWidgetState extends _TestAnimatedWidgetState {
  @override
  Widget getAnimatedWidget() {
    return AnimatedTheme(
      child: child,
      data: toggle ? ThemeData.dark() : ThemeData.light(),
      duration: duration,
      onEnd: widget.callback,
    );
  }
}
