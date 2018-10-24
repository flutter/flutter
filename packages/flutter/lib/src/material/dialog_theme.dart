// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dialog.dart';

/// Defines a theme for [Dialog] widgets.
///
/// A dialog theme describes the shape of the [Dialog]'s border.
///
/// Descendant widgets obtain the current theme's [DialogTheme] object using
/// `Theme.of(context).dialogTheme`.
/// [ThemeData.dialogTheme] can be customized by copying it (using
/// [DialogTheme.copyWith]).
///
/// See also:
///
///  * [Dialog], a widget that displays a material dialog, [Dialog] is used by
///  [AlertDialog], and [SimpleDialog].
///  * [ThemeData], which describes the overall theme information for the
///  application.
class DialogTheme extends Diagnosticable {
  /// Creates a dialog theme that can be used with [ThemeData.dialogTheme].
  const DialogTheme({ this.shape });

  /// Default value for [Dialog.shape].
  final ShapeBorder shape;

  /// Linearly interpolate between two dialog themes.
  ///
  /// The arguments must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static DialogTheme lerp(DialogTheme a, DialogTheme b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    return DialogTheme(
        shape: ShapeBorder.lerp(a.shape, b.shape, t)
    );
  }

  @override
  int get hashCode {
    return shape.hashCode;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final DialogTheme typedOther = other;
    return typedOther.shape == shape;
  }
}
