// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<Size> _getSize(WidgetTester tester, BoxConstraints constraints, double aspectRatio) async {
  final Key childKey = new UniqueKey();
  await tester.pumpWidget(
    new Center(
      child: new ConstrainedBox(
        constraints: constraints,
        child: new AspectRatio(
          aspectRatio: aspectRatio,
          child: new Container(
            key: childKey
          )
        )
      )
    )
  );
  final RenderBox box = tester.renderObject(find.byKey(childKey));
  return box.size;
}

void main() {
  testWidgets('Aspect ratio control test', (WidgetTester tester) async {
    expect(await _getSize(tester, new BoxConstraints.loose(const Size(500.0, 500.0)), 2.0), equals(const Size(500.0, 250.0)));
    expect(await _getSize(tester, new BoxConstraints.loose(const Size(500.0, 500.0)), 0.5), equals(const Size(250.0, 500.0)));
  });

  testWidgets('Aspect ratio infinite width', (WidgetTester tester) async {
    final Key childKey = new UniqueKey();
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Center(
        child: new SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: new AspectRatio(
            aspectRatio: 2.0,
            child: new Container(
              key: childKey
            )
          )
        )
      )
    ));
    final RenderBox box = tester.renderObject(find.byKey(childKey));
    expect(box.size, equals(const Size(1200.0, 600.0)));
  });
}
