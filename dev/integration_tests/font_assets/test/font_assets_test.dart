// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_asset_package/font_asset_package.dart';
import 'package:font_assets/main.dart';
import 'package:font_assets/src/font_data.dart';

void main() {
  testWidgets('fonts from build hooks are bundled with the app', (WidgetTester tester) async {
    await tester.pumpWidget(const FontAssetsApp());
    expect(find.text('hook'), findsNWidgets(2));
    expect(find.byIcon(HookIcons.add), findsOneWidget);

    final fontManifest =
        json.decode(await rootBundle.loadString('FontManifest.json')) as List<Object?>;
    Map<String, Object?> familyEntry(String family) => fontManifest
        .cast<Map<String, Object?>>()
        .singleWhere((Map<String, Object?> entry) => entry['family'] == family);

    // The family from the app's own hook is listed with all its weights, next
    // to the material fonts.
    expect(familyEntry(kHookFontFamily)['fonts'], <Object?>[
      <String, Object?>{'asset': 'packages/font_assets/fonts/Roboto-Regular.ttf'},
      <String, Object?>{'asset': 'packages/font_assets/fonts/Roboto-Bold.ttf', 'weight': 700},
    ]);
    expect(familyEntry('MaterialIcons'), isNotNull);

    // The icon font from the dependency's hook is namespaced by package, which
    // is what `IconData.fontPackage` resolves to.
    expect(familyEntry('packages/font_asset_package/HookIcons')['fonts'], <Object?>[
      <String, Object?>{'asset': 'packages/font_asset_package/fonts/HookIcons.otf'},
    ]);

    // The font files that the hooks generated are part of the asset bundle.
    for (final MapEntry<String, String> entry in <String, String>{
      'packages/font_assets/fonts/Roboto-Regular.ttf': kRobotoRegularFontBase64,
      'packages/font_assets/fonts/Roboto-Bold.ttf': kRobotoBoldFontBase64,
      'packages/font_asset_package/fonts/HookIcons.otf': kHookIconsFontBase64,
    }.entries) {
      final ByteData font = await rootBundle.load(entry.key);
      expect(
        font.buffer.asUint8List(font.offsetInBytes, font.lengthInBytes),
        base64Decode(entry.value),
        reason: entry.key,
      );
    }
  });
}
