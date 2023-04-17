// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gets local coordinates', (WidgetTester tester) async {
    const Key redContainer = Key('Hello');
    await tester.pumpWidget(Container(key: redContainer));
    expect(find.byKey(redContainer), findsOneWidget);
  });
}
