// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines a theme for [Dialog] widgets.
///
/// Descendant widgets obtain the current [DialogTheme] object using
/// `DialogTheme.of(context)`. Instances of [DialogTheme] can be customized with
/// [DialogTheme.copyWith].
///
/// When Shape is `null`, the dialog defaults to a [RoundedRectangleBorder] with
/// a border radius of 2.0 on all corners.
///
/// See also:
///
///  * [Dialog], a material dialog that can be customized using this [DialogTheme].
///  * [ThemeData], which describes the overall theme information for the
///    application.
class DialogTheme extends Diagnosticable {
  /// Creates a dialog theme that can be used for [ThemeData.dialogTheme].
  const DialogTheme({ this.shape });

  /// Default value for [Dialog.shape].
  final ShapeBorder shape;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  DialogTheme copyWith({ ShapeBorder shape }) {
    return DialogTheme(shape: shape ?? this.shape);
  }

  /// The data from the closest [DialogTheme] instance given the build context.
  static DialogTheme of(BuildContext context) {
    return Theme.of(context).dialogTheme;
  }

  /// Linearly interpolate between two dialog themes.
  ///
  /// The arguments must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static DialogTheme lerp(DialogTheme a, DialogTheme b, double t) {
    assert(t != null);
    return DialogTheme(
        shape: ShapeBorder.lerp(a?.shape, b?.shape, t)
    );
  }

  @override
  int get hashCode => shape.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final DialogTheme typedOther = other;
    return typedOther.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}
