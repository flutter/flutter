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
import 'package:gen_defaults/chip_action_template.dart';
import 'package:gen_defaults/chip_filter_template.dart';
import 'package:gen_defaults/chip_input_template.dart';
import 'package:gen_defaults/dialog_template.dart';
import 'package:gen_defaults/fab_template.dart';
import 'package:gen_defaults/icon_button_template.dart';
import 'package:gen_defaults/input_decorator_template.dart';
import 'package:gen_defaults/navigation_bar_template.dart';
import 'package:gen_defaults/navigation_rail_template.dart';
import 'package:gen_defaults/surface_tint.dart';
import 'package:gen_defaults/text_field_template.dart';
import 'package:gen_defaults/typography_template.dart';

Map<String, dynamic> _readTokenFile(String fileName) {
  return jsonDecode(File('dev/tools/gen_defaults/data/$fileName').readAsStringSync()) as Map<String, dynamic>;
}

Future<void> main(List<String> args) async {
  const String materialLib = 'packages/flutter/lib/src/material';
  const List<String> tokenFiles = <String>[
    'banner.json',
    'bottom_app_bar.json',
    'button_elevated.json',
    'button_filled.json',
    'button_filled_tonal.json',
    'button_outlined.json',
    'button_text.json',
    'card_elevated.json',
    'card_filled.json',
    'card_outlined.json',
    'checkbox.json',
    'chip_assist.json',
    'chip_filter.json',
    'chip_input.json',
    'chip_suggestion.json',
    'color_dark.json',
    'color_light.json',
    'date_picker_docked.json',
    'date_picker_modal.json',
    'dialog.json',
    'dialog_fullscreen.json',
    'elevation.json',
    'fab_extended_primary.json',
    'fab_large_primary.json',
    'fab_primary.json',
    'fab_small_primary.json',
    'icon_button.json',
    'icon_button_filled.json',
    'icon_button_filled_tonal.json',
    'icon_button_outlined.json',
    'menu.json',
    'motion.json',
    'navigation_bar.json',
    'navigation_drawer.json',
    'navigation_rail.json',
    'palette.json',
    'segmented_button_outlined.json',
    'shape.json',
    'slider.json',
    'state.json',
    'switch.json',
    'text_field_filled.json',
    'text_field_outlined.json',
    'text_style.json',
    'time_picker.json',
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

  AppBarTemplate('AppBar', '$materialLib/app_bar.dart', tokens).updateFile();
  ButtonTemplate('md.comp.elevated-button', 'ElevatedButton', '$materialLib/elevated_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.filled-button', 'FilledButton', '$materialLib/filled_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.filled-tonal-button', 'FilledTonalButton', '$materialLib/filled_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.outlined-button', 'OutlinedButton', '$materialLib/outlined_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.text-button', 'TextButton', '$materialLib/text_button.dart', tokens).updateFile();
  CardTemplate('Card', '$materialLib/card.dart', tokens).updateFile();
  ChipActionTemplate('ActionChip', '$materialLib/chip_action.dart', tokens).updateFile();
  ChipFilterTemplate('FilterChip', '$materialLib/chip_filter.dart', tokens).updateFile();
  ChipFilterTemplate('FilterChip', '$materialLib/chip_choice.dart', tokens).updateFile();
  ChipInputTemplate('InputChip', '$materialLib/chip_input.dart', tokens).updateFile();
  DialogTemplate('Dialog', '$materialLib/dialog.dart', tokens).updateFile();
  FABTemplate('FAB', '$materialLib/floating_action_button.dart', tokens).updateFile();
  IconButtonTemplate('IconButton', '$materialLib/icon_button.dart', tokens).updateFile();
  InputDecoratorTemplate('InputDecorator', '$materialLib/input_decorator.dart', tokens).updateFile();
  NavigationBarTemplate('NavigationBar', '$materialLib/navigation_bar.dart', tokens).updateFile();
  NavigationRailTemplate('NavigationRail', '$materialLib/navigation_rail.dart', tokens).updateFile();
  SurfaceTintTemplate('SurfaceTint', '$materialLib/elevation_overlay.dart', tokens).updateFile();
  TextFieldTemplate('TextField', '$materialLib/text_field.dart', tokens).updateFile();
  TypographyTemplate('Typography', '$materialLib/typography.dart', tokens).updateFile();
}
