// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// A set of 4 colors that can be used to configure the color properties of
/// components with contrast managed.
@immutable
class ColorsScheme with Diagnosticable {
  /// Create a ColorsScheme instance from the given colors.
  ///
  /// [ColorsScheme.fromSeed] can be used as a simpler way to create a full
  /// color scheme derived from a single seed color.
  ///
  /// * [seedColor]
  /// * [color]
  /// * [onColor]
  /// * [container]
  /// * [onContainer]
  const ColorsScheme({
    required this.brightness,
    required this.seedColor,
    required this.color,
    required this.onColor,
    required this.container,
    required this.onContainer,
  });

  /// Generate a [ColorsScheme] derived from the given `seedColor`.
  ///
  /// Using the seedColor as a starting point, a tonal palettes is
  /// constructed.
  /// The tonal palette is based on the Material 3 Color system and provide all
  /// the needed colors for a [ColorsScheme].
  /// These colors are designed to work well together and meet contrast
  /// requirements for accessibility.
  factory ColorsScheme.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) {
    final Cam16 cam = Cam16.fromInt(seedColor.value);
    final TonalPalette tonalPalette =
        TonalPalette.of(cam.hue, max(48, cam.chroma));
    switch (brightness) {
      case Brightness.light:
        return ColorsScheme(
          seedColor: seedColor,
          brightness: brightness,
          color: Color(tonalPalette.get(40)),
          onColor: Color(tonalPalette.get(100)),
          container: Color(tonalPalette.get(90)),
          onContainer: Color(tonalPalette.get(10)),
        );
      case Brightness.dark:
        return ColorsScheme(
          seedColor: seedColor,
          brightness: brightness,
          color: Color(tonalPalette.get(80)),
          onColor: Color(tonalPalette.get(20)),
          container: Color(tonalPalette.get(30)),
          onContainer: Color(tonalPalette.get(90)),
        );
    }
  }

  /// The overall brightness of this colors scheme.
  final Brightness brightness;

  /// The color used to generate Colors.
  final Color seedColor;

  /// The color principal to use.
  final Color color;

  /// A color that's clearly legible when drawn on [color].
  final Color onColor;

  /// A color used for elements needing less emphasis than [color].
  final Color container;

  /// A color that's clearly legible when drawn on [container].
  final Color onContainer;

  /// Creates a copy of this colorsgit remote scheme with the given fields
  /// replaced by the non-null parameter values.
  ColorsScheme copyWith({
    Brightness? brightness,
    Color? seedColor,
    Color? color,
    Color? onColor,
    Color? container,
    Color? onContainer,
  }) {
    return ColorsScheme(
      brightness: brightness ?? this.brightness,
      seedColor : seedColor ?? this.seedColor,
      color : color ?? this.color,
      onColor : onColor ?? this.onColor,
      container : container ?? this.container,
      onContainer : onContainer ?? this.onContainer,
    );
  }
}
