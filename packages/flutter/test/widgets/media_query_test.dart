// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('MediaQuery does not have a default', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      new Builder(
        builder: (BuildContext context) {
          tested = true;
          MediaQuery.of(context); // should throw
          return new Container();
        }
      )
    );
    expect(tested, isTrue);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('MediaQuery defaults to null', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      new Builder(
        builder: (BuildContext context) {
          final MediaQueryData data = MediaQuery.of(context, nullOk: true);
          expect(data, isNull);
          tested = true;
          return new Container();
        }
      )
    );
    expect(tested, isTrue);
  });

  testWidgets('MediaQueryData is sane', (WidgetTester tester) async {
    final MediaQueryData data = new MediaQueryData.fromWindow(ui.window);
    expect(data, hasOneLineDescription);
    expect(data.hashCode, equals(data.copyWith().hashCode));
    expect(data.size, equals(ui.window.physicalSize / ui.window.devicePixelRatio));
  });
}
