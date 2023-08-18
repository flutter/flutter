// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/transitions/matrix_transition.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows Flutter logo inside a MatrixTransition', (WidgetTester tester) async {
    await tester.pumpWidget(const example.MatrixTransitionExampleApp());

    expect(find.byType(MatrixTransition), findsOneWidget);
    expect(find.byType(FlutterLogo), findsOneWidget);
  });
}
