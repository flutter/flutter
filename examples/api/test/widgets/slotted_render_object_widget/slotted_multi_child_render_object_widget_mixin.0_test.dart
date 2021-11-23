// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/slotted_render_object_widget/slotted_multi_child_render_object_widget_mixin.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows two widgets arranged diagonally', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ExampleWidget(),
    );

    expect(find.text('topLeft'), findsOneWidget);
    expect(find.text('bottomRight'), findsOneWidget);

    expect(
      tester.getBottomRight(find.text('topLeft')),
      tester.getTopLeft(find.text('bottomRight')),
    );
  });
}
