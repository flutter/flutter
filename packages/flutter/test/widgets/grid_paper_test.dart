// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GridPaper control test', (WidgetTester tester) async {
    await tester.pumpWidget(const GridPaper());
    final List<Layer> layers1 = tester.layers;
    await tester.pumpWidget(const GridPaper());
    final List<Layer> layers2 = tester.layers;
    expect(layers1, equals(layers2));
  });

  testWidgets('GridPaper does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox.shrink(child: GridPaper())),
      ),
    );
    expect(tester.getSize(find.byType(GridPaper)), Size.zero);
  });
}
