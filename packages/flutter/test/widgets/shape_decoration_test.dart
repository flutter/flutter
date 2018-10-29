// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/image_data.dart';
import '../painting/mocks_for_image_cache.dart';
import '../rendering/mock_canvas.dart';

Future<void> main() async {
  final ui.Image rawImage = await decodeImageFromList(Uint8List.fromList(kTransparentImage));
  final ImageProvider image = TestImageProvider(0, 0, image: rawImage);
  testWidgets('ShapeDecoration.image', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DecoratedBox(
          decoration: ShapeDecoration(
            shape: Border.all(width: 1.0, color: Colors.white) +
                   Border.all(width: 1.0, color: Colors.black),
            image: DecorationImage(
              image: image,
            ),
          ),
        ),
      ),
    );
    expect(
      find.byType(DecoratedBox),
      paints
        ..drawImageRect(image: rawImage)
        ..rect(color: Colors.black)
        ..rect(color: Colors.white)
    );
  });

  testWidgets('ShapeDecoration.color', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DecoratedBox(
          decoration: ShapeDecoration(
            shape: Border.all(width: 1.0, color: Colors.white) +
                   Border.all(width: 1.0, color: Colors.black),
            color: Colors.blue,
          ),
        ),
      ),
    );
    expect(
      find.byType(DecoratedBox),
      paints
        ..path(color: Color(Colors.blue.value))
        ..rect(color: Colors.black)
        ..rect(color: Colors.white)
    );
  });

  testWidgets('TestBorder and Directionality - 1', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: DecoratedBox(
          decoration: ShapeDecoration(
            shape: TestBorder(log.add),
            color: Colors.green,
          ),
        ),
      ),
    );
    expect(
      log,
      <String>[
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr'
      ],
    );
  });

  testWidgets('TestBorder and Directionality - 2', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: TestBorder(log.add),
            image: DecorationImage(
              image: image,
            ),
          ),
        ),
      ),
    );
    expect(
      log,
      <String>[
        'getInnerPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl'
      ],
    );
  });
}

typedef Logger = void Function(String caller);

class TestBorder extends ShapeBorder {
  const TestBorder(this.onLog) : assert(onLog != null);

  final Logger onLog;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsetsDirectional.only(start: 1.0);

  @override
  ShapeBorder scale(double t) => TestBorder(onLog);

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    onLog('getInnerPath $rect $textDirection');
    return Path();
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    onLog('getOuterPath $rect $textDirection');
    return Path();
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {
    onLog('paint $rect $textDirection');
  }
}
