// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:conductor_ui/main.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Main app', () {
    testWidgets('Scaffold Initialization', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(null));

      expect(find.textContaining('Flutter Desktop Conductor'), findsOneWidget);
      expect(find.textContaining('Desktop app for managing a release'), findsOneWidget);
    });
  }, skip: Platform.isWindows); // This app does not support Windows [intended]
}
