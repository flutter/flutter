// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.9

import 'color_role.dart';
import 'shape_struct.dart';

class TokenAppBar {
  /// md.comp.app-bar.search.on-scroll.container.color
  static const TokenColorRole searchOnScrollContainerColor =
      TokenColorRole.surfaceContainerHighest;

  /// md.comp.app-bar.container.color
  static const TokenColorRole containerColor = TokenColorRole.surface;

  /// md.comp.app-bar.icon-button-space
  static const double iconButtonSpace = 0.00;

  /// md.comp.app-bar.on-scroll.container.elevation
  static const double onScrollContainerElevation = 3.00;

  /// md.comp.app-bar.trailing-space
  static const double trailingSpace = 4.00;

  /// md.comp.app-bar.search.label.color
  static const TokenColorRole searchLabelColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.app-bar.subtitle.color
  static const TokenColorRole subtitleColor = TokenColorRole.onSurfaceVariant;

  /// md.comp.app-bar.search.trailing-space
  static const double searchTrailingSpace = 8.00;

  /// md.comp.app-bar.icon.size
  static const double iconSize = 24.00;

  /// md.comp.app-bar.trailing-icon.color
  static const TokenColorRole trailingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.app-bar.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.app-bar.leading-space
  static const double leadingSpace = 4.00;

  /// md.comp.app-bar.search.container.color
  static const TokenColorRole searchContainerColor =
      TokenColorRole.surfaceContainer;

  /// md.comp.app-bar.leading-icon.color
  static const TokenColorRole leadingIconColor = TokenColorRole.onSurface;

  /// md.comp.app-bar.container.elevation
  static const double containerElevation = 0.00;

  /// md.comp.app-bar.on-scroll.container.color
  static const TokenColorRole onScrollContainerColor =
      TokenColorRole.surfaceContainer;

  /// md.comp.app-bar.title.color
  static const TokenColorRole titleColor = TokenColorRole.onSurface;

  /// md.comp.app-bar.search.leading-space
  static const double searchLeadingSpace = 8.00;

  /// md.comp.app-bar.avatar.size
  static const double avatarSize = 32.00;
}
