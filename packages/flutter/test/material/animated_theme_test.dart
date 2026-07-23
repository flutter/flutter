// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockOnEndFunction {
  int called = 0;

  void handler() {
    called++;
  }
}

const Duration _animationDuration = Duration(milliseconds: 1000);
const Duration _additionalDelay = Duration(milliseconds: 1);

void main() {
  late _MockOnEndFunction mockOnEndFunction;
  const switchKey = Key('switchKey');

  setUp(() {
    mockOnEndFunction = _MockOnEndFunction();
  });

  testWidgets('AnimatedTheme onEnd callback test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: _TestAnimatedThemeWidget(
            callback: mockOnEndFunction.handler,
            switchKey: switchKey,
          ),
        ),
      ),
    );

    final Finder widgetFinder = find.byKey(switchKey);

    await tester.tap(widgetFinder);

    await tester.pump();
    expect(mockOnEndFunction.called, 0);
    await tester.pump(_animationDuration);
    expect(mockOnEndFunction.called, 0);
    await tester.pump(_additionalDelay);
    expect(mockOnEndFunction.called, 1);

    await tester.tap(widgetFinder);

    await tester.pump();
    await tester.pump(_animationDuration + _additionalDelay);
    expect(mockOnEndFunction.called, 2);

    await tester.tap(widgetFinder);

    await tester.pump();
    await tester.pump(_animationDuration + _additionalDelay);
    expect(mockOnEndFunction.called, 3);
  });
}

class _TestAnimatedThemeWidget extends StatefulWidget {
  const _TestAnimatedThemeWidget({this.callback, required this.switchKey});

  final VoidCallback? callback;
  final Key switchKey;

  @override
  State<_TestAnimatedThemeWidget> createState() => _TestAnimatedThemeWidgetState();
}

class _TestAnimatedThemeWidgetState extends State<_TestAnimatedThemeWidget> {
  bool toggle = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedTheme(
          data: toggle ? ThemeData.dark() : ThemeData(),
          duration: _animationDuration,
          onEnd: widget.callback,
          child: const Placeholder(),
        ),
        GestureDetector(
          key: widget.switchKey,
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              toggle = !toggle;
            });
          },
          child: const SizedBox(width: 48.0, height: 48.0),
        ),
      ],
    );
  }
}
