// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A description of an icon fulfilled by a font glyph.
///
/// See [Icons] for a number of predefined icons available for material
/// design applications.
@immutable
class IconData {
  /// Creates icon data.
  ///
  /// Rarely used directly. Instead, consider using one of the predefined icons
  /// like the [Icons] collection.
  ///
  /// The [fontPackage] argument must be non-null when using a font family that
  /// is included in a package. This is used when selecting the font.
  const IconData(
    this.codePoint, {
    this.fontFamily,
    this.fontPackage,
  });

  /// The Unicode code point at which this icon is stored in the icon font.
  final int codePoint;

  /// The font family from which the glyph for the [codePoint] will be selected.
  final String fontFamily;

  // The name of the package from which the font family is included.
  final String fontPackage;

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final IconData typedOther = other;
    return codePoint == typedOther.codePoint;
  }

  @override
  int get hashCode => codePoint.hashCode;

  @override
  String toString() => 'IconData(U+${codePoint.toRadixString(16).toUpperCase().padLeft(5, '0')})';
}