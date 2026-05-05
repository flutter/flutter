// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenLoadingIndicator {
  /// md.comp.loading-indicator.contained.active-indicator.color
  static const TokenColorRole containedActiveIndicatorColor =
      TokenColorRole.onPrimaryContainer;

  /// md.comp.loading-indicator.container.height
  static const double containerHeight = 48.00;

  /// md.comp.loading-indicator.container.width
  static const double containerWidth = 48.00;

  /// md.comp.loading-indicator.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.loading-indicator.active-indicator.size
  static const double activeIndicatorSize = 38.00;

  /// md.comp.loading-indicator.active-indicator.color
  static const TokenColorRole activeIndicatorColor = TokenColorRole.primary;

  /// md.comp.loading-indicator.contained.container.color
  static const TokenColorRole containedContainerColor =
      TokenColorRole.primaryContainer;
}
