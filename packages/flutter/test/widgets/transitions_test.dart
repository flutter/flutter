// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('toString control test', (WidgetTester tester) async {
    final Widget widget = new FadeTransition(
      opacity: kAlwaysCompleteAnimation,
      child: const Text('Ready'),
    );
    expect(widget.toString, isNot(throwsException));
  });

  group('ContainerTransition test', () {
    final DecorationTween decorationTween = new DecorationTween(
      begin: new BoxDecoration(
        backgroundColor: const Color(0xFFFFFFFF),
        border: new Border.all(
          color: const Color(0xFF000000),
          style: BorderStyle.solid,
          width: 4.0,
        ),
        borderRadius: BorderRadius.zero,
        shape: BoxShape.rectangle,
        boxShadow: const <BoxShadow> [const BoxShadow(
          color: const Color(0x66000000),
          blurRadius: 10.0,
          spreadRadius: 4.0,
        )],
      ),
      end: new BoxDecoration(
        backgroundColor: const Color(0xFF000000),
        border: new Border.all(
          color: const Color(0xFF202020),
          style: BorderStyle.solid,
          width: 1.0,
        ),
        borderRadius: new BorderRadius.circular(10.0),
        shape: BoxShape.rectangle,
        // No shadow.
      ),
    );

    AnimationController controller;

    setUp(() {
      controller = new AnimationController(vsync: const TestVSync());
    });

    testWidgets(
      'ContainerTransition decoration test', 
      (WidgetTester tester) async {
        final ContainerTransition transitionUnderTest = new ContainerTransition(
          decoration: decorationTween.animate(controller),
          child: new Text("Doesn't matter"),
        );
        
        await tester.pumpWidget(transitionUnderTest);
        RenderDecoratedBox actualBox = 
            tester.renderObject(find.byType(DecoratedBox));
        BoxDecoration actualDecoration = actualBox.decoration;

        expect(actualDecoration.backgroundColor, const Color(0xFFFFFFFF));
        expect(actualDecoration.boxShadow[0].blurRadius, 10.0);
        expect(actualDecoration.boxShadow[0].spreadRadius, 4.0);
        expect(actualDecoration.boxShadow[0].color, const Color(0x66000000));

        controller.value = 0.5;

        await tester.pump();
        actualBox = tester.renderObject(find.byType(DecoratedBox));
        actualDecoration = actualBox.decoration;

        expect(actualDecoration.backgroundColor, const Color(0xFF7F7F7F));
        expect(actualDecoration.border.left.width, 2.5);
        expect(actualDecoration.border.left.style, BorderStyle.solid);
        expect(actualDecoration.border.left.color, const Color(0xFF101010));
        expect(actualDecoration.borderRadius, new BorderRadius.circular(5.0));
        expect(actualDecoration.shape, BoxShape.rectangle);
        expect(actualDecoration.boxShadow[0].blurRadius, 5.0);
        expect(actualDecoration.boxShadow[0].spreadRadius, 2.0);
        // Scaling a shadow doesn't change the color.
        expect(actualDecoration.boxShadow[0].color, const Color(0x66000000));

        controller.value = 1.0;

        await tester.pump();
        actualBox = tester.renderObject(find.byType(DecoratedBox));
        actualDecoration = actualBox.decoration;

        expect(actualDecoration.backgroundColor, const Color(0xFF000000));
        expect(actualDecoration.boxShadow, null);
      }
    );
  });
}
