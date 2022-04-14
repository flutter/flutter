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
  ///
  /// The opacity applies to both explicit and default icon colors. The value
  /// is clamped between 0.0 and 1.0.
  const CupertinoIconThemeData({
    super.color,
    super.opacity,
    super.size,
    super.shadows,
  });

  /// Called by [IconTheme.of] to resolve [color] against the given [BuildContext].
  @override
  IconThemeData resolve(BuildContext context) {
    final Color? resolvedColor = CupertinoDynamicColor.maybeResolve(color, context);
    return resolvedColor == color ? this : copyWith(color: resolvedColor);
  }

  /// Creates a copy of this icon theme but with the given fields replaced with
  /// the new values.
  @override
  CupertinoIconThemeData copyWith({ Color? color, double? opacity, double? size, List<Shadow>? shadows }) {
    return CupertinoIconThemeData(
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      size: size ?? this.size,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(createCupertinoColorProperty('color', color, defaultValue: null));
  }
}
