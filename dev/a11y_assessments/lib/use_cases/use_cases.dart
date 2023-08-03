// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'check_box_list_tile.dart';
import 'check_box_list_tile_disabled.dart';

abstract class UseCase {
  String get name;
  String get route;
  Widget build(BuildContext context);
}

final List<UseCase> useCases = <UseCase>[
  CheckBoxListTile(),
  CheckBoxListTileDisabled(),
];
