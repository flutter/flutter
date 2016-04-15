// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {

  // The "can be constructed" tests that follow are primarily to ensure that any
  // animations started by the progress indicators are stopped at dispose() time.

  test('LinearProgressIndicator(value: 0.0) can be constructed', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Center(
          child: new SizedBox(
            width: 200.0,
            child: new LinearProgressIndicator(value: 0.0)
          )
        )
      );
    });
  });

  test('LinearProgressIndicator(value: null) can be constructed', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Center(
          child: new SizedBox(
            width: 200.0,
            child: new LinearProgressIndicator(value: null)
          )
        )
      );
    });
  });

  test('CircularProgressIndicator(value: 0.0) can be constructed', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Center(
          child: new CircularProgressIndicator(value: 0.0)
        )
      );
    });
  });

  test('CircularProgressIndicator(value: null) can be constructed', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Center(
          child: new CircularProgressIndicator(value: null)
        )
      );
    });
  });

  test('LinearProgressIndicator changes when its value changes', () {
    testElementTree((ElementTreeTester tester) {
      tester.pumpWidget(new Block(children: <Widget>[new LinearProgressIndicator(value: 0.0)]));
      List<Layer> layers1 = tester.layers;
      tester.pumpWidget(new Block(children: <Widget>[new LinearProgressIndicator(value: 0.5)]));
      List<Layer> layers2 = tester.layers;
      expect(layers1, isNot(equals(layers2)));
    });
  });
}
