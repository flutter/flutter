// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('BoxConstraintsTween control test', (WidgetTester tester) async {
    BoxConstraintsTween tween = new BoxConstraintsTween(
      begin: new BoxConstraints.tight(const Size(20.0, 50.0)),
      end: new BoxConstraints.tight(const Size(10.0, 30.0))
    );
    BoxConstraints result = tween.lerp(0.25);
    expect(result.minWidth, 17.5);
    expect(result.maxWidth, 17.5);
    expect(result.minHeight, 45.0);
    expect(result.maxHeight, 45.0);
  });

  testWidgets('DecorationTween control test', (WidgetTester tester) async {
    DecorationTween tween = new DecorationTween(
      begin: const BoxDecoration(backgroundColor: const Color(0xFF00FF00)),
      end: const BoxDecoration(backgroundColor: const Color(0xFFFFFF00))
    );
    BoxDecoration result = tween.lerp(0.25);
    expect(result.backgroundColor, const Color(0xFF3FFF00));
  });

  testWidgets('EdgeInsetsTween control test', (WidgetTester tester) async {
    EdgeInsetsTween tween = new EdgeInsetsTween(
      begin: const EdgeInsets.symmetric(vertical: 50.0),
      end: const EdgeInsets.only(top: 10.0, bottom: 30.0)
    );
    EdgeInsets result = tween.lerp(0.25);
    expect(result.left, 0.0);
    expect(result.right, 0.0);
    expect(result.top, 40.0);
    expect(result.bottom, 45.0);
  });

  testWidgets('Matrix4Tween control test', (WidgetTester tester) async {
    Matrix4Tween tween = new Matrix4Tween(
      begin: new Matrix4.translationValues(10.0, 20.0, 30.0),
      end: new Matrix4.translationValues(14.0, 24.0, 34.0)
    );
    Matrix4 result = tween.lerp(0.25);
    expect(result, equals(new Matrix4.translationValues(11.0, 21.0, 31.0)));
  });
}
