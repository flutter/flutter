// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'chip_template.dart';

const String materialLib = 'packages/flutter/lib/src/material';

Future<void> main(List<String> args) async {
  final Map<String, dynamic> tokens = <String, dynamic>{};
  ChipTemplate('Chip', '$materialLib/chip.dart', tokens).updateFile();
}
