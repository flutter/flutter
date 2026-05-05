// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenSheetFloating {
  /// md.comp.sheet.floating.container.color
  static const TokenColorRole containerColor =
      TokenColorRole.surfaceContainerLow;

  /// md.comp.sheet.floating.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 28.00,
    topRight: 28.00,
    bottomLeft: 28.00,
    bottomRight: 28.00,
  );

  /// md.comp.sheet.floating.container.elevation
  static const double containerElevation = 1.00;
}
