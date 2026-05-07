// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// ## Usage
//
// Run this program from the root of the git repository.
//
// ```
// dart packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart
// ```

import 'dart:io';

import '../templates/color_scheme_template.dart';
import '../templates/icon_button_template.dart';

// The path to the material library in the flutter package.
const String materialLib = 'packages/flutter/lib/src/material';

void main() {
  stdout.writeln('Updating ColorScheme defaults...');
  const ColorSchemeTemplate('ColorScheme', '$materialLib/theme_data.dart').updateFile();

  stdout.writeln('Updating IconButton defaults...');
  const IconButtonTemplate(
    'IconButton',
    '$materialLib/material_3_expressive/icon_button.dart',
  ).updateFile();
  stdout.writeln('Done!');
}
