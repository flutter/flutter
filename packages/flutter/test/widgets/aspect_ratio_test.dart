// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

Future<Size> _getSize(WidgetTester tester, BoxConstraints constraints, double aspectRatio) async {
  final Key childKey = UniqueKey();
  await tester.pumpWidget(
    Center(
      child: ConstrainedBox(
        constraints: constraints,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            key: childKey,
          ),
        ),
      ),
    ),
  );
  final RenderBox box = tester.renderObject(find.byKey(childKey));
  return box.size;
}

void main() {
  testWidgetsWithLeakTracking('Aspect ratio control test', (WidgetTester tester) async {
    expect(await _getSize(tester, BoxConstraints.loose(const Size(500.0, 500.0)), 2.0), equals(const Size(500.0, 250.0)));
    expect(await _getSize(tester, BoxConstraints.loose(const Size(500.0, 500.0)), 0.5), equals(const Size(250.0, 500.0)));
  });

  testWidgetsWithLeakTracking('Aspect ratio infinite width', (WidgetTester tester) async {
    final Key childKey = UniqueKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AspectRatio(
            aspectRatio: 2.0,
            child: Container(
              key: childKey,
            ),
          ),
        ),
      ),
    ));
    final RenderBox box = tester.renderObject(find.byKey(childKey));
    expect(box.size, equals(const Size(1200.0, 600.0)));
  });
}
