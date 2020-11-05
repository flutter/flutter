// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/image_loading_main.dart' as app;

import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Image loads asset variant based on device pixel ratio',
          (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    final List<html.ImageElement> imageElements = html.querySelectorAll('img');
    expect(imageElements.length, 2);
    expect(imageElements[0].naturalWidth, 1.5 * 100);
    expect(imageElements[0].naturalHeight, 1.5 * 100);
    expect(imageElements[0].width, 100);
    expect(imageElements[0].height, 100);
    expect(imageElements[1].width, isNot(0));
  });
}
