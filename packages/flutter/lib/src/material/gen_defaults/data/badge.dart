// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenBadge {
  /// md.comp.badge.large.size
  static const double largeSize = 16.00;

  /// md.comp.badge.large.label-text.font
  static const String largeLabelTextFont = 'Roboto';

  /// md.comp.badge.size
  static const double size = 6.00;

  /// md.comp.badge.large.label-text.color
  static const TokenColorRole largeLabelTextColor = TokenColorRole.onError;

  /// md.comp.badge.large.shape
  static const ShapeStruct largeShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.badge.large.label-text.type
  static const double largeLabelTextTypeFontSize = 11.00;

  /// md.comp.badge.large.label-text.type
  static const double largeLabelTextTypeFontWeight = 500;

  /// md.comp.badge.large.label-text.type
  static const double largeLabelTextTypeLineHeight = 16.00;

  /// md.comp.badge.large.label-text.type
  static const double largeLabelTextTypeLetterSpacing = 0.50;

  /// md.comp.badge.large.label-text.type
  static const String largeLabelTextTypeFontFamily = 'Roboto';

  /// md.comp.badge.color
  static const TokenColorRole color = TokenColorRole.error;

  /// md.comp.badge.shape
  static const ShapeStruct shape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.badge.large.color
  static const TokenColorRole largeColor = TokenColorRole.error;
}
