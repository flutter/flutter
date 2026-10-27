// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:data_asset_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Data Asset Demo smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Data Asset Demo'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.textContaining('FOUND "packages/data_asset_app/data/id1.txt": "content1"'),
      findsOneWidget,
    );
    expect(find.textContaining('package_content1'), findsOneWidget);
  });
}
