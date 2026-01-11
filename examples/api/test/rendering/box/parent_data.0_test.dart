// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/rendering/box/parent_data.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('parent data example', (WidgetTester tester) async {
    await tester.pumpWidget(const SampleApp());
    expect(
      tester.getTopLeft(find.byType(Headline).at(2)),
      const Offset(30.0, 728.0),
    );
    await tester.tap(find.byIcon(Icons.density_small));
    await tester.pump();
    expect(
      tester.getTopLeft(find.byType(Headline).at(2)),
      const Offset(30.0, 682.0),
    );
  });
}
