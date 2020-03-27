// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/image_loading_main.dart' as app;

import 'package:e2e/e2e.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized() as E2EWidgetsFlutterBinding;

  testWidgets('Image loads asset variant based on device pixel ratio',
          (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    final html.ImageElement imageElement = html.querySelector('img') as html.ImageElement;
    expect(imageElement.naturalWidth, 1.5 * 100);
    expect(imageElement.naturalHeight, 1.5 * 100);
    expect(imageElement.width, 100);
    expect(imageElement.height, 100);
  });
}
