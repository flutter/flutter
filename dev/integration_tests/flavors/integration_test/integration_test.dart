// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flavors/main.dart' as app;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class FlavorTestWidgetsFlutterBinding extends IntegrationTestWidgetsFlutterBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
  }
  static FlavorTestWidgetsFlutterBinding? _instance;
  static FlavorTestWidgetsFlutterBinding ensureInitialized() {
    if (_instance == null) {
      FlavorTestWidgetsFlutterBinding();
    }
    return _instance!;
  }

  @override
  void attachRootWidget(Widget rootWidget) {
    stderr.writeln('[DEBUG] Attaching root widget...');
    super.attachRootWidget(rootWidget);
  }

  @override
  void dispatchEvent(PointerEvent event, HitTestResult? result) {
    stderr.writeln('[DEBUG] New pointer event: $event');
    super.dispatchEvent(event, result);
  }
}

void main() {
  FlavorTestWidgetsFlutterBinding.ensureInitialized();

  group('Flavor Test', () {
    testWidgets('check flavor', (WidgetTester tester) async {
      app.runMainApp();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(find.text('paid'), findsOneWidget);
    });
  });
}
