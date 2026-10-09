// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:font_asset/font_asset.dart';
import 'package:hooks/hooks.dart';

/// Provides the `HookIcons` icon font family, the way an icon font package
/// like `cupertino_icons` could.
///
/// A published package would ship the font file in the package itself. This
/// repository does not contain binaries, so the file is taken from the Flutter
/// SDK cache (it is the Material icons font under a different family name).
void main(List<String> arguments) async {
  await build(arguments, (BuildInput input, BuildOutputBuilder output) async {
    addFont(
      input,
      output,
      family: 'HookIcons',
      filePath: '../../../bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      name: 'fonts/HookIcons.otf',
    );
  });
}
