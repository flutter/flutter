// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Circles can have uniform borders', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Container(
          padding: new EdgeDims.all(50.0),
          decoration: new BoxDecoration(
            shape: Shape.circle,
            border: new Border.all(width: 10.0, color: const Color(0x80FF00FF)),
            backgroundColor: Colors.teal[600]
          )
        )
      );
    });
  });
}
