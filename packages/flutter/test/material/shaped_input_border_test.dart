// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ShapedInputBorder constructor', () {
    const inputBorder = ShapedInputBorder(shape: RoundedRectangleBorder());
    expect(inputBorder.borderSide, const BorderSide());
    expect(inputBorder.shape, const RoundedRectangleBorder());
    expect(inputBorder.gapPadding, 4.0);
    expect(inputBorder.isOutline, true);
  });

  test('ShapedInputBorder with RoundedSuperellipseBorder', () {
    const inputBorder = ShapedInputBorder(
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    );
    expect(inputBorder.borderSide, const BorderSide());
    expect(
      inputBorder.shape,
      const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    );
    expect(inputBorder.gapPadding, 4.0);
    expect(inputBorder.isOutline, true);
  });

  test('ShapedInputBorder copyWith, ==, hashCode', () {
    const inputBorder = ShapedInputBorder(shape: RoundedRectangleBorder());
    final ShapedInputBorder copy = inputBorder.copyWith();
    expect(inputBorder, copy);
    expect(inputBorder.hashCode, copy.hashCode);

    final ShapedInputBorder copy2 = inputBorder.copyWith(
      borderSide: const BorderSide(color: Colors.blue),
      shape: const StadiumBorder(),
      gapPadding: 8.0,
    );
    expect(copy2.borderSide, const BorderSide(color: Colors.blue));
    expect(copy2.shape, const StadiumBorder());
    expect(copy2.gapPadding, 8.0);
    expect(inputBorder == copy2, false);
  });

  test('ShapedInputBorder scale', () {
    const inputBorder = ShapedInputBorder(
      borderSide: BorderSide(width: 2.0),
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
    );
    final ShapedInputBorder scaled = inputBorder.scale(2.0);
    expect(scaled.borderSide.width, 4.0);
    expect(
      scaled.shape,
      const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
    );
    expect(scaled.gapPadding, 8.0);
  });

  test('ShapedInputBorder lerp', () {
    const inputBorder1 = ShapedInputBorder(
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))),
      gapPadding: 2.0,
    );
    const inputBorder2 = ShapedInputBorder(
      borderSide: BorderSide(width: 3.0),
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      gapPadding: 6.0,
    );

    final lerped = ShapeBorder.lerp(inputBorder1, inputBorder2, 0.5)! as ShapedInputBorder;
    expect(lerped.borderSide.width, 2.0);
    expect(
      lerped.shape,
      const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
    );
    expect(
      lerped.gapPadding,
      2.0,
    ); // gapPadding is not interpolated, it takes the value from the source
  });

  test('ShapedInputBorder dimensions', () {
    const inputBorder = ShapedInputBorder(
      borderSide: BorderSide(width: 4.0),
      shape: RoundedRectangleBorder(),
    );
    expect(inputBorder.dimensions, const EdgeInsets.all(4.0));
  });

  testWidgets('ShapedInputBorder paint with RoundedSuperellipseBorder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextField(
              decoration: InputDecoration(
                border: ShapedInputBorder(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelText: 'Test Label',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShapedInputBorder paint with gap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextField(
              decoration: InputDecoration(
                border: ShapedInputBorder(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelText: 'Test Label',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShapedInputBorder paint with StadiumBorder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextField(
              decoration: InputDecoration(
                border: ShapedInputBorder(
                  shape: StadiumBorder(),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelText: 'Test Label',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('ShapedInputBorder getInnerPath', () {
    const inputBorder = ShapedInputBorder(
      borderSide: BorderSide(width: 4.0),
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    );
    final Path path = inputBorder.getInnerPath(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0));
    expect(path, isNotNull);
  });

  test('ShapedInputBorder getOuterPath', () {
    const inputBorder = ShapedInputBorder(
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    );
    final Path path = inputBorder.getOuterPath(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0));
    expect(path, isNotNull);
  });

  test('ShapedInputBorder paintInterior', () {
    const inputBorder = ShapedInputBorder(
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    );
    expect(inputBorder.preferPaintInterior, true);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    inputBorder.paintInterior(canvas, const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0), paint);

    recorder.endRecording();
  });
}
