// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:font_asset/font_asset.dart';
import 'package:font_asset_package/src/font_data.dart';
import 'package:hooks/hooks.dart';

/// Provides the `HookIcons` icon font family, the way an icon font package
/// like `cupertino_icons` could.
///
/// The font file is generated into the hook's output directory from the data
/// in `lib/src/font_data.dart`, because this repository does not contain
/// binary files. A package that ships its font files would instead call
/// `addFont` with a path relative to the package root.
void main(List<String> arguments) async {
  await build(arguments, (BuildInput input, BuildOutputBuilder output) async {
    if (!input.config.buildAssetTypes.contains(fontAssetType)) {
      return;
    }
    final Uri fontFile = input.outputDirectory.resolve('HookIcons.otf');
    File.fromUri(fontFile)
      ..createSync(recursive: true)
      ..writeAsBytesSync(base64Decode(kHookIconsFontBase64));
    output.assets.fonts.add(
      FontAsset(
        package: input.packageName,
        name: 'fonts/HookIcons.otf',
        family: 'HookIcons',
        file: fontFile,
      ),
    );
  });
}
