// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_assets/main.dart';

void main() {
  testWidgets('fonts from the build hook are bundled with the app', (WidgetTester tester) async {
    await tester.pumpWidget(const FontAssetsApp());
    expect(find.text('Regular from hook'), findsOneWidget);
    expect(find.text('Bold from hook'), findsOneWidget);

    // The hook font family is registered in the font manifest next to the
    // material fonts, with all its weights.
    final fontManifest =
        json.decode(await rootBundle.loadString('FontManifest.json')) as List<Object?>;
    final Map<String, Object?> hookFamily = fontManifest.cast<Map<String, Object?>>().singleWhere(
      (Map<String, Object?> family) => family['family'] == kHookFontFamily,
    );
    expect(hookFamily['fonts'], <Object?>[
      <String, Object?>{'asset': 'packages/font_assets/fonts/Roboto-Regular.ttf'},
      <String, Object?>{'asset': 'packages/font_assets/fonts/Roboto-Bold.ttf', 'weight': 700},
    ]);
    expect(
      fontManifest.cast<Map<String, Object?>>().map((Map<String, Object?> f) => f['family']),
      contains('MaterialIcons'),
    );

    // The font files themselves are part of the asset bundle.
    for (final asset in <String>[
      'packages/font_assets/fonts/Roboto-Regular.ttf',
      'packages/font_assets/fonts/Roboto-Bold.ttf',
    ]) {
      final ByteData font = await rootBundle.load(asset);
      expect(font.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
