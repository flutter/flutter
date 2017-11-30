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

  testWidgets('MediaQueryData.copyWith defaults to source', (WidgetTester tester) async {
    final MediaQueryData data = new MediaQueryData.fromWindow(ui.window);
    final MediaQueryData copied = data.copyWith();
    expect(copied.size, data.size);
    expect(copied.devicePixelRatio, data.devicePixelRatio);
    expect(copied.textScaleFactor, data.textScaleFactor);
    expect(copied.padding, data.padding);
    expect(copied.viewInsets, data.viewInsets);
  });

  testWidgets('MediaQuery.copyWith copies specified values', (WidgetTester tester) async {
    final MediaQueryData data = new MediaQueryData.fromWindow(ui.window);
    final MediaQueryData copied = data.copyWith(
      size: const Size(3.14, 2.72),
      devicePixelRatio: 1.41,
      textScaleFactor: 1.62,
      padding: const EdgeInsets.all(9.10938),
      viewInsets: const EdgeInsets.all(1.67262),
    );
    expect(copied.size, const Size(3.14, 2.72));
    expect(copied.devicePixelRatio, 1.41);
    expect(copied.textScaleFactor, 1.62);
    expect(copied.padding, const EdgeInsets.all(9.10938));
    expect(copied.viewInsets, const EdgeInsets.all(1.67262));
  });
}
