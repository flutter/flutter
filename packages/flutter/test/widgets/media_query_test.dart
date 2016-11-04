// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('MediaQuery has a default', (WidgetTester tester) async {
    Size size;

    await tester.pumpWidget(
      new Builder(
        builder: (BuildContext context) {
          size = MediaQuery.of(context).size;
          return new Container();
        }
      )
    );

    expect(size, equals(ui.window.physicalSize / ui.window.devicePixelRatio));
  });
}
