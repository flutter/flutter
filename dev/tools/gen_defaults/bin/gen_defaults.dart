// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Generate component theme data defaults based on the Material
// Design Token database. These tokens were extracted into a
// JSON file from the internal Google database.
//
// ## Usage
//
// Run this program from the root of the git repository.
//
// ```
// dart dev/tools/gen_defaults/bin/gen_defaults.dart
// ```

import 'dart:convert';
import 'dart:io';

import 'package:gen_defaults/fab_template.dart';
import 'package:gen_defaults/typography_template.dart';

Map<String, dynamic> _readTokenFile(String fileName) {
  return jsonDecode(File('dev/tools/gen_defaults/data/$fileName').readAsStringSync()) as Map<String, dynamic>;
}

Future<void> main(List<String> args) async {
  const String materialLib = 'packages/flutter/lib/src/material';
  const List<String> tokenFiles = <String>[
    'assist_chip.json',
    'banner.json',
    'color_dark.json',
    'color_light.json',
    'dialog.json',
    'elevation.json',
    'fab_extended_primary.json',
    'fab_extended_secondary.json',
    'fab_extended_surface.json',
    'fab_large_primary.json',
    'fab_large_secondary.json',
    'fab_large_surface.json',
    'fab_primary.json',
    'fab_secondary.json',
    'fab_small_primary.json',
    'fab_small_secondary.json',
    'fab_small_surface.json',
    'fab_surface.json',
    'filter_chip.json',
    'input_chip.json',
    'motion.json',
    'navigation_bar.json',
    'palette.json',
    'shape.json',
    'slider.json',
    'state.json',
    'suggestion_chip.json',
    'text_style.json',
    'top_app_bar_large.json',
    'top_app_bar_medium.json',
    'top_app_bar_small.json',
    'typeface.json',
  ];

  final Map<String, dynamic> tokens = <String, dynamic>{};
  // Special case the light and dark color schemes.
  tokens['colorsLight'] = _readTokenFile('color_light.json');
  tokens['colorsDark'] = _readTokenFile('color_dark.json');

  for (final String tokenFile in tokenFiles) {
    tokens.addAll(_readTokenFile(tokenFile));
  }

  FABTemplate('$materialLib/floating_action_button.dart', tokens).updateFile();
  TypographyTemplate('$materialLib/typography.dart', tokens).updateFile();
}
