// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// This code is ported from the AngularDart SCSS.
///
/// See: https://github.com/dart-lang/angular_components/blob/master/lib/css/material/_shadow.scss
class ElevationShadow {
  /// Applies a standard transition style for box-shadow to box-shadow.
  static void applyShadowTransition(html.CssStyleDeclaration style) {
    style.transition = 'box-shadow .28s cubic-bezier(.4, 0, .2, 1)';
  }

  /// Disables box-shadow.
  static void applyShadowNone(html.CssStyleDeclaration style) {
    style.boxShadow = 'none';
  }

  /// Applies a standard shadow to the selected element(s).
  ///
  /// This rule is great for things that need a static shadow. If the elevation
  /// of the shadow needs to be changed dynamically, use [applyShadow].
  ///
  /// Valid values: 2, 3, 4, 6, 8, 12, 16, 24
  static void applyShadowElevation(html.CssStyleDeclaration style,
      {@required int dp, @required ui.Color color}) {
    const double keyUmbraOpacity = 0.2;
    const double keyPenumbraOpacity = 0.14;
    const double ambientShadowOpacity = 0.12;

    final String rgb = '${color.red}, ${color.green}, ${color.blue}';
    if (dp == 2) {
      style.boxShadow = '0 2px 2px 0 rgba($rgb, $keyPenumbraOpacity), '
          '0 3px 1px -2px rgba($rgb, $ambientShadowOpacity), '
          '0 1px 5px 0 rgba($rgb, $keyUmbraOpacity)';
    } else if (dp == 3) {
      style.boxShadow = '0 3px 4px 0 rgba($rgb, $keyPenumbraOpacity), '
          '0 3px 3px -2px rgba($rgb, $ambientShadowOpacity), '
          '0 1px 8px 0 rgba($rgb, $keyUmbraOpacity)';
    } else if (dp == 4) {
      style.boxShadow = '0 4px 5px 0 rgba($rgb, $keyPenumbraOpacity), '
          '0 1px 10px 0 rgba($rgb, $ambientShadowOpacity), '
          '0 2px 4px -1px rgba($rgb, $keyUmbraOpacity)';
    } else if (dp == 6) {
      style.boxShadow = '0 6px 10px 0 rgba($rgb, $keyPenumbraOpacity), '
          '0 1px 18px 0 rgba($rgb, $ambientShadowOpacity), '
          '0 3px 5px -1px rgba($rgb, $keyUmbraOpacity)';
    } else if (dp == 8) {
      style.boxShadow = '0 8px 10px 1px rgba($rgb, $keyPenumbraOpacity), '
          '0 3px 14px 2px rgba($rgb, $ambientShadowOpacity), '
          '0 5px 5px -3px rgba($rgb, $keyUmbraOpacity)';
    } else if (dp == 12) {
      style.boxShadow = '0 12px 17px 2px rgba($rgb, $keyPenumbraOpacity), '
          '0 5px 22px 4px rgba($rgb, $ambientShadowOpacity), '
          '0 7px 8px -4px rgba($rgb, $keyUmbraOpacity)';
    } else if (dp == 16) {
      style.boxShadow = '0 16px 24px 2px rgba($rgb, $keyPenumbraOpacity), '
          '0  6px 30px 5px rgba($rgb, $ambientShadowOpacity), '
          '0  8px 10px -5px rgba($rgb, $keyUmbraOpacity)';
    } else {
      style.boxShadow = '0 24px 38px 3px rgba($rgb, $keyPenumbraOpacity), '
          '0  9px 46px 8px rgba($rgb, $ambientShadowOpacity), '
          '0  11px 15px -7px rgba($rgb, $keyUmbraOpacity)';
    }
  }

  /// Applies the shadow styles to the selected element.
  ///
  /// Use the attributes below to control the shadow.
  ///
  /// - `animated` -- Whether to animate the shadow transition.
  /// - `elevation` -- Z-elevation of shadow. Valid Values: 1,2,3,4,5
  static void applyShadow(
      html.CssStyleDeclaration style, double elevation, ui.Color color) {
    applyShadowTransition(style);

    if (elevation <= 0.0) {
      applyShadowNone(style);
    } else if (elevation <= 1.0) {
      applyShadowElevation(style, dp: 2, color: color);
    } else if (elevation <= 2.0) {
      applyShadowElevation(style, dp: 4, color: color);
    } else if (elevation <= 3.0) {
      applyShadowElevation(style, dp: 6, color: color);
    } else if (elevation <= 4.0) {
      applyShadowElevation(style, dp: 8, color: color);
    } else if (elevation <= 5.0) {
      applyShadowElevation(style, dp: 16, color: color);
    } else {
      applyShadowElevation(style, dp: 24, color: color);
    }
  }

  static List<CanvasShadow> computeCanvasShadows(
      double elevation, ui.Color color) {
    if (elevation <= 0.0) {
      return const <CanvasShadow>[];
    } else if (elevation <= 1.0) {
      return computeShadowElevation(dp: 2, color: color);
    } else if (elevation <= 2.0) {
      return computeShadowElevation(dp: 4, color: color);
    } else if (elevation <= 3.0) {
      return computeShadowElevation(dp: 6, color: color);
    } else if (elevation <= 4.0) {
      return computeShadowElevation(dp: 8, color: color);
    } else if (elevation <= 5.0) {
      return computeShadowElevation(dp: 16, color: color);
    } else {
      return computeShadowElevation(dp: 24, color: color);
    }
  }

  /// Expands rect to include size of shadow.
  ///
  /// Computed from shadow elevation offset + spread, blur
  static ui.Rect computeShadowRect(ui.Rect r, double elevation) {
    // We are computing this rect by computing the maximum "reach" of the shadow
    // by summing the computed shadow offset and the blur for the given
    // elevation.  We are assuming that a blur of '1' corresponds to 1 pixel,
    // although the web spec says that this is not necessarily the case.
    // However, it seems to be a good conservative estimate.
    if (elevation <= 0.0) {
      return r;
    } else if (elevation <= 1.0) {
      return ui.Rect.fromLTRB(
          r.left - 2.5, r.top - 1.5, r.right + 3, r.bottom + 4);
    } else if (elevation <= 2.0) {
      return ui.Rect.fromLTRB(r.left - 5, r.top - 3, r.right + 6, r.bottom + 7);
    } else if (elevation <= 3.0) {
      return ui.Rect.fromLTRB(
          r.left - 9, r.top - 8, r.right + 9, r.bottom + 11);
    } else if (elevation <= 4.0) {
      return ui.Rect.fromLTRB(
          r.left - 10, r.top - 6, r.right + 10, r.bottom + 14);
    } else if (elevation <= 5.0) {
      return ui.Rect.fromLTRB(
          r.left - 15, r.top - 9, r.right + 20, r.bottom + 30);
    } else {
      return ui.Rect.fromLTRB(
          r.left - 23, r.top - 14, r.right + 23, r.bottom + 45);
    }
  }

  static List<CanvasShadow> computeShadowElevation(
      {@required int dp, @required ui.Color color}) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final ui.Color penumbraColor = ui.Color.fromARGB(36, red, green, blue);
    final ui.Color ambientShadowColor = ui.Color.fromARGB(31, red, green, blue);
    final ui.Color umbraColor = ui.Color.fromARGB(51, red, green, blue);

    final List<CanvasShadow> result = <CanvasShadow>[];
    if (dp == 2) {
      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 2.0,
        blur: 1.0,
        spread: 0.0,
        color: penumbraColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 3.0,
        blur: 0.5,
        spread: -2.0,
        color: ambientShadowColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 1.0,
        blur: 2.5,
        spread: 0.0,
        color: umbraColor,
      ));
    } else if (dp == 3) {
      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 1.5,
        blur: 4.0,
        spread: 0.0,
        color: penumbraColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 3.0,
        blur: 1.5,
        spread: -2.0,
        color: ambientShadowColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 1.0,
        blur: 4.0,
        spread: 0.0,
        color: umbraColor,
      ));
    } else if (dp == 4) {
      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 4.0,
        blur: 2.5,
        spread: 0.0,
        color: penumbraColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 1.0,
        blur: 5.0,
        spread: 0.0,
        color: ambientShadowColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 2.0,
        blur: 2.0,
        spread: -1.0,
        color: umbraColor,
      ));
    } else if (dp == 6) {
      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 6.0,
        blur: 5.0,
        spread: 0.0,
        color: penumbraColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 1.0,
        blur: 9.0,
        spread: 0.0,
        color: ambientShadowColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 3.0,
        blur: 2.5,
        spread: -1.0,
        color: umbraColor,
      ));
    } else if (dp == 8) {
      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 4.0,
        blur: 10.0,
        spread: 1.0,
        color: penumbraColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 3.0,
        blur: 7.0,
        spread: 2.0,
        color: ambientShadowColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 5.0,
        blur: 2.5,
        spread: -3.0,
        color: umbraColor,
      ));
    } else if (dp == 12) {
      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 12.0,
        blur: 8.5,
        spread: 2.0,
        color: penumbraColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 5.0,
        blur: 11.0,
        spread: 4.0,
        color: ambientShadowColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 7.0,
        blur: 4.0,
        spread: -4.0,
        color: umbraColor,
      ));
    } else if (dp == 16) {
      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 16.0,
        blur: 12.0,
        spread: 2.0,
        color: penumbraColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 6.0,
        blur: 15.0,
        spread: 5.0,
        color: ambientShadowColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 0.0,
        blur: 5.0,
        spread: -5.0,
        color: umbraColor,
      ));
    } else {
      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 24.0,
        blur: 18.0,
        spread: 3.0,
        color: penumbraColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 9.0,
        blur: 23.0,
        spread: 8.0,
        color: ambientShadowColor,
      ));

      result.add(CanvasShadow(
        offsetX: 0.0,
        offsetY: 11.0,
        blur: 7.5,
        spread: -7.0,
        color: umbraColor,
      ));
    }
    return result;
  }
}

class CanvasShadow {
  CanvasShadow({
    @required this.offsetX,
    @required this.offsetY,
    @required this.blur,
    @required this.spread,
    @required this.color,
  });

  final double offsetX;
  final double offsetY;
  final double blur;
  // TODO(yjbanov): is there a way to implement/emulate spread on Canvas2D?
  final double spread;
  final ui.Color color;
}
