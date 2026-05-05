// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenSheetBottom {
  /// md.comp.sheet.bottom.docked.drag-handle.width
  static const double dockedDragHandleWidth = 32.00;

  /// md.comp.sheet.bottom.focus.indicator.outline.offset
  static const double focusIndicatorOutlineOffset = 2.00;

  /// md.comp.sheet.bottom.docked.drag-handle.height
  static const double dockedDragHandleHeight = 4.00;

  /// md.comp.sheet.bottom.docked.container.color
  static const TokenColorRole dockedContainerColor =
      TokenColorRole.surfaceContainerLow;

  /// md.comp.sheet.bottom.docked.drag-handle.color
  static const TokenColorRole dockedDragHandleColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.sheet.bottom.docked.container.shape
  static const ShapeStruct dockedContainerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 28.00,
    topRight: 28.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.sheet.bottom.docked.standard.container.elevation
  static const double dockedStandardContainerElevation = 1.00;

  /// md.comp.sheet.bottom.focus.indicator.color
  static const TokenColorRole focusIndicatorColor = TokenColorRole.secondary;

  /// md.comp.sheet.bottom.docked.minimized.container.shape
  static const ShapeStruct dockedMinimizedContainerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.sheet.bottom.focus.indicator.thickness
  static const double focusIndicatorThickness = 3.00;

  /// md.comp.sheet.bottom.docked.modal.container.elevation
  static const double dockedModalContainerElevation = 1.00;
}
