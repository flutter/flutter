// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/input_decorator/input_decoration.prefix_icon.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InputDecorator prefixIcon alignment', (WidgetTester tester) async {
    await tester.pumpWidget(const example.PrefixIconExampleApp());
    expect(tester.getCenter(find.byIcon(Icons.person)).dy, 28.0);
  });
}
