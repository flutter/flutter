// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

enum ImplicitAnimatedWidgetType {
  AnimatedContainer,
  AnimatedPadding,
  AnimatedAlign,
  AnimatedPositioned,
  AnimatedPositionedDirectional,
  AnimatedOpacity,
  AnimatedDefaultTextStyle,
  AnimatedPhysicalModel,
}

class MockOnEndFunction implements Function {
  int called = 0;

  void call() {
    called++;
  }
}

void main() {
  MockOnEndFunction mockOnEndFunction;
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
    final BoxDecoration result = tween.lerp(0.25);
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

  testWidgets('onEnd callback test', (WidgetTester tester) async {
    int i = 0;
    for (ImplicitAnimatedWidgetType widgetType
        in ImplicitAnimatedWidgetType.values) {
      await tester.pumpWidget(wrap(
          child: TestAnimatedWidget(mockOnEndFunction, switchKey, widgetType)));

      final Finder widgetFinder = find.byKey(switchKey);

      await tester.tap(widgetFinder);

      await tester.pumpAndSettle();

      expect(mockOnEndFunction.called, ++i);
    }
  });
}

Widget wrap({Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      child: Center(child: child),
    ),
  );
}

class TestAnimatedWidget extends StatefulWidget {
  const TestAnimatedWidget(this.callback, this.switchKey, this.widgetType);

  final VoidCallback callback;
  final Key switchKey;
  final ImplicitAnimatedWidgetType widgetType;

  @override
  State<StatefulWidget> createState() => _TestAnimatedWidgetState();
}

class _TestAnimatedWidgetState extends State<TestAnimatedWidget> {
  bool toggle = false;

  void onChanged(bool v) {
    setState(() {
      toggle = v;
    });
  }

  Widget getAnimatedWidget() {
    const Widget child = Placeholder();
    const Duration duration = Duration(milliseconds: 10);

    switch (widget.widgetType) {
      case ImplicitAnimatedWidgetType.AnimatedContainer:
        return AnimatedContainer(
          child: child,
          duration: duration,
          onEnd: widget.callback,
          width: toggle ? 10 : 20,
        );
      case ImplicitAnimatedWidgetType.AnimatedPadding:
        return AnimatedPadding(
          child: child,
          duration: duration,
          onEnd: widget.callback,
          padding:
              toggle ? const EdgeInsets.all(8.0) : const EdgeInsets.all(16.0),
        );
      case ImplicitAnimatedWidgetType.AnimatedAlign:
        return AnimatedAlign(
          child: child,
          duration: duration,
          onEnd: widget.callback,
          alignment: toggle ? Alignment.topLeft : Alignment.bottomRight,
        );
      case ImplicitAnimatedWidgetType.AnimatedPositioned:
        return AnimatedPositioned(
          child: child,
          duration: duration,
          onEnd: widget.callback,
          left: toggle ? 10 : 20,
        );
      case ImplicitAnimatedWidgetType.AnimatedPositionedDirectional:
        return AnimatedPositionedDirectional(
          child: child,
          duration: duration,
          onEnd: widget.callback,
          start: toggle ? 10 : 20,
        );
      case ImplicitAnimatedWidgetType.AnimatedOpacity:
        return AnimatedOpacity(
          child: child,
          duration: duration,
          onEnd: widget.callback,
          opacity: toggle ? 0.1 : 0.9,
        );
      case ImplicitAnimatedWidgetType.AnimatedDefaultTextStyle:
        return AnimatedDefaultTextStyle(
            child: child,
            duration: duration,
            onEnd: widget.callback,
            style: toggle
                ? const TextStyle(fontStyle: FontStyle.italic)
                : const TextStyle(fontStyle: FontStyle.normal));
      case ImplicitAnimatedWidgetType.AnimatedPhysicalModel:
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
    return null;
  }

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
