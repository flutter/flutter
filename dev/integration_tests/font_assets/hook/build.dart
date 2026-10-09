// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:font_asset/font_asset.dart';
import 'package:font_assets/src/font_data.dart';
import 'package:hooks/hooks.dart';

/// Provides the `RobotoFromHook` font family (regular and bold) to the app.
///
/// The font files are generated into the hook's output directory from the data
/// in `lib/src/font_data.dart`, because this repository does not contain
/// binary files. A package that ships its font files would instead call
/// `addFontFamily` with paths relative to the package root.
void main(List<String> arguments) async {
  await build(arguments, (BuildInput input, BuildOutputBuilder output) async {
    if (!input.config.buildAssetTypes.contains(fontAssetType)) {
      return;
    }
    for (final (String fileName, String base64, int? weight) in <(String, String, int?)>[
      ('Roboto-Regular.ttf', kRobotoRegularFontBase64, null),
      ('Roboto-Bold.ttf', kRobotoBoldFontBase64, 700),
    ]) {
      final Uri fontFile = input.outputDirectory.resolve(fileName);
      File.fromUri(fontFile)
        ..createSync(recursive: true)
        ..writeAsBytesSync(base64Decode(base64));
      output.assets.fonts.add(
        FontAsset(
          package: input.packageName,
          name: 'fonts/$fileName',
          family: 'RobotoFromHook',
          file: fontFile,
          weight: weight,
        ),
      );
    }
  });
}
