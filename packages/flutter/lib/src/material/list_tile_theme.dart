// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Defines the title font used for [ListTile] descendants of a [ListTileTheme].
///
/// List tiles that appear in a [Drawer] use the theme's [TextTheme.bodyText1]
/// text style, which is a little smaller than the theme's [TextTheme.subtitle1]
/// text style, which is used by default.
enum ListTileStyle {
  /// Use a title font that's appropriate for a [ListTile] in a list.
  list,

  /// Use a title font that's appropriate for a [ListTile] that appears in a [Drawer].
  drawer,
}

/// An inherited widget that defines color and style parameters for [ListTile]s
/// in this widget's subtree.
///
/// Values specified here are used for [ListTile] properties that are not given
/// an explicit non-null value.
///
/// The [Drawer] widget specifies a tile theme for its children which sets
/// [style] to [ListTileStyle.drawer].
class ListTileTheme extends InheritedTheme {
  /// Creates a list tile theme that controls the color and style parameters for
  /// [ListTile]s.
  const ListTileTheme({
    Key? key,
    this.dense = false,
    this.shape,
    this.style = ListTileStyle.list,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.contentPadding,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    required Widget child,
  }) : super(key: key, child: child);

  /// Creates a list tile theme that controls the color and style parameters for
  /// [ListTile]s, and merges in the current list tile theme, if any.
  ///
  /// The [child] argument must not be null.
  static Widget merge({
    Key? key,
    bool? dense,
    ShapeBorder? shape,
    ListTileStyle? style,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
    EdgeInsetsGeometry? contentPadding,
    Color? tileColor,
    Color? selectedTileColor,
    bool? enableFeedback,
    required Widget child,
  }) {
    assert(child != null);
    return Builder(
      builder: (BuildContext context) {
        final ListTileTheme parent = ListTileTheme.of(context);
        return ListTileTheme(
          key: key,
          dense: dense ?? parent.dense,
          shape: shape ?? parent.shape,
          style: style ?? parent.style,
          selectedColor: selectedColor ?? parent.selectedColor,
          iconColor: iconColor ?? parent.iconColor,
          textColor: textColor ?? parent.textColor,
          contentPadding: contentPadding ?? parent.contentPadding,
          tileColor: tileColor ?? parent.tileColor,
          selectedTileColor: selectedTileColor ?? parent.selectedTileColor,
          enableFeedback: enableFeedback ?? parent.enableFeedback,
          child: child,
        );
      },
    );
  }

  /// If true then [ListTile]s will have the vertically dense layout.
  final bool dense;

  /// {@template flutter.material.ListTileTheme.shape}
  /// If specified, [shape] defines the shape of the [ListTile]'s [InkWell] border.
  /// {@endtemplate}
  final ShapeBorder? shape;

  /// If specified, [style] defines the font used for [ListTile] titles.
  final ListTileStyle style;

  /// If specified, the color used for icons and text when a [ListTile] is selected.
  final Color? selectedColor;

  /// If specified, the icon color used for enabled [ListTile]s that are not selected.
  final Color? iconColor;

  /// If specified, the text color used for enabled [ListTile]s that are not selected.
  final Color? textColor;

  /// The tile's internal padding.
  ///
  /// Insets a [ListTile]'s contents: its [ListTile.leading], [ListTile.title],
  /// [ListTile.subtitle], and [ListTile.trailing] widgets.
  final EdgeInsetsGeometry? contentPadding;

  /// If specified, defines the background color for `ListTile` when
  /// [ListTile.selected] is false.
  ///
  /// If [ListTile.tileColor] is provided, [tileColor] is ignored.
  final Color? tileColor;

  /// If specified, defines the background color for `ListTile` when
  /// [ListTile.selected] is true.
  ///
  /// If [ListTile.selectedTileColor] is provided, [selectedTileColor] is ignored.
  final Color? selectedTileColor;

  /// If specified, defines the feedback property for `ListTile`.
  ///
  /// If [ListTile.enableFeedback] is provided, [enableFeedback] is ignored.
  final bool? enableFeedback;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ListTileTheme theme = ListTileTheme.of(context);
  /// ```
  static ListTileTheme of(BuildContext context) {
    final ListTileTheme? result = context.dependOnInheritedWidgetOfExactType<ListTileTheme>();
    return result ?? const ListTileTheme(child: SizedBox());
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return ListTileTheme(
      dense: dense,
      shape: shape,
      style: style,
      selectedColor: selectedColor,
      iconColor: iconColor,
      textColor: textColor,
      contentPadding: contentPadding,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      child: child,
    );
  }

  @override
  bool updateShouldNotify(ListTileTheme oldWidget) {
    return dense != oldWidget.dense
      || shape != oldWidget.shape
      || style != oldWidget.style
      || selectedColor != oldWidget.selectedColor
      || iconColor != oldWidget.iconColor
      || textColor != oldWidget.textColor
      || contentPadding != oldWidget.contentPadding
      || tileColor != oldWidget.tileColor
      || selectedTileColor != oldWidget.selectedTileColor
      || enableFeedback != oldWidget.enableFeedback;
  }
}
