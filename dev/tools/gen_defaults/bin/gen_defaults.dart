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

Future<void> main(List<String> args) async {
  const String tokensDB = 'dev/tools/gen_defaults/data/material-tokens.json';
  final Map<String, dynamic> tokens = jsonDecode(File(tokensDB).readAsStringSync()) as Map<String, dynamic>;

  const String materialLib = 'packages/flutter/lib/src/material';

  FABTemplate('$materialLib/floating_action_button.dart', tokens).updateFile();
}
