// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  test('LinearProgressIndicator changes when its value changes', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Block(<Widget>[new LinearProgressIndicator(value: 0.0)]));

      List<Layer> layers1 = tester.layers;

      tester.pumpWidget(new Block(<Widget>[new LinearProgressIndicator(value: 0.5)]));

      List<Layer> layers2 = tester.layers;
      expect(layers1, isNot(equals(layers2)));
    });
  });
}
