// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A simple utility class for dealing with the overlay color needed
/// to indicate elevation for dark theme widgets.
///
/// This is an internal implementation class and should not be exported by
/// the material package.
class ElevationOverlay {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  ElevationOverlay._();

  /// Applies an elevation overlay color to a given color to indicate
  /// the level of elevation in a dark theme.
  ///
  /// If the ambient [ThemeData.applyElevationOverlayColor] is true,
  /// and [ThemeData.brightness] is [Brightness.dark] then this will return
  /// a version of the given color with a semi-transparent
  /// [ThemeData.colorScheme.onSurface] overlaid on top of it. The opacity
  /// of the overlay is computed based on the [elevation].
  ///
  /// Otherwise it will just return the [color] unmodified.
  ///
  /// See also:
  ///
  ///  * [ThemeData.applyElevationOverlayColor] which controls the whether
  ///    an overlay color will be applied to indicate elevation.
  ///  * [overlayColor] which computes the needed overlay color.
  static Color applyOverlay(BuildContext context, Color color, double elevation) {
    final ThemeData theme = Theme.of(context);
    if (elevation > 0.0 &&
        theme.applyElevationOverlayColor &&
        theme.brightness == Brightness.dark) {

      return Color.alphaBlend(overlayColor(context, elevation), color);
    }
    return color;
  }

  /// Computes the appropriate overlay color used to indicate elevation in
  /// dark themes.
  ///
  /// See also:
  ///
  ///  * https://material.io/design/color/dark-theme.html#properties which
  ///    specifies the exact overlay values for a given elevation.
  static Color overlayColor(BuildContext context, double elevation) {
    final ThemeData theme = Theme.of(context);
    // Compute the opacity for the given elevation
    // This formula matches the values in the spec:
    // https://material.io/design/color/dark-theme.html#properties
    final double opacity = (4.5 * math.log(elevation + 1) + 2) / 100.0;
    return theme.colorScheme.onSurface.withOpacity(opacity);
  }
}
