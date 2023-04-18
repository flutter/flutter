// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'colors.dart';

/// An [IconThemeData] subclass that automatically resolves its [color] when retrieved
/// using [IconTheme.of].
class CupertinoIconThemeData extends IconThemeData with Diagnosticable {
  /// Creates a [CupertinoIconThemeData].
  const CupertinoIconThemeData({
    super.size,
    super.fill,
    super.weight,
    super.grade,
    super.opticalSize,
    super.color,
    super.opacity,
    super.shadows,
  });

  /// Called by [IconTheme.of] to resolve [color] against the given [BuildContext].
  @override
  IconThemeData resolve(final BuildContext context) {
    final Color? resolvedColor = CupertinoDynamicColor.maybeResolve(color, context);
    return resolvedColor == color ? this : copyWith(color: resolvedColor);
  }

  /// Creates a copy of this icon theme but with the given fields replaced with
  /// the new values.
  @override
  CupertinoIconThemeData copyWith({
    final double? size,
    final double? fill,
    final double? weight,
    final double? grade,
    final double? opticalSize,
    final Color? color,
    final double? opacity,
    final List<Shadow>? shadows,
  }) {
    return CupertinoIconThemeData(
      size: size ?? this.size,
      fill: fill ?? this.fill,
      weight: weight ?? this.weight,
      grade: grade ?? this.grade,
      opticalSize: opticalSize ?? this.opticalSize,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(createCupertinoColorProperty('color', color, defaultValue: null));
  }
}
