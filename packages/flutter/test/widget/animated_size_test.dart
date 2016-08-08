// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('AnimatedSize test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: new SizedBox(
            width: 100.0,
            height: 100.0
          )
        )
      )
    );

    RenderBox box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));

    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: new Duration(milliseconds: 200),
          child: new SizedBox(
            width: 200.0,
            height: 200.0
          )
        )
      )
    );

    await tester.pump(); // _state is changed
    await tester.pump(); // constraint propagates to AnimatedController
    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, greaterThan(100.0));
    expect(box.size.height, greaterThan(100.0));
    expect(box.size.width, lessThan(200.0));
    expect(box.size.height, lessThan(200.0));

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(200.0));
    expect(box.size.height, equals(200.0));

    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: new Duration(milliseconds: 200),
          child: new SizedBox(
            width: 100.0,
            height: 100.0
          )
        )
      )
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, greaterThan(100.0));
    expect(box.size.height, greaterThan(100.0));
    expect(box.size.width, lessThan(200.0));
    expect(box.size.height, lessThan(200.0));

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));
  });
}
