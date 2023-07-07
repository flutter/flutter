// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test snackbar', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(const CameraApp());
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
