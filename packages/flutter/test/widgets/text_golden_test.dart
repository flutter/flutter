// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Centered text', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: const Text('Hello',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xffff0000)),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Centered.png'),
    );

    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: const Text('Hello world how are you today',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xffff0000)),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Centered.wrap.png'),
    );
  }, skip: !Platform.isLinux);


  testWidgets('Text Foreground', (WidgetTester tester) async {
    const Color black = Color(0xFF000000);
    const Color red = Color(0xFFFF0000);
    const Color blue = Color(0xFF0000FF);
    final Shader linearGradient = const LinearGradient(
      colors: <Color>[red, blue],
    ).createShader(Rect.fromLTWH(0.0, 0.0, 50.0, 20.0));

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          child: Text('Hello',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              foreground: Paint()
                ..color = black
                ..shader = linearGradient
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('text_golden.Foreground.gradient.png'),
    );

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          child: Text('Hello',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              foreground: Paint()
                ..color = black
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.0
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('text_golden.Foreground.stroke.png'),
    );

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          child: Text('Hello',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              foreground: Paint()
                ..color = black
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.0
                ..shader = linearGradient
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('text_golden.Foreground.stroke_and_gradient.png'),
    );
  }, skip: !Platform.isLinux);

  // TODO(garyq): This test requires an update when the background
  // drawing from the beginning of the line bug is fixed. The current
  // tested version is not completely correct.
  testWidgets('Text Background', (WidgetTester tester) async {
    const Color red = Colors.red;
    const Color blue = Colors.blue;
    const Color translucentGreen = Color(0x5000F000);
    const Color translucentDarkRed = Color(0x500F0000);
    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: RichText(
              textDirection: TextDirection.ltr,
              text: TextSpan(
                text: 'text1 ',
                style: TextStyle(
                  color: translucentGreen,
                  background: Paint()
                    ..color = red.withOpacity(0.5),
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'text2',
                    style: TextStyle(
                      color: translucentDarkRed,
                      background: Paint()
                        ..color = blue.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('text_golden.Background.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('Text Fade', (WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: RepaintBoundary(
              child: Center(
                child: Container(
                  width: 200.0,
                  height: 200.0,
                  color: Colors.green,
                  child: Center(
                    child: Container(
                      width: 100.0,
                      color: Colors.blue,
                      child: const Text(
                        'Pp PPp PPPp PPPPp PPPPpp PPPPppp PPPPppppp ',
                        style: TextStyle(color: Colors.black),
                        maxLines: 3,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
    );

    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('text_golden.Fade.1.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('Default Strut text', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: const Text('Hello\nLine 2\nLine 3',
              textDirection: TextDirection.ltr,
              style: TextStyle(),
              strutStyle: StrutStyle(),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.StrutDefault.png'),
    );
  }, skip: true); // Should only be on linux (skip: !Platform.isLinux).
                  // Disabled for now until font inconsistency is resolved.

  testWidgets('Strut text 1', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: const Text('Hello\nLine2\nLine3',
              textDirection: TextDirection.ltr,
              style: TextStyle(),
              strutStyle: StrutStyle(
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Strut.1.1.png'),
    );
  }, skip: true); // Should only be on linux (skip: !Platform.isLinux).
                  // Disabled for now until font inconsistency is resolved.

  testWidgets('Strut text 2', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: const Text('Hello\nLine 2\nLine 3',
              textDirection: TextDirection.ltr,
              style: TextStyle(),
              strutStyle: StrutStyle(
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Strut.2.1.png'),
    );
  }, skip: true); // Should only be on linux (skip: !Platform.isLinux).
                  // Disabled for now until font inconsistency is resolved.

  testWidgets('Strut text rich', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 150.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: const Text.rich(
              TextSpan(
                text: 'Hello\n',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 30,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Second line!\n',
                    style: TextStyle(
                      fontSize: 5,
                      color: Colors.blue,
                    ),
                  ),
                  TextSpan(
                    text: 'Third line!\n',
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              textDirection: TextDirection.ltr,
              strutStyle: StrutStyle(
                fontSize: 14,
                height: 1.1,
                leading: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Strut.3.1.png'),
    );
  }, skip: true); // Should only be on linux (skip: !Platform.isLinux).
                  // Disabled for now until font inconsistency is resolved.

  testWidgets('Strut text font fallback', (WidgetTester tester) async {
    // Font Fallback
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: const Text('Hello\nLine 2\nLine 3',
              textDirection: TextDirection.ltr,
              style: TextStyle(),
              strutStyle: StrutStyle(
                fontFamily: 'FakeFont 1',
                fontFamilyFallback: <String>[
                  'FakeFont 2',
                  'EvilFont 3',
                  'Nice Font 4',
                  'ahem',
                ],
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Strut.4.1.png'),
    );
  }, skip: true); // Should only be on linux (skip: !Platform.isLinux).
                  // Disabled for now until font inconsistency is resolved.

  testWidgets('Strut text rich forceStrutHeight', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: const Text.rich(
              TextSpan(
                text: 'Hello\n',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 30,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Second line!\n',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue,
                    ),
                  ),
                  TextSpan(
                    text: 'Third line!\n',
                    style: TextStyle(
                      fontSize: 27,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              textDirection: TextDirection.ltr,
              strutStyle: StrutStyle(
                fontSize: 14,
                height: 1.1,
                forceStrutHeight: true,
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.StrutForce.1.1.png'),
    );
  }, skip: true); // Should only be on linux (skip: !Platform.isLinux).
                  // Disabled for now until font inconsistency is resolved.

  testWidgets('Decoration thickness', (WidgetTester tester) async {
    final TextDecoration allDecorations = TextDecoration.combine(
      <TextDecoration>[
        TextDecoration.underline,
        TextDecoration.overline,
        TextDecoration.lineThrough,
      ]
    );

    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 300.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: Text(
              'Hello, wor!\nabcd.',
              style: TextStyle(
                fontSize: 25,
                decoration: allDecorations,
                decorationColor: Colors.blue,
                decorationStyle: TextDecorationStyle.dashed,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Decoration.1.0.png'),
    );
  }, skip: !Platform.isLinux); // Coretext uses different thicknesses for decoration

  testWidgets('Decoration thickness', (WidgetTester tester) async {
    final TextDecoration allDecorations = TextDecoration.combine(
      <TextDecoration>[
        TextDecoration.underline,
        TextDecoration.overline,
        TextDecoration.lineThrough,
      ]
    );

    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            width: 300.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: Color(0xff00ff00),
            ),
            child: Text(
              'Hello, wor!\nabcd.',
              style: TextStyle(
                fontSize: 25,
                decoration: allDecorations,
                decorationColor: Colors.blue,
                decorationStyle: TextDecorationStyle.wavy,
                decorationThickness: 4,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.DecorationThickness.1.0.png'),
    );
  }, skip: !Platform.isLinux); // Coretext uses different thicknesses for decoration
}
