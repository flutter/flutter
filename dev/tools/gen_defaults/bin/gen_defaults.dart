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

import 'package:gen_defaults/app_bar_template.dart';
import 'package:gen_defaults/button_template.dart';
import 'package:gen_defaults/card_template.dart';
import 'package:gen_defaults/dialog_template.dart';
import 'package:gen_defaults/fab_template.dart';
import 'package:gen_defaults/navigation_bar_template.dart';
import 'package:gen_defaults/navigation_rail_template.dart';
import 'package:gen_defaults/surface_tint.dart';
import 'package:gen_defaults/typography_template.dart';

Map<String, dynamic> _readTokenFile(String fileName) {
  return jsonDecode(File('dev/tools/gen_defaults/data/$fileName').readAsStringSync()) as Map<String, dynamic>;
}

Future<void> main(List<String> args) async {
  const String materialLib = 'packages/flutter/lib/src/material';
  const List<String> tokenFiles = <String>[
    'banner.json',
    'button_elevated.json',
    'button_filled.json',
    'button_filled_tonal.json',
    'button_outlined.json',
    'button_text.json',
    'card_elevated.json',
    'card_filled.json',
    'card_outlined.json',
    'chip_assist.json',
    'chip_filter.json',
    'chip_input.json',
    'chip_suggestion.json',
    'color_dark.json',
    'color_light.json',
    'dialog.json',
    'elevation.json',
    'fab_extended_primary.json',
    'fab_large_primary.json',
    'fab_primary.json',
    'fab_small_primary.json',
    'motion.json',
    'navigation_bar.json',
    'navigation_rail.json',
    'palette.json',
    'shape.json',
    'slider.json',
    'state.json',
    'text_style.json',
    'top_app_bar_large.json',
    'top_app_bar_medium.json',
    'top_app_bar_small.json',
    'typeface.json',
  ];

  // Generate a map with all the tokens to simplify the template interface.
  final Map<String, dynamic> tokens = <String, dynamic>{};
  for (final String tokenFile in tokenFiles) {
    tokens.addAll(_readTokenFile(tokenFile));
  }

  // Special case the light and dark color schemes.
  tokens['colorsLight'] = _readTokenFile('color_light.json');
  tokens['colorsDark'] = _readTokenFile('color_dark.json');

  AppBarTemplate('$materialLib/app_bar.dart', tokens).updateFile();
  ButtonTemplate('md.comp.elevated-button', '$materialLib/elevated_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.outlined-button', '$materialLib/outlined_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.text-button', '$materialLib/text_button.dart', tokens).updateFile();
  CardTemplate('$materialLib/card.dart', tokens).updateFile();
  DialogTemplate('$materialLib/dialog.dart', tokens).updateFile();
  FABTemplate('$materialLib/floating_action_button.dart', tokens).updateFile();
  NavigationBarTemplate('$materialLib/navigation_bar.dart', tokens).updateFile();
  NavigationRailTemplate('$materialLib/navigation_rail.dart', tokens).updateFile();
  SurfaceTintTemplate('$materialLib/elevation_overlay.dart', tokens).updateFile();
  TypographyTemplate('$materialLib/typography.dart', tokens).updateFile();
}
