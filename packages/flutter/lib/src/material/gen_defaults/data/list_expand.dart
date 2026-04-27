// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.9

import 'color_role.dart';
import 'shape_struct.dart';

class TokenListExpand {
  /// md.comp.list.expand.trailing-icon.shape
  static const ShapeStruct trailingIconShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.list.expand.collapsed.list-item.trailing-icon.icon.color
  static const TokenColorRole collapsedListItemTrailingIconIconColor =
      TokenColorRole.onSurface;

  /// md.comp.list.expand.expanded.list-item.trailing-icon.container.color
  static const TokenColorRole expandedListItemTrailingIconContainerColor =
      TokenColorRole.surfaceContainer;

  /// md.comp.list.expand.expanded.list-item.trailing-icon.icon.color
  static const TokenColorRole expandedListItemTrailingIconIconColor =
      TokenColorRole.onSurface;

  /// md.comp.list.expand.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 16.00,
    topRight: 16.00,
    bottomLeft: 16.00,
    bottomRight: 16.00,
  );

  /// md.comp.list.expand.expanded.list-item.segmented.container.color
  static const TokenColorRole expandedListItemSegmentedContainerColor =
      TokenColorRole.surface;

  /// md.comp.list.expand.expanded.list-item.container.color
  static const TokenColorRole expandedListItemContainerColor =
      TokenColorRole.surface;

  /// md.comp.list.expand.collapsed.list-item.trailing-icon.container.color
  static const TokenColorRole collapsedListItemTrailingIconContainerColor =
      TokenColorRole.surface;
}
