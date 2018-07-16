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
      new RepaintBoundary(
        child: new Center(
          child: new Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: const Color(0xff00ff00),
            ),
            child: const Text('Hello',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: const Color(0xffff0000)),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Centered.png'),
      skip: !Platform.isLinux,
    );

    await tester.pumpWidget(
      new RepaintBoundary(
        child: new Center(
          child: new Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: const Color(0xff00ff00),
            ),
            child: const Text('Hello world how are you today',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: const Color(0xffff0000)),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Centered.wrap.png'),
      skip: !Platform.isLinux,
    );
  });


  testWidgets('Text Foreground', (WidgetTester tester) async {
    const Color black = const Color(0xFF000000);
    const Color red = const Color(0xFFFF0000);
    const Color blue = const Color(0xFF0000FF);
    final Shader linearGradient = const LinearGradient(colors: <Color>[red, blue]).createShader(new Rect.fromLTWH(0.0, 0.0, 50.0, 20.0));

    await tester.pumpWidget(
      new RepaintBoundary(
        child: new Center(
          child: new Text('Hello',
            textDirection: TextDirection.ltr,
            style: new TextStyle(
              foreground: new Paint()
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
      // this was generated on MacOS and will fail on Linux
      // change to !Platform.isLinux once they're properly generated
      skip: true, // !Platform.isLinux,
    );

    await tester.pumpWidget(
      new RepaintBoundary(
        child: new Center(
          child: new Text('Hello', 
            textDirection: TextDirection.ltr,          
            style: new TextStyle(
              foreground: new Paint()
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
      // this was generated on MacOS and will fail on Linux
      // change to !Platform.isLinux once they're properly generated
      skip: true, // !Platform.isLinux,
    );

    await tester.pumpWidget(
      new RepaintBoundary(
        child: new Center(
          child: new Text('Hello', 
            textDirection: TextDirection.ltr,          
            style: new TextStyle(
              foreground: new Paint()
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
      // this was generated on MacOS and will fail on Linux
      // change to !Platform.isLinux once they're properly generated
      skip: true, // !Platform.isLinux,
    );
  });

  testWidgets('Text Fade', (WidgetTester tester) async {
    await tester.pumpWidget(
        new MaterialApp(
          home: new Scaffold(
            backgroundColor: Colors.transparent,
            body: new RepaintBoundary(
              child: Center(
                child: new Container(
                  width: 200.0,
                  height: 200.0,
                  color: Colors.green,
                  child: new Center(
                    child: new Container(
                      width: 100.0,
                      color: Colors.blue,
                      child: const Text(
                        'Pp PPp PPPp PPPPp PPPPpp PPPPppp PPPPppppp ',
                        style: const TextStyle(color: Colors.black),
                        maxLines: 3,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        )
    );

    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('text_golden.Fade.1.png'),
      skip: !Platform.isLinux,
    );
  });
}
