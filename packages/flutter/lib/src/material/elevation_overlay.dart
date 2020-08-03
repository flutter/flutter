// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A utility class for dealing with the overlay color needed
/// to indicate elevation of surfaces in a dark theme.
class ElevationOverlay {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  ElevationOverlay._();

  /// Applies an overlay color to a surface color to indicate
  /// the level of its elevation in a dark theme.
  ///
  /// Material drop shadows can be difficult to see in a dark theme, so the
  /// elevation of a surface should be portrayed with an "overlay" in addition
  /// to the shadow. As the elevation of the component increases, the
  /// overlay increases in opacity. This function computes and applies this
  /// overlay to a given color as needed.
  ///
  /// If the ambient theme is dark ([ThemeData.brightness] is [Brightness.dark]),
  /// and [ThemeData.applyElevationOverlayColor] is true, and the given
  /// [color] is [ColorScheme.surface] then this will return a version of
  /// the [color] with a semi-transparent [ColorScheme.onSurface] overlaid
  /// on top of it. The opacity of the overlay is computed based on the
  /// [elevation].
  ///
  /// Otherwise it will just return the [color] unmodified.
  ///
  /// See also:
  ///
  ///  * [ThemeData.applyElevationOverlayColor] which controls the whether
  ///    an overlay color will be applied to indicate elevation.
  ///  * [overlayColor] which computes the needed overlay color.
  ///  * [Material] which uses this to apply an elevation overlay to its surface.
  ///  * <https://material.io/design/color/dark-theme.html>, which specifies how
  ///    the overlay should be applied.
  static Color applyOverlay(BuildContext context, Color color, double elevation) {
    final ThemeData theme = Theme.of(context);
    if (elevation > 0.0 &&
        theme.applyElevationOverlayColor &&
        theme.brightness == Brightness.dark &&
        color == theme.colorScheme.surface) {
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
