// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RoundedSuperellipseInputBorder constructor', () {
    const RoundedSuperellipseInputBorder inputBorder = RoundedSuperellipseInputBorder();
    expect(inputBorder.borderSide, const BorderSide());
    expect(inputBorder.borderRadius, const BorderRadius.all(Radius.circular(4.0)));
    expect(inputBorder.gapPadding, 4.0);
    expect(inputBorder.isOutline, true);
  });

  test('RoundedSuperellipseInputBorder copyWith, ==, hashCode', () {
    const RoundedSuperellipseInputBorder inputBorder = RoundedSuperellipseInputBorder();
    final RoundedSuperellipseInputBorder copy = inputBorder.copyWith();
    expect(inputBorder, copy);
    expect(inputBorder.hashCode, copy.hashCode);

    final RoundedSuperellipseInputBorder copy2 = inputBorder.copyWith(
      borderSide: const BorderSide(color: Colors.blue),
      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      gapPadding: 8.0,
    );
    expect(copy2.borderSide, const BorderSide(color: Colors.blue));
    expect(copy2.borderRadius, const BorderRadius.all(Radius.circular(8.0)));
    expect(copy2.gapPadding, 8.0);
    expect(inputBorder == copy2, false);
  });

  test('RoundedSuperellipseInputBorder scale', () {
    const RoundedSuperellipseInputBorder inputBorder = RoundedSuperellipseInputBorder(
      borderSide: BorderSide(width: 2.0),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    );
    final RoundedSuperellipseInputBorder scaled = inputBorder.scale(2.0);
    expect(scaled.borderSide.width, 4.0);
    expect(scaled.borderRadius, const BorderRadius.all(Radius.circular(20.0)));
    expect(scaled.gapPadding, 8.0);
  });

  test('RoundedSuperellipseInputBorder lerp', () {
    const RoundedSuperellipseInputBorder inputBorder1 = RoundedSuperellipseInputBorder(
      gapPadding: 2.0,
    );
    const RoundedSuperellipseInputBorder inputBorder2 = RoundedSuperellipseInputBorder(
      borderSide: BorderSide(width: 3.0),
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
      gapPadding: 6.0,
    );

    final RoundedSuperellipseInputBorder lerped =
        ShapeBorder.lerp(inputBorder1, inputBorder2, 0.5)! as RoundedSuperellipseInputBorder;
    expect(lerped.borderSide.width, 2.0);
    expect(lerped.borderRadius, const BorderRadius.all(Radius.circular(8.0)));
    expect(
      lerped.gapPadding,
      2.0,
    ); // gapPadding is not interpolated, it takes the value from the source
  });

  test('RoundedSuperellipseInputBorder dimensions', () {
    const RoundedSuperellipseInputBorder inputBorder = RoundedSuperellipseInputBorder(
      borderSide: BorderSide(width: 4.0),
    );
    expect(inputBorder.dimensions, const EdgeInsets.all(4.0));
  });

  testWidgets('RoundedSuperellipseInputBorder paint', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextField(
              decoration: InputDecoration(
                border: RoundedSuperellipseInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
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

  testWidgets('RoundedSuperellipseInputBorder paint with gap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextField(
              decoration: InputDecoration(
                border: RoundedSuperellipseInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
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

  test('RoundedSuperellipseInputBorder getInnerPath', () {
    const RoundedSuperellipseInputBorder inputBorder = RoundedSuperellipseInputBorder(
      borderSide: BorderSide(width: 4.0),
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    );
    final Path path = inputBorder.getInnerPath(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0));
    expect(path, isNotNull);
  });

  test('RoundedSuperellipseInputBorder getOuterPath', () {
    const RoundedSuperellipseInputBorder inputBorder = RoundedSuperellipseInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    );
    final Path path = inputBorder.getOuterPath(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0));
    expect(path, isNotNull);
  });

  test('RoundedSuperellipseInputBorder paintInterior', () {
    const RoundedSuperellipseInputBorder inputBorder = RoundedSuperellipseInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    );
    expect(inputBorder.preferPaintInterior, true);

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint();

    inputBorder.paintInterior(canvas, const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0), paint);

    recorder.endRecording();
  });
}
