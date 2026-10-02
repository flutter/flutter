// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/text/text.selection_height_style.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selection height style example builds', (
    WidgetTester tester,
  ) async {
    example.main();
    await tester.pump();

    expect(
      find.text(
        'Select this text. The line height is larger than the glyph height.',
      ),
      findsOneWidget,
    );
  });
}
