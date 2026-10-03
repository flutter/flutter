// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flavors/main.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flavor Test', () {
    testWidgets('loads the selected configuration through Dart and native asset APIs', (
      WidgetTester tester,
    ) async {
      const key = 'assets/branch-config.json';
      final String dartConfig = await rootBundle.loadString(key);
      expect(jsonDecode(dartConfig), <String, Object?>{'flavor': appFlavor});
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      expect(manifest.listAssets(), contains(key));
      expect(manifest.listAssets(), isNot(contains('configs/$appFlavor/branch-config.json')));
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final String? nativeConfig = await const MethodChannel(
          'flavor',
        ).invokeMethod<String>('loadBranchConfig');
        expect(nativeConfig, dartConfig);
      }
    });

    testWidgets('check flavor', (WidgetTester tester) async {
      app.runMainApp();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(find.text('paid'), findsOneWidget);
      expect(appFlavor, 'paid');
    });
  });
}
