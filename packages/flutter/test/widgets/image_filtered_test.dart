// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

ImageFilter createFilter(Rect bounds) {
  return ImageFilter.matrix((Matrix4.identity()
    ..translate(bounds.center.dx, bounds.center.dy)
    ..rotateZ(pi / 4.0)
    ..translate(- bounds.center.dx, - bounds.center.dy)
  ).storage);
}

void main() {
  testWidgets('Can be constructed with filter', (WidgetTester tester) async {
    const Widget child = SizedBox(width: 100.0, height: 100.0);
    await tester.pumpWidget(ImageFiltered(
      child: child,
      imageFilter: createFilter(Offset.zero & const Size(100.0, 100.0)),
    ));
  }, skip: isBrowser);

  testWidgets('Can be constructed with filter callback', (WidgetTester tester) async {
    const Widget child = SizedBox(width: 100.0, height: 100.0);
    await tester.pumpWidget(const ImageFiltered(
      child: child,
      imageFilterCallback: createFilter,
    ));
  }, skip: isBrowser);

  testWidgets('Must include filter or callback', (WidgetTester tester) async {
    const Widget child = SizedBox(width: 100.0, height: 100.0);
    expect(() => ImageFiltered(child: child), throwsAssertionError);
  }, skip: isBrowser);

  testWidgets('Must not include both filter and callback', (WidgetTester tester) async {
    const Widget child = SizedBox(width: 100.0, height: 100.0);
    expect(() => ImageFiltered(
      child: child,
      imageFilter: createFilter(Offset.zero & const Size(100.0, 100.0)),
      imageFilterCallback: createFilter,
    ), throwsAssertionError);
  }, skip: isBrowser);

  testWidgets('Bounds rect includes offset', (WidgetTester tester) async {
    late Rect callbackBounds;
    ImageFilter recordFilterBounds(Rect bounds) {
      callbackBounds = bounds;
      return createFilter(bounds);
    }

    final Widget widget = Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400.0,
        height: 400.0,
        child: Center(
          child: ImageFiltered(
            imageFilterCallback: recordFilterBounds,
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);

    // The filter bounds rectangle should reflect the position of the centered SizedBox.
    expect(callbackBounds.center, equals(const Offset(200.0, 200.0)));
    expect(callbackBounds.size, equals(const Size(100.0, 100.0)));
  }, skip: isBrowser);
}
