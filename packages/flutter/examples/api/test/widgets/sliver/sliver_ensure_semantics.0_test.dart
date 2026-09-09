// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/sliver/sliver_ensure_semantics.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverEnsureSemantics example', (WidgetTester tester) async {
    await tester.pumpWidget(const example.SliverEnsureSemanticsExampleApp());

    expect(find.text('SliverEnsureSemantics Demo'), findsOneWidget);
  });
}
