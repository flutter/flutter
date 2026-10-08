// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:font_asset/build_helpers.dart';
import 'package:hooks/hooks.dart';

void main(List<String> arguments) {
  build(arguments, (BuildInput input, BuildOutputBuilder output) async {
    final Uri flutterRoot = input.packageRoot.resolve('../../../');
    addFont(
      input,
      output,
      filePath: '../../../packages/flutter_tools/static/Ahem.ttf',
      name: 'fonts/Ahem.ttf',
      family: 'BBHBartle',
    );
    addFontFamily(
      input,
      output,
      family: 'RobotoMono',
      fonts: <({Uri filePath, int? weight})>[
        (
          filePath: flutterRoot.resolve(
            'bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
          ),
          weight: null,
        ),
        (
          filePath: flutterRoot.resolve(
            'bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
          ),
          weight: 700,
        ),
      ],
    );
    addMaterialFont(input, output);
  });
}
