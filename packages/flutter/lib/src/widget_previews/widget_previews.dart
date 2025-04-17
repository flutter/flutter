// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:/flutter/cupertino.dart';
/// @docImport 'package:/flutter/material.dart';
library;

import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/material.dart' show Brightness, ThemeData;
import 'package:flutter/widgets.dart';

/// Annotation used to mark functions that return a widget preview.
///
/// NOTE: this interface is not stable and **will change**.
///
/// {@tool snippet}
///
/// Functions annotated with `@Preview()` must return a `Widget` or
/// `WidgetBuilder` and be public. This annotation can only be applied
/// to top-level functions, static methods defined within a class, and
/// public `Widget` constructors and factories with no required arguments.
///
/// ```dart
/// @Preview(name: 'Top-level preview')
/// Widget preview() => const Text('Foo');
///
/// @Preview(name: 'Builder preview')
/// WidgetBuilder builderPreview() {
///   return (BuildContext context) {
///     return const Text('Builder');
///   };
/// }
///
/// class MyWidget extends StatelessWidget {
///   @Preview(name: 'Constructor preview')
///   const MyWidget.preview({super.key});
///
///   @Preview(name: 'Factory constructor preview')
///   factory MyWidget.factoryPreview() => const MyWidget.preview();
///
///   @Preview(name: 'Static preview')
///   static Widget previewStatic() => const Text('Static');
///
///   @override
///   Widget build(BuildContext context) {
///     return const Text('MyWidget');
///   }
/// }
/// ```
/// {@end-tool}
///
/// **Important Note:** all values provided to the `@Preview()` annotation must
/// be constant and non-private.
// TODO(bkonyi): link to actual documentation when available.
base class Preview {
  /// Annotation used to mark functions that return widget previews.
  const Preview({
    this.name,
    this.width,
    this.height,
    this.textScaleFactor,
    this.wrapper,
    this.theme,
    this.brightness,
  });

  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  final String? name;

  /// Artificial width constraint to be applied to the previewed widget.
  ///
  /// If not provided, the previewed widget will attempt to set its own width
  /// constraints and may result in an unbounded constraint error.
  final double? width;

  /// Artificial height constraint to be applied to the previewed widget.
  ///
  /// If not provided, the previewed widget will attempt to set its own height
  /// constraints and may result in an unbounded constraint error.
  final double? height;

  /// Applies font scaling to text within the previewed widget.
  ///
  /// If not provided, the default text scaling factor provided by [MediaQuery]
  /// will be used.
  final double? textScaleFactor;

  /// Wraps the previewed [Widget] in a [Widget] tree.
  ///
  /// This function can be used to perform dependency injection or setup
  /// additional scaffolding needed to correctly render the preview.
  ///
  /// Note: this must be a reference to a static, public function defined as
  /// either a top-level function or static member in a class.
  // TODO(bkonyi): provide an example.
  final Widget Function(Widget)? wrapper;

  /// A callback to return Material and Cupertino theming data to be applied
  /// to the previewed [Widget].
  ///
  /// Note: this must be a reference to a static, public function defined as
  /// either a top-level function or static member in a class.
  final PreviewThemeData Function()? theme;

  /// Sets the initial theme brightness.
  ///
  /// If not provided, the current system default brightness will be used.
  final Brightness? brightness;
}

/// A collection of [ThemeData] and [CupertinoThemeData] instances for use in
/// widget previews.
base class PreviewThemeData {
  /// Creates a collection of [ThemeData] and [CupertinoThemeData] instances
  /// for use in widget previews.
  ///
  /// If a theme isn't provided for a specific configuration, no theme data
  /// will be applied and the default theme will be used.
  const PreviewThemeData({
    this.materialLight,
    this.materialDark,
    this.cupertinoLight,
    this.cupertinoDark,
  });

  /// The Material [ThemeData] to apply when light mode is enabled.
  final ThemeData? materialLight;

  /// The Material [ThemeData] to apply when dark mode is enabled.
  final ThemeData? materialDark;

  /// The Cupertino [CupertinoThemeData] to apply when light mode is enabled.
  final CupertinoThemeData? cupertinoLight;

  /// The Cupertino [CupertinoThemeData] to apply when dark mode is enabled.
  final CupertinoThemeData? cupertinoDark;

  /// Returns the pair of [ThemeData] and [CupertinoThemeData] corresponding to
  /// the value of [brightness].
  (ThemeData?, CupertinoThemeData?) themeForBrightness(Brightness brightness) {
    if (brightness == Brightness.light) {
      return (materialLight, cupertinoLight);
    }
    return (materialDark, cupertinoDark);
  }
}
