// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

export 'src/font_data.dart' show kHookIconsFontBase64;

/// Icons from the `HookIcons` font family that `hook/build.dart` provides.
///
/// As with any icon font from a package, [IconData.fontPackage] namespaces
/// the family (`packages/font_asset_package/HookIcons` in `FontManifest.json`).
abstract final class HookIcons {
  /// The "add" glyph of the font.
  static const IconData add = IconData(
    0xe047,
    fontFamily: 'HookIcons',
    fontPackage: 'font_asset_package',
  );
}
