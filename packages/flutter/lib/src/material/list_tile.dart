// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'divider.dart';
import 'icon_button.dart';
import 'icon_button_theme.dart';
import 'ink_decoration.dart';
import 'ink_well.dart';
import 'list_tile_theme.dart';
import 'material_state.dart';
import 'text_theme.dart';
import 'theme.dart';
import 'theme_data.dart';

// Examples can assume:
// int _act = 1;

/// Defines the title font used for [ListTile] descendants of a [ListTileTheme].
///
/// List tiles that appear in a [Drawer] use the theme's [TextTheme.bodyLarge]
/// text style, which is a little smaller than the theme's [TextTheme.titleMedium]
/// text style, which is used by default.
enum ListTileStyle {
  /// Use a title font that's appropriate for a [ListTile] in a list.
  list,

  /// Use a title font that's appropriate for a [ListTile] that appears in a [Drawer].
  drawer,
}

/// Where to place the control in widgets that use [ListTile] to position a
/// control next to a label.
///
/// See also:
///
///  * [CheckboxListTile], which combines a [ListTile] with a [Checkbox].
///  * [RadioListTile], which combines a [ListTile] with a [Radio] button.
///  * [SwitchListTile], which combines a [ListTile] with a [Switch].
///  * [ExpansionTile], which combines a [ListTile] with a button that expands
///    or collapses the tile to reveal or hide the children.
enum ListTileControlAffinity {
  /// Position the control on the leading edge, and the secondary widget, if
  /// any, on the trailing edge.
  leading,

  /// Position the control on the trailing edge, and the secondary widget, if
  /// any, on the leading edge.
  trailing,

  /// Position the control relative to the text in the fashion that is typical
  /// for the current platform, and place the secondary widget on the opposite
  /// side.
  platform,
}

/// Defines how [ListTile.leading] and [ListTile.trailing] are
/// vertically aligned relative to the [ListTile]'s titles
/// ([ListTile.title] and [ListTile.subtitle]).
///
/// See also:
///
///  * [ListTile.titleAlignment], to configure the title alignment for an
///    individual [ListTile].
///  * [ListTileThemeData.titleAlignment], to configure the title alignment
///    for all of the [ListTile]s under a [ListTileTheme].
///  * [ThemeData.listTileTheme], to configure the [ListTileTheme]
///    for an entire app.
enum ListTileTitleAlignment {
  /// The top of the [ListTile.leading] and [ListTile.trailing] widgets are
  /// placed [ListTile.minVerticalPadding] below the top of the [ListTile.title]
  /// if [ListTile.isThreeLine] is true, otherwise they're centered relative
  /// to the [ListTile.title] and [ListTile.subtitle] widgets.
  threeLine,

  /// The top of the [ListTile.leading] and [ListTile.trailing]
  /// widgets are placed [ListTile.minVerticalPadding] below the top of the
  /// [ListTile] if [ListTile.isThreeLine] is true or the height of the
  /// [ListTile] is greater than 88, otherwise they're centered
  /// relative to the [ListTile].
  ///
  /// This is the default when [ThemeData.useMaterial3] is true.
  material3,

  /// The tops of the [ListTile.leading] and [ListTile.trailing] widgets are
  /// placed 16 units below the top of the [ListTile.title]
  /// if the titles' overall height is greater than 72, otherwise they're
  /// centered relative to the [ListTile.title] and [ListTile.subtitle] widgets.
  ///
  /// This is the default when [ThemeData.useMaterial3] is false.
  titleHeight,

  /// The tops of the [ListTile.leading] and [ListTile.trailing] widgets are
  /// placed [ListTile.minVerticalPadding] below the top of the [ListTile.title].
  top,

  /// The [ListTile.leading] and [ListTile.trailing] widgets are
  /// centered relative to the [ListTile]'s titles.
  center,

  /// The bottoms of the [ListTile.leading] and [ListTile.trailing] widgets are
  /// placed [ListTile.minVerticalPadding] above the bottom of the [ListTile]'s
  /// titles.
  bottom,
}

/// Use internally to pass the list size in lines.
enum ListTileLineCount {
  /// A one-line list.
  oneLine,

  /// A two-line list.
  twoLine,

  /// A three-line list.
  threeLine,
}

/// A class to allow the padding around a widget to be treated as part
/// of the padding provided by the widget itself.
///
/// An example is the [IconButton]. For accessibility, this provides a padding
/// of 8 on each side to make a larger tap target. In the Material 2 & 3 List
/// specification this padding is part of the List.
/// [ListTileConstraint.icon24] can be used
/// to align the [Icon] part of the button correctly.
///
/// See also:
///
/// * [ListTileConstraint] this uses ListTilePaddingCorrection and can be
///   applied to a [ListTile].
@immutable
class ListTilePaddingCorrection extends EdgeInsetsDirectional {
  const ListTilePaddingCorrection._({
    double start = 0.0,
    double top = 0.0,
    double end = 0.0,
    double bottom = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  }): super.fromSTEB(start, top, end, bottom);

  /// The distance from the true center of the widget to the
  /// corrected center in the X axis.
  final double offsetX;

  /// The distance from the true center of the widget to the
  /// corrected center in the Y axis.
  final double offsetY;

  /// Do not correct the widget.
  static const ListTilePaddingCorrection noCorrection = ListTilePaddingCorrection._();

  /// Apply a specific correction..
  ///
  /// The this will not allow the correction to move the element off the
  /// [ListTile] or cause it to overlap with the [ListTile.title],
  /// [ListTile.overline] or [ListTile.subtitle].
  static ListTilePaddingCorrection of(EdgeInsetsDirectional targetCorrection) {
    return ListTilePaddingCorrection._(
      start: targetCorrection.start,
      top: targetCorrection.top,
      end: targetCorrection.end,
      bottom: targetCorrection.bottom,
      offsetX: targetCorrection.end - targetCorrection.start,
      offsetY: targetCorrection.bottom - targetCorrection.top,
    );
  }

  @override
  String toString() {
    return 'ListTilePaddingCorrection('
        'start: ${start.toStringAsFixed(1)}, '
        'top: ${top.toStringAsFixed(1)}, '
        'end: ${end.toStringAsFixed(1)}, '
        'bottom: ${bottom.toStringAsFixed(1)}, '
        'offsetX: ${offsetX.toStringAsFixed(1)}, '
        'offsetY: ${offsetY.toStringAsFixed(1)}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return other is ListTilePaddingCorrection
      &&  start == other.start
      &&  top == other.top
      &&  end == other.end
      &&  bottom == other.bottom
      &&  offsetX == other.offsetX
      &&  offsetY == other.offsetY;
  }

  @override
  int get hashCode => Object.hash(start, top, end, bottom, offsetX, offsetY);
}

/// Used to control the layout behaviour of [ListTile], [ListTile.leading]
/// and [ListTile.trailing]. Allows the leading and trailing widget
/// size constraints, position and padding to be set, and the minimum height of
/// the [ListTile].
@immutable
class ListTileConstraint {
  /// Creates a [ListTileConstraint].
  ///
  /// See also:
  ///
  ///  * [ListTileConstraint.copyWith]
  ///  * [ListTileConstraint.standard]
  ///  * [ListTileConstraint.icon24]
  ///  * [ListTileConstraint.avatar]
  ///  * [ListTileConstraint.image]
  ///  * [ListTileConstraint.video]
  ///  * [ListTileConstraint.unconstrained]
  ///  * [ListTileConstraint.of]
  ///  * [ListTileConstraint.center]
  const ListTileConstraint({
    required this.maxSize,
    required this.minimumTileHeight,
    required this.leadingHorizontalTitleGap,
    required this.trailingHorizontalTitleGap,
    required this.ignoreHorizontalTilePadding,
    required this.paddingCorrection,
  });

  static Size _infiniteSize({required bool isDense, required bool useMaterial3, required Offset densityAdjustment}) {
    return Size.infinite;
  }
  static Size _defaultSize({required bool isDense, required bool useMaterial3, required Offset densityAdjustment}) {
    return Size.fromHeight((isDense ? 48.0 : 56.0) + densityAdjustment.dy);
  }
  static Size _avatarSize({required bool isDense, required bool useMaterial3, required Offset densityAdjustment}) {
    return Size.square(40 + densityAdjustment.dy);
  }
  static Size _imageSize({required bool isDense, required bool useMaterial3, required Offset densityAdjustment}) {
    return Size.square((isDense ? 48.0 : 56.0) + densityAdjustment.dy);
  }
  static Size _videoSize({required bool isDense, required bool useMaterial3, required Offset densityAdjustment}) {
    if (useMaterial3) {
      return Size((isDense ? 100: 114), (isDense ? 56.0 : 64.0) + densityAdjustment.dy);
    }
    return Size((isDense ? 86 : 100), (isDense ? 48.0 : 56.0) + densityAdjustment.dy);
  }

  static double _minimumTileHeightWithLeadingOrTrailingElement({
    required bool isDense,
    required bool useMaterial3,
    required bool isLeading,
    required ListTileLineCount numberOfLines,
  }) {
    switch (numberOfLines) {
      case ListTileLineCount.oneLine: {
        if (useMaterial3 || isLeading) {
          return isDense ? 48.0 : 56.0;
        }
        return 48.0;
      }
      case ListTileLineCount.twoLine: {
        if (!useMaterial3 && !isLeading) {
          return isDense ? 56.0 : 64.0;
        }
        return isDense ? 64.0 : 72.0;
      }
      case ListTileLineCount.threeLine: {
        return isDense ? 76.0 : 88.0;
      }
    }
  }

  static double _minimumTileHeightWithImage({
    required bool isDense,
    required bool useMaterial3,
    required bool isLeading,
    required ListTileLineCount numberOfLines,
  }) {
    if (numberOfLines == ListTileLineCount.threeLine) {
      return isDense ? 76.0 : 88.0;
    }
    return (isDense ? 64.0 : 72.0);
  }

  static double _minimumTileHeightWithVideo({
    required bool isDense,
    required bool useMaterial3,
    required bool isLeading,
    required ListTileLineCount numberOfLines,
  }) {
    if (useMaterial3 || numberOfLines == ListTileLineCount.threeLine) {
      return (isDense ? 76.0 : 88.0);
    }
    return (isDense ? 64.0 : 72.0);
  }

  static double _defaultHorizontalTitleGap({required bool isThreeLine, required bool useMaterial3}) {
    return 16.0;
  }
  static double _videoHorizontalTitleGap({required bool isThreeLine, required bool useMaterial3}) {
    return isThreeLine && !useMaterial3 ? 20.0 : 16.0;
  }

  static ListTilePaddingCorrection _noCorrection(Size widgetSize) {
    return ListTilePaddingCorrection.noCorrection;
  }

  static ListTilePaddingCorrection _center24(Size widgetSize) {
    return ListTilePaddingCorrection.of(EdgeInsetsDirectional.symmetric(
      horizontal: math.max(widgetSize.width - 24.0, 0.0) / 2.0,
      vertical: math.max(widgetSize.height - 24.0, 0.0) / 2.0,
    ));
  }

  static ListTilePaddingCorrection _switch(Size widgetSize) {
    return ListTilePaddingCorrection.of(const EdgeInsetsDirectional.all(4.0));
  }

  /// One-line trailing and leading widget heights do not follow
  /// Material specifications, but this sizing is required to adhere
  /// to accessibility requirements for smallest tappable widget.
  /// Two- and three-line trailing widget heights are constrained
  /// properly according to the Material spec.
  /// This is the same as image height.
  ///
  /// The leading or trailing element has an unbound width and maximum height
  /// of 48 when dense, otherwise 56.
  ///
  /// The leading and trailing horizontal title gaps are 16.
  static const ListTileConstraint standard =
    ListTileConstraint(
      maxSize: _defaultSize,
      minimumTileHeight: _minimumTileHeightWithLeadingOrTrailingElement,
      leadingHorizontalTitleGap: _defaultHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: false,
      paddingCorrection: _noCorrection,
    );

  /// A constraint that can be applied to an [Icon], such as for an [IconButton].
  ///
  /// When [ThemeData.useMaterial3] is false, and using default styles,
  /// this will cause the [IconButton]'s splash to clip off the [ListTile].
  static const ListTileConstraint icon24 =
    ListTileConstraint(
      maxSize: _defaultSize,
      minimumTileHeight: _minimumTileHeightWithLeadingOrTrailingElement,
      leadingHorizontalTitleGap: _defaultHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: false,
      paddingCorrection: _center24,
    );

  /// A constraint that can be applied to an [Switch].
  static const ListTileConstraint switchTile =
    ListTileConstraint(
      maxSize: _defaultSize,
      minimumTileHeight: _minimumTileHeightWithLeadingOrTrailingElement,
      leadingHorizontalTitleGap: _defaultHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: false,
      paddingCorrection: _switch,
    );

  /// Constraints for a standard avatar in a list.
  ///
  /// This limits the leading or trailing element size to a 40 square
  ///
  /// The leading and trailing horizontal title gaps are 16.
  static const ListTileConstraint avatar =
    ListTileConstraint(
      maxSize: _avatarSize,
      minimumTileHeight: _minimumTileHeightWithLeadingOrTrailingElement,
      leadingHorizontalTitleGap: _defaultHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: false,
      paddingCorrection: _noCorrection,
    );

  /// Constraints for a standard image in a list.
  ///
  /// This limits the leading or trailing element size to a 48 square
  /// when dense, otherwise to a 56 square. This forces the tile height to
  /// 64 when dense, otherwise to 72.
  ///
  /// The leading and trailing horizontal title gaps are 16.
  static const ListTileConstraint image =
    ListTileConstraint(
      maxSize: _imageSize,
      minimumTileHeight: _minimumTileHeightWithImage,
      leadingHorizontalTitleGap: _defaultHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: false,
      paddingCorrection: _noCorrection,
    );

  /// Constraints for a standard Material 2 or 3 video.
  ///
  /// When [ThemeData.useMaterial3] is true, this limits the leading or
  /// trailing element size to 56h x 100w when dense, otherwise 64h x 114w.
  /// The tile height to is forced to 72 when dense, otherwise to 88. The
  /// leading horizontal title gap is 16.
  ///
  /// When [ThemeData.useMaterial3] is false, this limits the leading or
  /// trailing element size to 48h x 86w when dense, otherwise 56h x 100w.
  /// The tile height to is forced to 64 when dense, otherwise to 72. If
  /// [ListTile.isThreeLine] is also true, the leading horizontal title gap
  /// is forced to 20.
  ///
  /// In both cases the horizontal tile padding is ignored.
  static const ListTileConstraint video =
    ListTileConstraint(
      maxSize: _videoSize,
      minimumTileHeight: _minimumTileHeightWithVideo,
      leadingHorizontalTitleGap: _videoHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: true,
      paddingCorrection: _noCorrection,
    );

  /// The same as [ListTileConstraint.standard]
  /// except the height is unconstrained.
  static const ListTileConstraint unconstrained =
    ListTileConstraint(
      maxSize: _infiniteSize,
      minimumTileHeight: _minimumTileHeightWithLeadingOrTrailingElement,
      leadingHorizontalTitleGap: _defaultHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: false,
      paddingCorrection: _noCorrection,
    );

  /// Constraints for an element with the given padding correction.
  ///
  /// Uses the same values as [ListTileConstraint.standard].
  static ListTileConstraint of(EdgeInsetsDirectional insets) {
    return ListTileConstraint(
      maxSize: _defaultSize,
      minimumTileHeight: _minimumTileHeightWithLeadingOrTrailingElement,
      leadingHorizontalTitleGap: _defaultHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: false,
      paddingCorrection: (Size widgetSize) => ListTilePaddingCorrection.of(insets),
    );
  }

  /// Constraints for an element with symmetric padding, such as an
  /// [IconButton].
  ///
  /// Uses the same values as [ListTileConstraint.standard] except it
  /// determines the padding at runtime by comparing the [correctedSize]
  /// to the actual widget size.
  static ListTileConstraint center(Size correctedSize) {
    return ListTileConstraint(
      maxSize: _defaultSize,
      minimumTileHeight: _minimumTileHeightWithLeadingOrTrailingElement,
      leadingHorizontalTitleGap: _defaultHorizontalTitleGap,
      trailingHorizontalTitleGap: _defaultHorizontalTitleGap,
      ignoreHorizontalTilePadding: false,
      paddingCorrection: (Size widgetSize) =>
          ListTilePaddingCorrection.of(EdgeInsetsDirectional.symmetric(
            horizontal: math.max(widgetSize.width - correctedSize.width, 0.0) / 2.0,
            vertical: math.max(widgetSize.height - correctedSize.height, 0.0) / 2.0,
          )),
    );
  }

  /// The maximum size of the leading or trailing element.
  /// Both height and width may be unconstrained.
  final Size Function({required bool isDense, required bool useMaterial3, required Offset densityAdjustment}) maxSize;

  /// The minimum height of the [ListTile] when the element is present.
  /// This is not used when there is no corresponding element.
  final double Function({required bool isDense, required bool useMaterial3, required bool isLeading, required ListTileLineCount numberOfLines}) minimumTileHeight;

  /// The padding between the element and the title when it is in the
  /// leading position. This conforms to the given [TextDirection].
  /// This is not used when there is no corresponding element.
  final double Function({required bool isThreeLine, required bool useMaterial3}) leadingHorizontalTitleGap;

  /// The padding between the element and the title when it is in the
  /// trailing position. This conforms to the given [TextDirection].
  ///
  /// This is not used when there is no corresponding element.
  final double Function({required bool isThreeLine, required bool useMaterial3}) trailingHorizontalTitleGap;

  /// A leading element is placed flush against the start of the [ListTile],
  /// and a trailing element is placed flush against the end the [ListTile].
  /// This conforms to the given [TextDirection].
  ///
  /// This is not used when there is no corresponding element.
  final bool ignoreHorizontalTilePadding;

  /// Used to treat the padding from [ListTile] as part or all of the padding
  /// from the leading or trailing element. The element will be rendered as if
  /// its size is reduced by the returned [ListTilePaddingCorrection].
  ///
  /// This is not used when there is no corresponding element.
  final ListTilePaddingCorrection Function(Size widgetSize) paddingCorrection;

  /// Create a copy of the ListTileLeadingTrailingConstraint with the given
  /// parameters.
  ListTileConstraint copyWith({
    Size Function({required bool isDense, required bool useMaterial3, required Offset densityAdjustment})? minSize,
    Size Function({required bool isDense, required bool useMaterial3, required Offset densityAdjustment})? maxSize,
    double Function({required bool isDense, required bool useMaterial3, required bool isLeading, required ListTileLineCount numberOfLines})? minimumTileHeight,
    double Function({required bool isThreeLine, required bool useMaterial3})? leadingHorizontalTitleGap,
    double Function({required bool isThreeLine, required bool useMaterial3})? trailingHorizontalTitleGap,
    bool? ignoreHorizontalTilePadding,
    ListTilePaddingCorrection Function(Size widgetSize)? paddingCorrection,
  }) {
    if (
      <Object?>[maxSize, minimumTileHeight, leadingHorizontalTitleGap,
        trailingHorizontalTitleGap, ignoreHorizontalTilePadding,
        paddingCorrection]
          .where((Object? e) => e != null)
          .isEmpty
    ) {
      return this;
    }

    return ListTileConstraint(
      maxSize: maxSize ?? this.maxSize,
      minimumTileHeight: minimumTileHeight ?? this.minimumTileHeight,
      leadingHorizontalTitleGap: leadingHorizontalTitleGap ?? this.leadingHorizontalTitleGap,
      trailingHorizontalTitleGap: trailingHorizontalTitleGap ?? this.trailingHorizontalTitleGap,
      ignoreHorizontalTilePadding: ignoreHorizontalTilePadding ?? this.ignoreHorizontalTilePadding,
      paddingCorrection: paddingCorrection ?? this.paddingCorrection,
    );
  }

  @override
  String toString() {
    switch (this) {
      case standard:
        return 'ListTileConstraint.standard';
      case icon24:
        return 'ListTileConstraint.icon24';
      case switchTile:
        return 'ListTileConstraint.switchTile';
      case avatar:
        return 'ListTileConstraint.avatar';
      case image:
        return 'ListTileConstraint.image';
      case video:
        return 'ListTileConstraint.video';
    }
    return 'ListTileConstraint()';
  }
}

/// A single fixed-height row that typically contains some text as well as
/// a leading or trailing icon.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=l8dj0yPBvgQ}
///
/// A list tile contains one to three lines of text optionally flanked by icons or
/// other widgets, such as check boxes. The icons (or other widgets) for the
/// tile are defined with the [leading] and [trailing] parameters. The first
/// line of text is not optional and is specified with [title]. The value of
/// [subtitle], which _is_ optional, will occupy the space allocated for an
/// additional line of text, or two lines if [isThreeLine] is true. If [dense]
/// is true then the overall height of this tile and the size of the
/// [DefaultTextStyle]s that wrap the [title] and [subtitle] widget are reduced.
///
/// It is the responsibility of the caller to ensure that [title] and [overline]
/// do not wrap, and to ensure that [subtitle] doesn't wrap
/// (if [isThreeLine] is false) or wraps to two lines (if it is true).
///
/// The heights of the [leading] and [trailing] widgets are constrained
/// according to the
/// [Material 2](https://m2.material.io/components/lists#specs) or
/// [Material 3](https://m3.material.io/components/lists/specs) spec,
/// determined by [ThemeData.useMaterial3].
/// An exception is made for one-line ListTiles for accessibility. Please
/// see the example below to see how to adhere to both Material spec and
/// accessibility requirements.
///
/// By default, the [leading] and [trailing] widgets can expand as far as they wish
/// horizontally, so ensure that they are properly constrained but are limited
/// to height of 56. This can be changed using [leadingConstraint] and [trailingConstraint].
///
/// In addition, [leadingConstraint] and [trailingConstraint] can be used to
/// correct padding offsets and enforce Material styles for [IconButton]s
/// avatar, images and video widgets. User specified [ListTileConstraint]s
/// can also be created.
///
/// List tiles are typically used in [ListView]s, or arranged in [Column]s in
/// [Drawer]s and [Card]s.
///
/// This widget requires a [Material] widget ancestor in the tree to paint
/// itself on, which is typically provided by the app's [Scaffold].
/// The [tileColor], [selectedTileColor], [focusColor], and [hoverColor]
/// are not painted by the [ListTile] itself but by the [Material] widget
/// ancestor. In this case, one can wrap a [Material] widget around the
/// [ListTile], e.g.:
///
/// {@tool snippet}
/// ```dart
/// const ColoredBox(
///   color: Colors.green,
///   child: Material(
///     child: ListTile(
///       title: Text('ListTile with red background'),
///       tileColor: Colors.red,
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// ## Performance considerations when wrapping [ListTile] with [Material]
///
/// Wrapping a large number of [ListTile]s individually with [Material]s
/// is expensive. Consider only wrapping the [ListTile]s that require it
/// or include a common [Material] ancestor where possible.
///
/// [ListTile] must be wrapped in a [Material] widget to animate [tileColor],
/// [selectedTileColor], [focusColor], and [hoverColor] as these colors
/// are not drawn by the list tile itself but by the material widget ancestor.
///
/// {@tool dartpad}
/// This example showcases how [ListTile] needs to be wrapped in a [Material]
/// widget to animate colors.
///
/// ** See code in examples/api/lib/material/list_tile/list_tile.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example uses a [ListView] to demonstrate different configurations of
/// [ListTile]s in [Card]s.
///
/// ![Different variations of ListTile](https://flutter.github.io/assets-for-api-docs/assets/material/list_tile.png)
///
/// ** See code in examples/api/lib/material/list_tile/list_tile.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows the creation of a [ListTile] using [ThemeData.useMaterial3] flag,
/// as described in: https://m3.material.io/components/lists/overview.
///
/// ** See code in examples/api/lib/material/list_tile/list_tile.2.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows [ListTile]'s [textColor] and [iconColor] can use
/// [MaterialStateColor] color to change the color of the text and icon
/// when the [ListTile] is enabled, selected, or disabled.
///
/// ** See code in examples/api/lib/material/list_tile/list_tile.3.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows [ListTile.titleAlignment] can be used to configure the
/// [leading] and [trailing] widgets alignment relative to the [title] and
/// [subtitle] widgets.
///
/// ** See code in examples/api/lib/material/list_tile/list_tile.4.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows [ListTileConstraints] can be used to
/// configure the [leading] and [trailing] widgets to make the list in the
/// Material 3 spec.
///
/// ** See code in examples/api/lib/material/list_tile/list_tile.5.dart **
/// {@end-tool}
///
/// {@tool snippet}
/// To use a [ListTile] within a [Row], it needs to be wrapped in an
/// [Expanded] widget. [ListTile] requires fixed width constraints,
/// whereas a [Row] does not constrain its children.
///
/// ```dart
/// const Row(
///   children: <Widget>[
///     Expanded(
///       child: ListTile(
///         leading: FlutterLogo(),
///         title: Text('These ListTiles are expanded '),
///       ),
///     ),
///     Expanded(
///       child: ListTile(
///         trailing: FlutterLogo(),
///         title: Text('to fill the available space.'),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// Tiles can be much more elaborate. Here is a tile which can be tapped, but
/// which is disabled when the `_act` variable is not 2. When the tile is
/// tapped, the whole row has an ink splash effect (see [InkWell]).
///
/// ```dart
/// ListTile(
///   leading: const Icon(Icons.flight_land),
///   title: const Text("Trix's airplane"),
///   subtitle: _act != 2 ? const Text('The airplane is only in Act II.') : null,
///   enabled: _act == 2,
///   onTap: () { /* react to the tile being tapped */ }
/// )
/// ```
/// {@end-tool}
///
/// To be accessible, tappable [leading] and [trailing] widgets have to
/// be at least 48x48 in size. However, to adhere to the Material spec,
/// [trailing] and [leading] widgets in one-line ListTiles should visually be
/// at most 32 ([dense]: true) or 40 ([dense]: false) in height, which may
/// conflict with the accessibility requirement.
///
/// For this reason, a one-line ListTile allows the height of [leading]
/// and [trailing] widgets to be constrained by the height of the ListTile.
/// This allows for the creation of tappable [leading] and [trailing] widgets
/// that are large enough, but it is up to the developer to ensure that
/// their widgets follow the Material spec.
///
/// {@tool snippet}
///
/// Here is an example of a one-line, non-[dense] ListTile with a
/// tappable leading widget that adheres to accessibility requirements and
/// the Material spec. To adjust the use case below for a one-line, [dense]
/// ListTile, adjust the vertical padding to 8.0.
///
/// ```dart
/// ListTile(
///   leading: GestureDetector(
///     behavior: HitTestBehavior.translucent,
///     onTap: () {},
///     child: Container(
///       width: 48,
///       height: 48,
///       padding: const EdgeInsets.symmetric(vertical: 4.0),
///       alignment: Alignment.center,
///       child: const CircleAvatar(),
///     ),
///   ),
///   title: const Text('title'),
///   dense: false,
/// )
/// ```
/// {@end-tool}
///
/// ## The ListTile layout isn't exactly what I want
///
/// If the way ListTile pads and positions its elements isn't quite what
/// you're looking for, it's easy to create custom list items with a
/// combination of other widgets, such as [Row]s and [Column]s.
///
/// {@tool dartpad}
/// Here is an example of a custom list item that resembles a YouTube-related
/// video list item created with [Expanded] and [Container] widgets.
///
/// ![Custom list item a](https://flutter.github.io/assets-for-api-docs/assets/widgets/custom_list_item_a.png)
///
/// ** See code in examples/api/lib/material/list_tile/custom_list_item.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// Here is an example of an article list item with multiline titles and
/// subtitles. It utilizes [Row]s and [Column]s, as well as [Expanded] and
/// [AspectRatio] widgets to organize its layout.
///
/// ![Custom list item b](https://flutter.github.io/assets-for-api-docs/assets/widgets/custom_list_item_b.png)
///
/// ** See code in examples/api/lib/material/list_tile/custom_list_item.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ListTileTheme], which defines visual properties for [ListTile]s.
///  * [ListView], which can display an arbitrary number of [ListTile]s
///    in a scrolling list.
///  * [ReorderableList],  that allows the user to interactively reorder the
///    list items.
///  * [CircleAvatar], which shows an icon representing a person and is often
///    used as the [leading] element of a ListTile.
///  * [Card], which can be used with [Column] to show a few [ListTile]s.
///  * [Divider], which can be used to separate [ListTile]s.
///  * [ListTile.divideTiles], a utility for inserting [Divider]s in between [ListTile]s.
///  * [CheckboxListTile], [ExpansionTile], [RadioListTile], and [SwitchListTile], widgets
///    that combine [ListTile] with other controls.
///  * Material 3 [ListTile] specifications are referenced from <https://m3.material.io/components/lists/specs>
///    and Material 2 [ListTile] specifications are referenced from <https://m2.material.io/components/lists#specs>
///  * Cookbook: [Use lists](https://flutter.dev/docs/cookbook/lists/basic-list)
///  * Cookbook: [Implement swipe to dismiss](https://flutter.dev/docs/cookbook/gestures/dismissible)
class ListTile extends StatelessWidget {
  /// Creates a list tile.
  ///
  /// If [isThreeLine] is true, then [overline] or [subtitle] must not be null.
  /// If [isThreeLine] is false, then only one of [overline] and [subtitle] must
  /// be not null.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  const ListTile({
    super.key,
    this.leading,
    this.title,
    this.overline,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.visualDensity,
    this.shape,
    this.style,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.titleTextStyle,
    this.overlineTextColor,
    this.overlineTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextColor,
    this.leadingAndTrailingTextStyle,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.mouseCursor,
    this.selected = false,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.focusNode,
    this.autofocus = false,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.titleAlignment,
    this.leadingConstraint,
    this.trailingConstraint,
  }) : assert(
         !(subtitle == null && isThreeLine),
         'ListTile.subtitle must be present when ListTile.isThreeLine == true',
       ),
       assert(
         !(subtitle != null && overline != null && !isThreeLine),
         'CheckboxListTile.subtitle and CheckboxListTile.overline must not be present '
           'together when CheckboxListTile.isThreeLine == false',
       );

  /// A widget to display before the title.
  ///
  /// Typically an [Icon] or a [CircleAvatar] widget.
  final Widget? leading;

  /// The primary content of the list tile.
  ///
  /// Typically a [Text] widget.
  ///
  /// This should not wrap. To enforce the single line limit, use
  /// [Text.maxLines].
  final Widget? title;

  /// Additional content displayed above the title.
  ///
  /// Typically a [Text] widget. This should not wrap.
  ///
  /// If [isThreeLine] is false, at most one of [ListTile.overline] and
  /// [ListTile.overline] can be present.
  ///
  /// The subtitle's default [TextStyle] depends on [TextTheme.labelSmall] except
  /// [TextStyle.color]. The [TextStyle.color] depends on the value of [enabled]
  /// and [selected].
  ///
  /// When [enabled] is false, the text color is set to [ThemeData.disabledColor].
  ///
  /// When [selected] is false, the text color is set to [ListTileThemeData.overlineTextColor].
  final Widget? overline;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  ///
  /// If [isThreeLine] is false, this should not wrap.
  ///
  /// If [isThreeLine] is false, at most one of [ListTile.overline] and
  /// [ListTile.overline] can be present.
  ///
  /// The subtitle's default [TextStyle] depends on [TextTheme.bodyMedium] except
  /// [TextStyle.color]. The [TextStyle.color] depends on the value of [enabled]
  /// and [selected].
  ///
  /// When [enabled] is false, the text color is set to [ThemeData.disabledColor].
  ///
  /// When [selected] is false, the text color is set to [ListTileTheme.textColor]
  /// if it's not null and to [TextTheme.bodySmall]'s color if [ListTileTheme.textColor]
  /// is null.
  final Widget? subtitle;

  /// A widget to display after the title.
  ///
  /// Typically an [Icon] widget.
  ///
  /// To show right-aligned metadata (assuming left-to-right reading order;
  /// left-aligned for right-to-left reading order), consider using a [Row] with
  /// [CrossAxisAlignment.baseline] alignment whose first item is [Expanded] and
  /// whose second child is the metadata text, instead of using the [trailing]
  /// property.
  final Widget? trailing;

  /// Whether this list tile is intended to display three lines of text.
  ///
  /// If true, then [overline] or [subtitle] must be non-null (since it is expected to give
  /// the second and third lines of text).
  ///
  /// If false, the list tile is treated as having one line if the [overline] or [subtitle] is
  /// null and treated as having two lines if the subtitle is non-null. It must only have
  /// one of [overline] or [subtitle].
  ///
  /// When using a [Text] widget for [title], [overline] and [subtitle], you can enforce
  /// line limits using [Text.maxLines].
  final bool isThreeLine;

  /// Whether this list tile is part of a vertically dense list.
  ///
  /// If this property is null then its value is based on [ListTileTheme.dense].
  ///
  /// Dense list tiles default to a smaller height.
  ///
  /// It is not recommended to set [dense] to true when [ThemeData.useMaterial3] is true.
  final bool? dense;

  /// Defines how compact the list tile's layout will be.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  ///
  /// See also:
  ///
  ///  * [ThemeData.visualDensity], which specifies the [visualDensity] for all
  ///    widgets within a [Theme].
  final VisualDensity? visualDensity;

  /// {@template flutter.material.ListTile.shape}
  /// Defines the tile's [InkWell.customBorder] and [Ink.decoration] shape.
  /// {@endtemplate}
  ///
  /// If this property is null then [ListTileThemeData.shape] is used. If that
  /// is also null then a rectangular [Border] will be used.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final ShapeBorder? shape;

  /// Defines the color used for icons and text when the list tile is selected.
  ///
  /// If this property is null then [ListTileThemeData.selectedColor]
  /// is used. If that is also null then [ColorScheme.primary] is used.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final Color? selectedColor;

  /// Defines the default color for [leading] and [trailing] icons.
  ///
  /// If this property is null and [selected] is false then [ListTileThemeData.iconColor]
  /// is used. If that is also null and [ThemeData.useMaterial3] is true, [ColorScheme.onSurfaceVariant]
  /// is used, otherwise if [ThemeData.brightness] is [Brightness.light], [Colors.black54] is used,
  /// and if [ThemeData.brightness] is [Brightness.dark], the value is null.
  ///
  /// If this property is null and [selected] is true then [ListTileThemeData.selectedColor]
  /// is used. If that is also null then [ColorScheme.primary] is used.
  ///
  /// If this color is a [MaterialStateColor] it will be resolved against
  /// [MaterialState.selected] and [MaterialState.disabled] states.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final Color? iconColor;

  /// Defines the text color for the [title], [subtitle], [leading], and [trailing].
  ///
  /// If this property is null and [selected] is false then [ListTileThemeData.textColor]
  /// is used. If that is also null then default text color is used for the [title], [subtitle]
  /// [leading], and [trailing]. Except for [subtitle], if [ThemeData.useMaterial3] is false,
  /// [TextTheme.bodySmall] is used.
  ///
  /// If this property is null and [selected] is true then [ListTileThemeData.selectedColor]
  /// is used. If that is also null then [ColorScheme.primary] is used.
  ///
  /// If this color is a [MaterialStateColor] it will be resolved against
  /// [MaterialState.selected] and [MaterialState.disabled] states.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final Color? textColor;

  /// The text style for ListTile's [title].
  ///
  /// If this property is null, then [ListTileThemeData.titleTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.bodyLarge]
  /// will be used. Otherwise, If ListTile style is [ListTileStyle.list],
  /// [TextTheme.titleMedium] will be used and if ListTile style is [ListTileStyle.drawer],
  /// [TextTheme.bodyLarge] will be used.
  final TextStyle? titleTextStyle;

  /// The text style for ListTile's [subtitle].
  ///
  /// If this property is null, then [ListTileThemeData.subtitleTextStyle] is used.
  /// If that is also null, [TextTheme.bodyMedium] will be used.
  final TextStyle? subtitleTextStyle;

  /// The color for ListTile's [overline].
  ///
  /// If this property is null, then [ListTileThemeData.overlineTextColor] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [ColorScheme.onSurfaceVariant]
  /// is used, otherwise if [ThemeData.brightness] is [Brightness.light], [Colors.black54] is used,
  /// and if [ThemeData.brightness] is [Brightness.dark], the value is null.
  final Color? overlineTextColor;

  /// The text style for ListTile's [overline].
  ///
  /// If this property is null, then [ListTileThemeData.overlineTextStyle] is used.
  /// If that is also null, [TextTheme.labelSmall] will be used.
  final TextStyle? overlineTextStyle;

  /// The color for ListTile's [leading] and [trailing].
  ///
  /// If this property is null, then [ListTileThemeData.overlineTextColor] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [ColorScheme.onSurfaceVariant]
  /// is used, otherwise if [ThemeData.brightness] is [Brightness.light], [Colors.black54] is used,
  /// and if [ThemeData.brightness] is [Brightness.dark], the value is null.
  final Color? leadingAndTrailingTextColor;

  /// The text style for ListTile's [leading] and [trailing].
  ///
  /// If this property is null, then [ListTileThemeData.leadingAndTrailingTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.labelSmall]
  /// will be used, otherwise [TextTheme.bodyMedium] will be used.
  final TextStyle? leadingAndTrailingTextStyle;

  /// Defines the font used for the [title].
  ///
  /// If this property is null then [ListTileThemeData.style] is used. If that
  /// is also null then [ListTileStyle.list] is used.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final ListTileStyle? style;

  /// The tile's internal padding.
  ///
  /// Insets a [ListTile]'s contents: its [leading], [title], [subtitle],
  /// and [trailing] widgets.
  ///
  /// If null, `EdgeInsets.symmetric(horizontal: 16.0)` is used.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether this list tile is interactive.
  ///
  /// If false, this list tile is styled with the disabled color from the
  /// current [Theme] and the [onTap] and [onLongPress] callbacks are
  /// inoperative.
  final bool enabled;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  /// Called when the user long-presses on this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback? onLongPress;

  /// {@macro flutter.material.inkwell.onFocusChange}
  final ValueChanged<bool>? onFocusChange;

  /// {@template flutter.material.ListTile.mouseCursor}
  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [MaterialStateProperty.resolve] is used for the following [MaterialState]s:
  ///
  ///  * [MaterialState.selected].
  ///  * [MaterialState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the value of [ListTileThemeData.mouseCursor] is used. If
  /// that is also null, then [MaterialStateMouseCursor.clickable] is used.
  ///
  /// See also:
  ///
  ///  * [MaterialStateMouseCursor], which can be used to create a [MouseCursor]
  ///    that is also a [MaterialStateProperty<MouseCursor>].
  final MouseCursor? mouseCursor;

  /// If this tile is also [enabled] then icons and text are rendered with the same color.
  ///
  /// By default the selected color is the theme's primary color. The selected color
  /// can be overridden with a [ListTileTheme].
  ///
  /// {@tool dartpad}
  /// Here is an example of using a [StatefulWidget] to keep track of the
  /// selected index, and using that to set the [selected] property on the
  /// corresponding [ListTile].
  ///
  /// ** See code in examples/api/lib/material/list_tile/list_tile.selected.0.dart **
  /// {@end-tool}
  final bool selected;

  /// The color for the tile's [Material] when it has the input focus.
  final Color? focusColor;

  /// The color for the tile's [Material] when a pointer is hovering over it.
  final Color? hoverColor;

  /// The color of splash for the tile's [Material].
  final Color? splashColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// {@template flutter.material.ListTile.tileColor}
  /// Defines the background color of `ListTile` when [selected] is false.
  ///
  /// If this property is null and [selected] is false then [ListTileThemeData.tileColor]
  /// is used. If that is also null and [selected] is true, [selectedTileColor] is used.
  /// When that is also null, the [ListTileTheme.selectedTileColor] is used, otherwise
  /// [Colors.transparent] is used.
  ///
  /// {@endtemplate}
  final Color? tileColor;

  /// Defines the background color of `ListTile` when [selected] is true.
  ///
  /// When the value if null, the [selectedTileColor] is set to [ListTileTheme.selectedTileColor]
  /// if it's not null and to [Colors.transparent] if it's null.
  final Color? selectedTileColor;

  /// {@template flutter.material.ListTile.enableFeedback}
  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// When null, the default value is true.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// The horizontal gap between the titles and the leading/trailing widgets.
  ///
  /// If null, then the value of [ListTileTheme.horizontalTitleGap] is used. If
  /// that is also null, then a default value of 16 is used.
  final double? horizontalTitleGap;

  /// The minimum padding on the top and bottom of the title and subtitle widgets.
  ///
  /// If null, then the value of [ListTileTheme.minVerticalPadding] is used. If
  /// that is also null, then a default value of 4 is used.
  final double? minVerticalPadding;

  /// The minimum width allocated for the [ListTile.leading] widget.
  ///
  /// If null, then the value of [ListTileTheme.minLeadingWidth] is used. If
  /// that is also null, then a default value of 40 is used.
  final double? minLeadingWidth;

  /// Defines how [ListTile.leading] and [ListTile.trailing]
  /// are vertically aligned relative to the [ListTile].
  ///
  /// If this property is null then [ListTileThemeData.titleAlignment]
  /// is used. If that is also null then [ListTileTitleAlignment.material3]
  /// is used if [ThemeData.useMaterial3] is true, otherwise [ListTileTitleAlignment.titleHeight]
  /// is used.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final ListTileTitleAlignment? titleAlignment;

  /// Defines how [leading] is constrained and aligned to the [ListTile].
  ///
  /// The default value is [ListTileConstraint.standard].
  final ListTileConstraint? leadingConstraint;

  /// Defines how [trailing] is constrained and aligned to the [ListTile].
  ///
  /// The default value is [ListTileConstraint.standard].
  final ListTileConstraint? trailingConstraint;

  /// Add a one pixel border in between each tile. If color isn't specified the
  /// [ThemeData.dividerColor] of the context's [Theme] is used.
  ///
  /// See also:
  ///
  ///  * [Divider], which you can use to obtain this effect manually.
  static Iterable<Widget> divideTiles({ BuildContext? context, required Iterable<Widget> tiles, Color? color }) {
    assert(color != null || context != null);
    tiles = tiles.toList();

    if (tiles.isEmpty || tiles.length == 1) {
      return tiles;
    }

    Widget wrapTile(Widget tile) {
      return DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(
            bottom: Divider.createBorderSide(context, color: color),
          ),
        ),
        child: tile,
      );
    }

    return <Widget>[
      ...tiles.take(tiles.length - 1).map(wrapTile),
      tiles.last,
    ];
  }

  bool _isDenseLayout(ThemeData theme, ListTileThemeData tileTheme) {
    return dense ?? tileTheme.dense ?? theme.listTileTheme.dense ?? false;
  }

  Color _tileBackgroundColor(ThemeData theme, ListTileThemeData tileTheme, ListTileThemeData defaults) {
    final Color? color = selected
      ? selectedTileColor ?? tileTheme.selectedTileColor ?? theme.listTileTheme.selectedTileColor
      : tileColor ?? tileTheme.tileColor ?? theme.listTileTheme.tileColor;
    return color ?? defaults.tileColor!;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
    final ListTileThemeData tileTheme = ListTileTheme.of(context);
    final ListTileStyle listTileStyle = style
      ?? tileTheme.style
      ?? theme.listTileTheme.style
      ?? ListTileStyle.list;
    final ListTileThemeData defaults = theme.useMaterial3
      ? _LisTileDefaultsM3(context)
      : _LisTileDefaultsM2(context, listTileStyle);
    final Set<MaterialState> states = <MaterialState>{
      if (!enabled) MaterialState.disabled,
      if (selected) MaterialState.selected,
    };

    Color? resolveColor(Color? explicitColor, Color? selectedColor, Color? enabledColor, [Color? disabledColor]) {
      return _IndividualOverrides(
        explicitColor: explicitColor,
        selectedColor: selectedColor,
        enabledColor: enabledColor,
        disabledColor: disabledColor,
      ).resolve(states);
    }

    final Color? effectiveIconColor = resolveColor(iconColor, selectedColor, iconColor)
      ?? resolveColor(tileTheme.iconColor, tileTheme.selectedColor, tileTheme.iconColor)
      ?? resolveColor(theme.listTileTheme.iconColor, theme.listTileTheme.selectedColor, theme.listTileTheme.iconColor)
      ?? resolveColor(defaults.iconColor, defaults.selectedColor, defaults.iconColor, theme.disabledColor);
    final Color? effectiveColor = resolveColor(textColor, selectedColor, textColor)
      ?? resolveColor(tileTheme.textColor, tileTheme.selectedColor, tileTheme.textColor)
      ?? resolveColor(theme.listTileTheme.textColor, theme.listTileTheme.selectedColor, theme.listTileTheme.textColor)
      ?? resolveColor(defaults.textColor, defaults.selectedColor, defaults.textColor, theme.disabledColor);
    final IconThemeData iconThemeData = IconThemeData(color: effectiveIconColor);
    final IconButtonThemeData iconButtonThemeData = IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: effectiveIconColor),
    );

    TextStyle? leadingAndTrailingStyle;
    if (leading != null || trailing != null) {
      leadingAndTrailingStyle = leadingAndTrailingTextStyle
        ?? tileTheme.leadingAndTrailingTextStyle
        ?? defaults.leadingAndTrailingTextStyle!;
      final Color? effectiveLeadingAndTrailingTextColor = resolveColor(leadingAndTrailingTextColor, selectedColor, leadingAndTrailingTextColor)
          ?? resolveColor(tileTheme.leadingAndTrailingTextColor, tileTheme.selectedColor, tileTheme.leadingAndTrailingTextColor)
          ?? resolveColor(theme.listTileTheme.leadingAndTrailingTextColor, theme.listTileTheme.selectedColor, theme.listTileTheme.leadingAndTrailingTextColor)
          ?? resolveColor(defaults.leadingAndTrailingTextColor, defaults.selectedColor, defaults.leadingAndTrailingTextColor, theme.disabledColor);
      leadingAndTrailingStyle = leadingAndTrailingStyle.copyWith(color: effectiveLeadingAndTrailingTextColor);
    }

    Widget? leadingIcon;
    if (leading != null) {
      leadingIcon = AnimatedDefaultTextStyle(
        style: leadingAndTrailingStyle!,
        duration: kThemeChangeDuration,
        child: leading!,
      );
    }

    TextStyle titleStyle = titleTextStyle
      ?? tileTheme.titleTextStyle
      ?? defaults.titleTextStyle!;
    final Color? titleColor = effectiveColor;
    titleStyle = titleStyle.copyWith(
      color: titleColor,
      fontSize: _isDenseLayout(theme, tileTheme) ? 13.0 : null,
    );
    final Widget titleText = AnimatedDefaultTextStyle(
      style: titleStyle,
      duration: kThemeChangeDuration,
      child: title ?? const SizedBox(),
    );

    Widget? subtitleText;
    TextStyle? subtitleStyle;
    if (subtitle != null) {
      subtitleStyle = subtitleTextStyle
        ?? tileTheme.subtitleTextStyle
        ?? defaults.subtitleTextStyle!;
      final Color? subtitleColor = effectiveColor ?? theme.textTheme.bodySmall!.color;
      subtitleStyle = subtitleStyle.copyWith(
        color: subtitleColor,
        fontSize: _isDenseLayout(theme, tileTheme) ? 12.0 : null,
      );
      subtitleText = AnimatedDefaultTextStyle(
        style: subtitleStyle,
        duration: kThemeChangeDuration,
        child: subtitle!,
      );
    }

    Widget? overlineText;
    TextStyle? overlineStyle;
    if (overline != null) {
      overlineStyle = overlineTextStyle
          ?? tileTheme.overlineTextStyle
          ?? defaults.overlineTextStyle!;
      final Color? effectiveOverlineTextColor = overlineTextColor
          ?? tileTheme.overlineTextColor
          ?? defaults.overlineTextColor;
      overlineStyle = overlineStyle.copyWith(
        color: effectiveOverlineTextColor,
        fontSize: _isDenseLayout(theme, tileTheme) ? 10.0 : null,
      );
      overlineText = AnimatedDefaultTextStyle(
        style: overlineStyle,
        duration: kThemeChangeDuration,
        child: overline!,
      );
    }

    Widget? trailingIcon;
    if (trailing != null) {
      trailingIcon = AnimatedDefaultTextStyle(
        style: leadingAndTrailingStyle!,
        duration: kThemeChangeDuration,
        child: trailing!,
      );
    }

    final ListTileConstraint effectiveLeadingConstraint =
      leading != null && leadingConstraint != null
        ? leadingConstraint!
        : ListTileConstraint.standard;
    final ListTileConstraint effectiveTrailingConstraint =
      trailing != null && trailingConstraint != null
        ? trailingConstraint!
        : ListTileConstraint.standard;

    final TextDirection textDirection = Directionality.of(context);
    final EdgeInsetsGeometry baseContentPadding = contentPadding
        ?? tileTheme.contentPadding
        ?? defaults.contentPadding!;
    final EdgeInsetsGeometry clamp =
      EdgeInsetsDirectional.only(
        start: effectiveLeadingConstraint.ignoreHorizontalTilePadding ? 0.0 : double.infinity,
        top: double.infinity,
        end: effectiveTrailingConstraint.ignoreHorizontalTilePadding ? 0.0 : double.infinity,
        bottom: double.infinity,
      );
    final EdgeInsetsDirectional effectiveContentPadding = baseContentPadding
        .toDirectional(textDirection)
        .clamp(EdgeInsets.zero, clamp) // ignore_clamp_double_lint
        .toDirectional(textDirection);
    final EdgeInsets resolvedContentPadding = effectiveContentPadding.resolve(textDirection);

    // Show basic cursor when ListTile isn't enabled or gesture callbacks are null.
    final Set<MaterialState> mouseStates = <MaterialState>{
      if (!enabled || (onTap == null && onLongPress == null)) MaterialState.disabled,
    };
    final MouseCursor effectiveMouseCursor = MaterialStateProperty.resolveAs<MouseCursor?>(mouseCursor, mouseStates)
      ?? tileTheme.mouseCursor?.resolve(mouseStates)
      ?? MaterialStateMouseCursor.clickable.resolve(mouseStates);

    final ListTileTitleAlignment effectiveTitleAlignment = titleAlignment
      ?? tileTheme.titleAlignment
      ?? (theme.useMaterial3 ? ListTileTitleAlignment.material3 : ListTileTitleAlignment.titleHeight);

    // override the basic default behaviour for large tiles.
    double calculateDefaultMinVerticalPadding() {
      if (theme.useMaterial3 &&
          (isThreeLine || effectiveLeadingConstraint.ignoreHorizontalTilePadding
            || effectiveTrailingConstraint.ignoreHorizontalTilePadding)
      ) {
        return 12.0;
      }
      return defaults.minVerticalPadding!;
    }
    final double effectiveMinVerticalPadding = minVerticalPadding
        ?? tileTheme.minVerticalPadding
        ?? calculateDefaultMinVerticalPadding();

    final double effectiveLeadingHorizontalTitleGap = horizontalTitleGap
        ?? tileTheme.horizontalTitleGap
        ?? effectiveLeadingConstraint.leadingHorizontalTitleGap(
            isThreeLine: isThreeLine,
            useMaterial3: theme.useMaterial3,
          );
    final double effectiveTrailingHorizontalTitleGap = horizontalTitleGap
        ?? tileTheme.horizontalTitleGap
        ?? effectiveTrailingConstraint.leadingHorizontalTitleGap(
          isThreeLine: isThreeLine,
          useMaterial3: theme.useMaterial3,
        );

    return InkWell(
      customBorder: shape ?? tileTheme.shape,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      onFocusChange: onFocusChange,
      mouseCursor: effectiveMouseCursor,
      canRequestFocus: enabled,
      focusNode: focusNode,
      focusColor: focusColor,
      hoverColor: hoverColor,
      splashColor: splashColor,
      autofocus: autofocus,
      enableFeedback: enableFeedback ?? tileTheme.enableFeedback ?? true,
      child: Semantics(
        selected: selected,
        enabled: enabled,
        child: Ink(
          decoration: ShapeDecoration(
            shape: shape ?? tileTheme.shape ?? const Border(),
            color: _tileBackgroundColor(theme, tileTheme, defaults),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            minimum: resolvedContentPadding,
            child: IconTheme.merge(
              data: iconThemeData,
              child: IconButtonTheme(
                data: iconButtonThemeData,
                child: _ListTile(
                  leading: leadingIcon,
                  title: titleText,
                  overline: overlineText,
                  subtitle: subtitleText,
                  trailing: trailingIcon,
                  isDense: _isDenseLayout(theme, tileTheme),
                  visualDensity: visualDensity ?? tileTheme.visualDensity ?? theme.visualDensity,
                  isThreeLine: isThreeLine,
                  useMaterial3: theme.useMaterial3,
                  textDirection: textDirection,
                  titleBaselineType: titleStyle.textBaseline ?? defaults.titleTextStyle!.textBaseline!,
                  overlineBaselineType: overlineStyle?.textBaseline ?? defaults.overlineTextStyle!.textBaseline!,
                  subtitleBaselineType: subtitleStyle?.textBaseline ?? defaults.subtitleTextStyle!.textBaseline!,
                  leadingHorizontalTitleGap: effectiveLeadingHorizontalTitleGap,
                  trailingHorizontalTitleGap: effectiveTrailingHorizontalTitleGap,
                  minVerticalPadding: effectiveMinVerticalPadding,
                  minLeadingWidth: minLeadingWidth ?? tileTheme.minLeadingWidth ?? defaults.minLeadingWidth!,
                  titleAlignment: effectiveTitleAlignment,
                  leadingConstraint: effectiveLeadingConstraint,
                  trailingConstraint: effectiveTrailingConstraint,
                  parentPadding: effectiveContentPadding,
                ),
              ),
            ),
          ),
       ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('leading', leading, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('title', title, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('subtitle', subtitle, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('trailing', trailing, defaultValue: null));
    properties.add(FlagProperty('isThreeLine', value: isThreeLine, ifTrue:'THREE_LINE', ifFalse: 'TWO_LINE', showName: true, defaultValue: false));
    properties.add(FlagProperty('dense', value: dense, ifTrue: 'true', ifFalse: 'false', showName: true));
    properties.add(DiagnosticsProperty<VisualDensity>('visualDensity', visualDensity, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<ListTileStyle>('style', style, defaultValue: null));
    properties.add(ColorProperty('selectedColor', selectedColor, defaultValue: null));
    properties.add(ColorProperty('iconColor', iconColor, defaultValue: null));
    properties.add(ColorProperty('textColor', textColor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('titleTextStyle', titleTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('subtitleTextStyle', subtitleTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('leadingAndTrailingTextStyle', leadingAndTrailingTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('contentPadding', contentPadding, defaultValue: null));
    properties.add(FlagProperty('enabled', value: enabled, ifTrue: 'true', ifFalse: 'false', showName: true, defaultValue: true));
    properties.add(DiagnosticsProperty<Function>('onTap', onTap, defaultValue: null));
    properties.add(DiagnosticsProperty<Function>('onLongPress', onLongPress, defaultValue: null));
    properties.add(DiagnosticsProperty<MouseCursor>('mouseCursor', mouseCursor, defaultValue: null));
    properties.add(FlagProperty('selected', value: selected, ifTrue: 'true', ifFalse: 'false', showName: true, defaultValue: false));
    properties.add(ColorProperty('focusColor', focusColor, defaultValue: null));
    properties.add(ColorProperty('hoverColor', hoverColor, defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
    properties.add(FlagProperty('autofocus', value: autofocus, ifTrue: 'true', ifFalse: 'false', showName: true, defaultValue: false));
    properties.add(ColorProperty('tileColor', tileColor, defaultValue: null));
    properties.add(ColorProperty('selectedTileColor', selectedTileColor, defaultValue: null));
    properties.add(FlagProperty('enableFeedback', value: enableFeedback, ifTrue: 'true', ifFalse: 'false', showName: true));
    properties.add(DoubleProperty('horizontalTitleGap', horizontalTitleGap, defaultValue: null));
    properties.add(DoubleProperty('minVerticalPadding', minVerticalPadding, defaultValue: null));
    properties.add(DoubleProperty('minLeadingWidth', minLeadingWidth, defaultValue: null));
    properties.add(DiagnosticsProperty<ListTileTitleAlignment>('titleAlignment', titleAlignment, defaultValue: null));
    properties.add(DiagnosticsProperty<ListTileConstraint>('leadingConstraint', leadingConstraint, defaultValue: null));
    properties.add(DiagnosticsProperty<ListTileConstraint>('trailingConstraint', trailingConstraint, defaultValue: null));
  }
}

class _IndividualOverrides extends MaterialStateProperty<Color?> {
  _IndividualOverrides({
    this.explicitColor,
    this.enabledColor,
    this.selectedColor,
    this.disabledColor,
  });

  final Color? explicitColor;
  final Color? enabledColor;
  final Color? selectedColor;
  final Color? disabledColor;

  @override
  Color? resolve(Set<MaterialState> states) {
    if (explicitColor is MaterialStateColor) {
      return MaterialStateProperty.resolveAs<Color?>(explicitColor, states);
    }
    if (states.contains(MaterialState.disabled)) {
      return disabledColor;
    }
    if (states.contains(MaterialState.selected)) {
      return selectedColor;
    }
    return enabledColor;
  }
}

// Identifies the children of a _ListTileElement.
enum _ListTileSlot {
  leading,
  overline,
  title,
  subtitle,
  trailing,
}

class _ListTile extends SlottedMultiChildRenderObjectWidget<_ListTileSlot, RenderBox> {
  const _ListTile({
    this.leading,
    required this.title,
    this.overline,
    this.subtitle,
    this.trailing,
    required this.isThreeLine,
    required this.useMaterial3,
    required this.isDense,
    required this.visualDensity,
    required this.textDirection,
    required this.titleBaselineType,
    required this.leadingHorizontalTitleGap,
    required this.trailingHorizontalTitleGap,
    required this.minVerticalPadding,
    required this.minLeadingWidth,
    this.overlineBaselineType,
    this.subtitleBaselineType,
    required this.titleAlignment,
    required this.leadingConstraint,
    required this.trailingConstraint,
    required this.parentPadding,
  });

  final Widget? leading;
  final Widget title;
  final Widget? overline;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool useMaterial3;
  final bool isDense;
  final VisualDensity visualDensity;
  final TextDirection textDirection;
  final TextBaseline titleBaselineType;
  final TextBaseline? overlineBaselineType;
  final TextBaseline? subtitleBaselineType;
  final double leadingHorizontalTitleGap;
  final double trailingHorizontalTitleGap;
  final double minVerticalPadding;
  final double minLeadingWidth;
  final ListTileTitleAlignment titleAlignment;
  final ListTileConstraint leadingConstraint;
  final ListTileConstraint trailingConstraint;
  final EdgeInsetsDirectional parentPadding;

  @override
  Iterable<_ListTileSlot> get slots => _ListTileSlot.values;

  @override
  Widget? childForSlot(_ListTileSlot slot) {
    switch (slot) {
      case _ListTileSlot.leading:
        return leading;
      case _ListTileSlot.overline:
        return overline;
      case _ListTileSlot.title:
        return title;
      case _ListTileSlot.subtitle:
        return subtitle;
      case _ListTileSlot.trailing:
        return trailing;
    }
  }

  @override
  _RenderListTile createRenderObject(BuildContext context) {
    return _RenderListTile(
      isThreeLine: isThreeLine,
      useMaterial3: useMaterial3,
      isDense: isDense,
      visualDensity: visualDensity,
      textDirection: textDirection,
      titleBaselineType: titleBaselineType,
      overlineBaselineType: overlineBaselineType,
      subtitleBaselineType: subtitleBaselineType,
      leadingHorizontalTitleGap: leadingHorizontalTitleGap,
      trailingHorizontalTitleGap: trailingHorizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
      titleAlignment: titleAlignment,
      leadingConstraint: leadingConstraint,
      trailingConstraint: trailingConstraint,
      parentPadding: parentPadding,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderListTile renderObject) {
    renderObject
      ..isThreeLine = isThreeLine
      ..useMaterial3 = useMaterial3
      ..isDense = isDense
      ..visualDensity = visualDensity
      ..textDirection = textDirection
      ..titleBaselineType = titleBaselineType
      ..overlineBaselineType = overlineBaselineType
      ..subtitleBaselineType = subtitleBaselineType
      ..leadingHorizontalTitleGap = leadingHorizontalTitleGap
      ..trailingHorizontalTitleGap = trailingHorizontalTitleGap
      ..minLeadingWidth = minLeadingWidth
      ..minVerticalPadding = minVerticalPadding
      ..titleAlignment = titleAlignment
      ..leadingConstraint = leadingConstraint
      ..trailingConstraint = trailingConstraint
      ..parentPadding = parentPadding;
  }
}

class _RenderListTile extends RenderBox with SlottedContainerRenderObjectMixin<_ListTileSlot, RenderBox> {
  _RenderListTile({
    required bool isDense,
    required VisualDensity visualDensity,
    required bool isThreeLine,
    required bool useMaterial3,
    required TextDirection textDirection,
    required TextBaseline titleBaselineType,
    TextBaseline? overlineBaselineType,
    TextBaseline? subtitleBaselineType,
    required double leadingHorizontalTitleGap,
    required double trailingHorizontalTitleGap,
    required double minVerticalPadding,
    required double minLeadingWidth,
    required ListTileTitleAlignment titleAlignment,
    required ListTileConstraint leadingConstraint,
    required ListTileConstraint trailingConstraint,
    required EdgeInsetsDirectional parentPadding,
  }) : _isDense = isDense,
       _visualDensity = visualDensity,
       _isThreeLine = isThreeLine,
       _useMaterial3 = useMaterial3,
       _textDirection = textDirection,
       _titleBaselineType = titleBaselineType,
       _overlineBaselineType = overlineBaselineType,
       _subtitleBaselineType = subtitleBaselineType,
       _leadingHorizontalTitleGap = leadingHorizontalTitleGap,
       _trailingHorizontalTitleGap = trailingHorizontalTitleGap,
       _minVerticalPadding = minVerticalPadding,
       _minLeadingWidth = minLeadingWidth,
       _titleAlignment = titleAlignment,
       _leadingConstraint = leadingConstraint,
       _trailingConstraint = trailingConstraint,
       _parentPadding =  parentPadding;

  RenderBox? get leading => childForSlot(_ListTileSlot.leading);
  RenderBox? get title => childForSlot(_ListTileSlot.title);
  RenderBox? get overline => childForSlot(_ListTileSlot.overline);
  RenderBox? get subtitle => childForSlot(_ListTileSlot.subtitle);
  RenderBox? get trailing => childForSlot(_ListTileSlot.trailing);

  // The returned list is ordered for hit testing.
  @override
  Iterable<RenderBox> get children {
    return <RenderBox>[
      if (leading != null)
        leading!,
      if (title != null)
        title!,
      if (overline != null)
        overline!,
      if (subtitle != null)
        subtitle!,
      if (trailing != null)
        trailing!,
    ];
  }

  bool get isDense => _isDense;
  bool _isDense;
  set isDense(bool value) {
    if (_isDense == value) {
      return;
    }
    _isDense = value;
    markNeedsLayout();
  }

  VisualDensity get visualDensity => _visualDensity;
  VisualDensity _visualDensity;
  set visualDensity(VisualDensity value) {
    if (_visualDensity == value) {
      return;
    }
    _visualDensity = value;
    markNeedsLayout();
  }

  bool get isThreeLine => _isThreeLine;
  bool _isThreeLine;
  set isThreeLine(bool value) {
    if (_isThreeLine == value) {
      return;
    }
    _isThreeLine = value;
    markNeedsLayout();
  }

  bool get hasOverline => overline != null;
  bool get hasSubtitle => subtitle != null;
  bool get hasLeading => leading != null;
  bool get hasTrailing => trailing != null;

  ListTileLineCount get _numberOfLines {
    if (isThreeLine) {
      return ListTileLineCount.threeLine;
    } else if (hasOverline || hasSubtitle) {
      return ListTileLineCount.twoLine;
    }
    return ListTileLineCount.oneLine;
  }

  bool get useMaterial3 => _useMaterial3;
  bool _useMaterial3;
  set useMaterial3(bool value) {
    if (_useMaterial3 == value) {
      return;
    }
    _useMaterial3 = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  TextBaseline get titleBaselineType => _titleBaselineType;
  TextBaseline _titleBaselineType;
  set titleBaselineType(TextBaseline value) {
    if (_titleBaselineType == value) {
      return;
    }
    _titleBaselineType = value;
    markNeedsLayout();
  }

  TextBaseline? get subtitleBaselineType => _subtitleBaselineType;
  TextBaseline? _subtitleBaselineType;
  set subtitleBaselineType(TextBaseline? value) {
    if (_subtitleBaselineType == value) {
      return;
    }
    _subtitleBaselineType = value;
    markNeedsLayout();
  }

  TextBaseline? get overlineBaselineType => _overlineBaselineType;
  TextBaseline? _overlineBaselineType;
  set overlineBaselineType(TextBaseline? value) {
    if (_overlineBaselineType == value) {
      return;
    }
    _overlineBaselineType = value;
    markNeedsLayout();
  }

  double get leadingHorizontalTitleGap => _leadingHorizontalTitleGap;
  double _leadingHorizontalTitleGap;
  set leadingHorizontalTitleGap(double value) {
    if (_leadingHorizontalTitleGap == value) {
      return;
    }
    _leadingHorizontalTitleGap = value;
    markNeedsLayout();
  }
  double get _effectiveLeadingHorizontalTitleGap => _leadingHorizontalTitleGap + visualDensity.horizontal * 2.0;

  double get trailingHorizontalTitleGap => _trailingHorizontalTitleGap;
  double _trailingHorizontalTitleGap;
  set trailingHorizontalTitleGap(double value) {
    if (_trailingHorizontalTitleGap == value) {
      return;
    }
    _trailingHorizontalTitleGap = value;
    markNeedsLayout();
  }
  double get _effectiveTrailingHorizontalTitleGap => _trailingHorizontalTitleGap + visualDensity.horizontal * 2.0;

  double get minVerticalPadding => _minVerticalPadding;
  double _minVerticalPadding;

  set minVerticalPadding(double value) {
    if (_minVerticalPadding == value) {
      return;
    }
    _minVerticalPadding = value;
    markNeedsLayout();
  }

  double get minLeadingWidth => _minLeadingWidth;
  double _minLeadingWidth;

  set minLeadingWidth(double value) {
    if (_minLeadingWidth == value) {
      return;
    }
    _minLeadingWidth = value;
    markNeedsLayout();
  }

  ListTileTitleAlignment get titleAlignment => _titleAlignment;
  ListTileTitleAlignment _titleAlignment;
  set titleAlignment(ListTileTitleAlignment value) {
    if (_titleAlignment == value) {
      return;
    }
    _titleAlignment = value;
    markNeedsLayout();
  }

  ListTileConstraint get leadingConstraint => _leadingConstraint;
  ListTileConstraint _leadingConstraint;
  set leadingConstraint(ListTileConstraint value) {
    if (_leadingConstraint == value) {
      return;
    }
    _leadingConstraint = value;
    markNeedsLayout();
  }

  ListTileConstraint get trailingConstraint => _trailingConstraint;
  ListTileConstraint _trailingConstraint;
  set trailingConstraint(ListTileConstraint value) {
    if (_trailingConstraint == value) {
      return;
    }
    _trailingConstraint = value;
    markNeedsLayout();
  }

  EdgeInsetsDirectional get parentPadding => _parentPadding;
  EdgeInsetsDirectional _parentPadding;
  set parentPadding(EdgeInsetsDirectional value) {
    if (_parentPadding == value) {
      return;
    }
    _parentPadding = value;
    markNeedsLayout();
  }

  @override
  bool get sizedByParent => false;

  static double _minWidth(RenderBox? box, double height) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(height);
  }

  static double _maxWidth(RenderBox? box, double height) {
    return box == null ? 0.0 : box.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final double leadingWidth = leading != null
      ? math.max(leading!.getMinIntrinsicWidth(height), _minLeadingWidth)
        + _effectiveLeadingHorizontalTitleGap
      : 0.0;
    return leadingWidth
      + math.max(_minWidth(title, height), _minWidth(subtitle, height))
      + _maxWidth(trailing, height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double leadingWidth = leading != null
      ? math.max(leading!.getMaxIntrinsicWidth(height), _minLeadingWidth)
        + _effectiveTrailingHorizontalTitleGap
      : 0.0;
    return leadingWidth
      + math.max(_maxWidth(title, height), _maxWidth(subtitle, height))
      + _maxWidth(trailing, height);
  }

  double get _defaultTileHeight {
    final Offset baseDensity = visualDensity.baseSizeAdjustment;
    final ListTileLineCount numberOfLines = _numberOfLines;

    double baseDefaultTileHeight() {
      switch (numberOfLines) {
        case ListTileLineCount.oneLine: {
          // This does not follow the M2 spec which should have a base height
          // of 48 for one-line lists with no leading element
          return (isDense ? 48.0 : 56.0);
        }
        case ListTileLineCount.twoLine: {
          // This does not follow the M2 spec which should have a base height
          // of 64 for two-line lists with no leading element
          return (isDense ? 64.0 : 72.0);
        }
        case ListTileLineCount.threeLine: {
          return (isDense ? 76.0 : 88.0);
        }
      }
    }

    final double leadingTrailingForcedHeight =
      math.max(leading != null
        ? leadingConstraint.minimumTileHeight(isDense: isDense, useMaterial3: useMaterial3, isLeading: true, numberOfLines: numberOfLines)
        : 0.0,
      trailing != null
        ? trailingConstraint.minimumTileHeight(isDense: isDense, useMaterial3: useMaterial3, isLeading: false, numberOfLines: numberOfLines)
        : 0.0);

    return math.max(baseDefaultTileHeight(), leadingTrailingForcedHeight)
      + baseDensity.dy;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return math.max(
      _defaultTileHeight,
      math.max(
        title!.getMinIntrinsicHeight(width)
          + (overline?.getMinIntrinsicHeight(width) ?? 0.0)
          + (subtitle?.getMinIntrinsicHeight(width) ?? 0.0),
        math.max(
          leading?.getMinIntrinsicHeight(width) ?? 0.0,
          trailing?.getMinIntrinsicHeight(width) ?? 0.0
        ),
      ) + (useMaterial3 ? minVerticalPadding * 2 : 0.0),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeMinIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(title != null);
    final BoxParentData parentData = title!.parentData! as BoxParentData;
    return parentData.offset.dy + title!.getDistanceToActualBaseline(baseline)!;
  }

  static double? _boxBaseline(RenderBox box, TextBaseline baseline) {
    return box.getDistanceToBaseline(baseline);
  }

  static Size _layoutBox(RenderBox? box, BoxConstraints constraints) {
    if (box == null) {
      return Size.zero;
    }
    box.layout(constraints, parentUsesSize: true);
    return box.size;
  }

  static void _positionBox(RenderBox box, Offset offset) {
    final BoxParentData parentData = box.parentData! as BoxParentData;
    parentData.offset = offset;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(
      reason: 'Layout requires baseline metrics, which are only available after a full layout.',
    ));
    return Size.zero;
  }

  // All of the dimensions below were taken from the Material Design spec:
  // Material 2: https://m2.material.io/components/lists#specs
  // Material 3: https://m3.material.io/components/lists/specs
  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final Offset densityAdjustment = visualDensity.baseSizeAdjustment;

    final BoxConstraints maxLeadingHeightConstraint = BoxConstraints.loose(
      leadingConstraint.maxSize(isDense: isDense, useMaterial3: useMaterial3, densityAdjustment: densityAdjustment),
    );
    final BoxConstraints maxTrailingHeightConstraint = BoxConstraints.loose(
      trailingConstraint.maxSize(isDense: isDense, useMaterial3: useMaterial3, densityAdjustment: densityAdjustment),
    );
    final BoxConstraints looseConstraints = constraints.loosen();
    final BoxConstraints leadingConstraints = looseConstraints.enforce(maxLeadingHeightConstraint);
    final BoxConstraints trailingConstraints = looseConstraints.enforce(maxTrailingHeightConstraint);

    final double tileWidth = looseConstraints.maxWidth;
    final Size leadingSize = _layoutBox(leading, leadingConstraints);
    final Size trailingSize = _layoutBox(trailing, trailingConstraints);

    assert(
      tileWidth != leadingSize.width || tileWidth == 0.0,
      'Leading widget consumes entire tile width. Please use a sized widget, '
      'or consider replacing ListTile with a custom widget '
      '(see https://api.flutter.dev/flutter/material/ListTile-class.html#material.ListTile.4)',
    );
    assert(
      tileWidth != trailingSize.width || tileWidth == 0.0,
      'Trailing widget consumes entire tile width. Please use a sized widget, '
      'or consider replacing ListTile with a custom widget '
      '(see https://api.flutter.dev/flutter/material/ListTile-class.html#material.ListTile.4)',
    );

    final ListTilePaddingCorrection leadingPaddingCorrection
      = _leadingConstraint.paddingCorrection(leadingSize);
    final double leadingTitleGap = _effectiveLeadingHorizontalTitleGap;
    final double leadingStart = math.max(
      hasLeading ? -leadingPaddingCorrection.start : 0.0,
      -_parentPadding.start,
    );
    final double leadingEnd = leadingStart + leadingSize.width;
    final double effectiveLeadingEnd = hasLeading
      ? math.max(
          leadingStart
            + leadingSize.width
            - math.min(leadingPaddingCorrection.end, leadingTitleGap),
          _minLeadingWidth,
        )
      : 0.0;

    final ListTilePaddingCorrection trailingPaddingCorrection
      = _trailingConstraint.paddingCorrection(trailingSize);
    final double trailingTitleGap = _effectiveTrailingHorizontalTitleGap;
    final double trailingEnd = hasTrailing
      ? tileWidth + math.min(
      trailingPaddingCorrection.end,
        _parentPadding.end,
      )
      : tileWidth;
    final double trailingStart = trailingEnd - trailingSize.width;

    final double titleStart = hasLeading
        ? effectiveLeadingEnd + leadingTitleGap
        : 0.0;
    final double titleEnd = hasTrailing
      ? trailingStart - trailingTitleGap
        + math.min(trailingPaddingCorrection.start, trailingTitleGap)
      : tileWidth;

    final BoxConstraints textConstraints = looseConstraints.tighten(
      width: titleEnd - titleStart,
    );
    final Size titleSize = _layoutBox(title, textConstraints);
    final Size overlineSize = _layoutBox(overline, textConstraints);
    final Size subtitleSize = _layoutBox(subtitle, textConstraints);

    final double defaultTileHeight = _defaultTileHeight;

    final double totalLabelHeight = overlineSize.height + titleSize.height + subtitleSize.height;

    final double totalMinVerticalPadding = 2.0 * _minVerticalPadding;

    final double effectiveLeadingHeight = useMaterial3
      ? math.max(
          leadingSize.height,
          leadingSize.height
            - math.max(leadingPaddingCorrection.vertical - totalMinVerticalPadding, 0.0)
            + totalMinVerticalPadding,
        )
      : leadingSize.height;
    final double effectiveTrailingHeight = useMaterial3
      ? math.max(
          trailingSize.height,
          trailingSize.height
              - math.max(leadingPaddingCorrection.vertical - totalMinVerticalPadding, 0.0)
              + totalMinVerticalPadding,
        )
      : trailingSize.height;

    final double tileHeight = math.max(
      defaultTileHeight,
      math.max(
        totalLabelHeight + totalMinVerticalPadding,
        math.max(
          effectiveLeadingHeight,
          effectiveTrailingHeight,
        ),
      ),
    );

   // Text vertical alignment
    double? overlineY;
    double titleY;
    double? subtitleY;

    final ListTileLineCount numberOfLines = _numberOfLines;

    if (numberOfLines == ListTileLineCount.oneLine) {
      titleY = (tileHeight - titleSize.height) / 2.0;
    } else if (useMaterial3) {
      // Material 3 treats the text elements as a single block with
      // 0 padding between individual text blocks.
      if (
      isThreeLine ||
          tileHeight > 88.0 || (isDense && tileHeight > 76.0)
      ) {
        // Top align
        // There is an inconsistency in the spec. In the written component
        // it is tileHeight >= 88, but this conflicts with the one and two line
        // video layouts which are centred.
        overlineY = minVerticalPadding;
        titleY = overlineY + overlineSize.height;
        subtitleY = titleY + titleSize.height;
      } else {
        // Center
        overlineY = (tileHeight - totalLabelHeight) / 2.0;
        titleY = overlineY + overlineSize.height;
        subtitleY = titleY + titleSize.height;
      }
    } else if (tileHeight == totalLabelHeight + totalMinVerticalPadding) {
      // Short cut for Material 2 when all space is taken by the labels.
      // This saves a lot of shuffling about later.
      overlineY = minVerticalPadding;
      titleY = overlineY + overlineSize.height;
      subtitleY = titleY + titleSize.height;
    } else {
      // Material 2 vertically aligns text using each element's
      // baseline. Each baseline distances are from the top of the the tile and
      // are dependent on the which elements are present.
      double? titleBaseline;
      double? overlineBaseline;
      double? subtitleBaseline;
      switch (numberOfLines) {
        case ListTileLineCount.oneLine: break;
        case ListTileLineCount.twoLine: {
          if (leading == null) {
            if (hasOverline) {
              overlineBaseline = isDense ? 18.0 : 24.0;
              titleBaseline = isDense ? 38.0 : 44.0;
            } else {
              titleBaseline = isDense ? 22.0 : 28.0;
              subtitleBaseline = isDense ? 42.0 : 48.0;
            }
          } else {
            if (hasOverline) {
              overlineBaseline = isDense ? 22.0 : 28.0;
              titleBaseline = isDense ? 42.0 : 48.0;
            } else {
              titleBaseline = isDense ? 28.0 : 32.0;
              subtitleBaseline = isDense ? 48.0 : 52.0;
            }
          }
        }
        case ListTileLineCount.threeLine: {
          if (hasOverline) {
            overlineBaseline = isDense ? 18.0 : 28.0;
            titleBaseline = isDense ? 42.0 : 48.0;
            subtitleBaseline = isDense ? 64.0 : 70.0;
          } else {
            titleBaseline = isDense ? 22.0 : 28.0;
            subtitleBaseline = isDense ? 42.0 : 48.0;
          }
        }
      }

      titleY = titleBaseline! - _boxBaseline(title!, titleBaselineType)!;
      if (hasOverline) {
        overlineY = overlineBaseline! - _boxBaseline(overline!, overlineBaselineType!)!;

        // If the title and overline overlap, move the overline upwards by half
        // the overlap and the title down by the same amount.
        final double overlap = overlineY + overlineSize.height - titleY;
        if (overlap > 0.0) {
          overlineY -= overlap / 2.0;
          titleY += overlap / 2.0;
        }
      }

      final double bottomPaddingY = tileHeight - _minVerticalPadding;

      if (hasSubtitle) {
        assert(subtitleBaselineType != null);
        final double subtitleBoxBaseLine = _boxBaseline(subtitle!, subtitleBaselineType!)!;

        subtitleY = subtitleBaseline! - subtitleBoxBaseLine +
            visualDensity.vertical * 2.0;

        // If the title and subtitle overlap, move the title (and overline if
        // present) upwards by half the overlap and the subtitle down by
        // the same amount.
        final double titleOverlap = titleY + titleSize.height - subtitleY;
        if (titleOverlap > 0.0) {
          if (overlineY != null) {
            overlineY -= titleOverlap / 2.0;
          }
          titleY -= titleOverlap / 2.0;
          subtitleY += titleOverlap / 2.0;
        }
      }

      // Lower all title elements if they are above the top padding.
      // Raise all title elements if they are below the bottom padding.
      // Height has already been set to at least the height of the
      // title elements
      final double titleBottom = titleY + titleSize.height;
      final double subtitleBottom = (subtitleY ?? 0.0) + subtitleSize.height;
      if (overlineY != null && overlineY < _minVerticalPadding) {
        final double overlinePaddingOverlap = _minVerticalPadding - overlineY;
        overlineY += overlinePaddingOverlap;
        final double titleOverlineOverlap = math.max(overlineY + overlineSize.height - titleY, 0.0);
        titleY += titleOverlineOverlap;
        if (subtitleY != null) {
          final double subtitleTitleOverlap = math.max(titleBottom - subtitleY, 0.0);
          subtitleY += subtitleTitleOverlap;
        }
      } else if (titleY < _minVerticalPadding) {
        final double titlePaddingOverlap = _minVerticalPadding - titleY;
        titleY += titlePaddingOverlap;
        if (subtitleY != null) {
          final double titleSubtitleOverlap = math.max(titleBottom - subtitleY, 0.0);
          subtitleY += titleSubtitleOverlap;
        }
      }
      if (subtitleY != null && subtitleBottom > bottomPaddingY ) {
        final double subtitlePaddingOverlap = subtitleBottom - bottomPaddingY;
        subtitleY -= subtitlePaddingOverlap;
        final double titleSubtitleOverlap = math.max(titleBottom - subtitleY, 0.0);
        titleY -= titleSubtitleOverlap;
        if (overlineY != null) {
          final double titleOverlineOverlap = math.max(overlineY + overlineSize.height - titleY, 0.0);
          overlineY -= titleOverlineOverlap;
        }
      } else if (titleBottom > bottomPaddingY) {
        final double titlePaddingOverlap = titleBottom - bottomPaddingY;
        titleY -= titlePaddingOverlap;
        if (overlineY != null) {
          final double titleOverlineOverlap = math.max(overlineY + overlineSize.height - titleY, 0.0);
          overlineY -= titleOverlineOverlap;
        }
      }
    }

    // Leading and trailing widget vertical alignment
    final double leadingY;
    final double trailingY;

    switch (titleAlignment) {
      case ListTileTitleAlignment.threeLine: {
        if (isThreeLine) {
          leadingY = math.max(_minVerticalPadding - leadingPaddingCorrection.top, 0.0);
          trailingY = math.max(_minVerticalPadding - trailingPaddingCorrection.top, 0.0);
        } else {
          leadingY = (tileHeight - leadingSize.height + leadingPaddingCorrection.offsetY) / 2.0;
          trailingY = (tileHeight - trailingSize.height + leadingPaddingCorrection.offsetY) / 2.0;
        }
        break;
      }
      case ListTileTitleAlignment.material3: {
        // Material 3 uses simplified alignment - either center to top for all
        // elements
        if (
          isThreeLine ||
          tileHeight > 88.0 || (isDense && tileHeight > 76.0)
        ) {
          // Top align
          // There is an inconsistency on the spec. In the written component
          // it is tileHeight >= 88, but this conflicts with the one and two line
          // video layouts which are centred.
          leadingY = math.max(_minVerticalPadding - leadingPaddingCorrection.top, 0.0);
          trailingY = math.max(_minVerticalPadding - trailingPaddingCorrection.top, 0.0);
        } else {
          // Center
          leadingY = (tileHeight - leadingSize.height + leadingPaddingCorrection.offsetY) / 2.0;
          trailingY = (tileHeight - trailingSize.height + trailingPaddingCorrection.offsetY) / 2.0;
        }
        break;
      }
      case ListTileTitleAlignment.titleHeight: {
        // This attempts to implement the redlines for the vertical position of the
        // leading and trailing icons on the spec page:
        //   https://m2.material.io/components/lists#specs
        // The interpretation for these redlines is as follows:
        //  - For large tiles (> 72dp), both leading and trailing controls should be
        //    a fixed distance from top. As per guidelines this is set to 16dp.
        //  - For smaller tiles, trailing should always be centered. Leading can be
        //    centered or closer to the top. It should never be further than 16dp
        //    to the top.
        // Baseline offset of trailing supporting text is not supported.
        if (tileHeight > 72.0) {
          leadingY = math.max(16.0 - leadingPaddingCorrection.top, 0.0);
          trailingY = math.max(16.0 - trailingPaddingCorrection.top, 0.0);
        } else {
          leadingY = math.min((tileHeight - leadingSize.height - leadingPaddingCorrection.offsetY) / 2.0, 16.0);
          trailingY = (tileHeight - trailingSize.height - trailingPaddingCorrection.offsetY) / 2.0;
        }
        break;
      }
      case ListTileTitleAlignment.top: {
        leadingY = math.max(_minVerticalPadding - leadingPaddingCorrection.top, 0.0);
        trailingY = math.max(_minVerticalPadding - trailingPaddingCorrection.top, 0.0);
        break;
      }
      case ListTileTitleAlignment.center: {
        leadingY = (tileHeight - leadingSize.height + leadingPaddingCorrection.offsetY) / 2.0;
        trailingY = (tileHeight - trailingSize.height + trailingPaddingCorrection.offsetY) / 2.0;
        break;
      }
      case ListTileTitleAlignment.bottom: {
        leadingY = tileHeight - leadingSize.height - math.max(_minVerticalPadding - leadingPaddingCorrection.bottom, 0.0);
        trailingY = tileHeight - trailingSize.height - math.max(_minVerticalPadding - trailingPaddingCorrection.bottom, 0.0);
        break;
      }
    }

    // Widget positioning
    switch (textDirection) {
      case TextDirection.rtl: {
        if (hasLeading) {
          _positionBox(leading!, Offset(tileWidth - leadingEnd, leadingY));
        }
        if (hasOverline) {
          _positionBox(overline!, Offset(tileWidth - titleEnd, overlineY!));
        }
        _positionBox(title!, Offset(tileWidth - titleEnd, titleY));
        if (hasSubtitle) {
          _positionBox(subtitle!, Offset(tileWidth - titleEnd, subtitleY!));
        }
        if (hasTrailing) {
          _positionBox(trailing!, Offset(tileWidth - trailingEnd, trailingY));
        }
        break;
      }
      case TextDirection.ltr: {
        if (hasLeading) {
          _positionBox(leading!, Offset(leadingStart, leadingY));
        }
        if (hasOverline) {
          _positionBox(overline!, Offset(titleStart, overlineY!));
        }
        _positionBox(title!, Offset(titleStart, titleY));
        if (hasSubtitle) {
          _positionBox(subtitle!, Offset(titleStart, subtitleY!));
        }
        if (hasTrailing) {
          _positionBox(trailing!, Offset(trailingStart, trailingY));
        }
        break;
      }
    }

    size = constraints.constrain(Size(tileWidth, tileHeight));
    assert(size.width == constraints.constrainWidth(tileWidth));
    assert(size.height == constraints.constrainHeight(tileHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void doPaint(RenderBox? child) {
      if (child != null) {
        final BoxParentData parentData = child.parentData! as BoxParentData;
        context.paintChild(child, parentData.offset + offset);
      }
    }
    doPaint(leading);
    doPaint(overline);
    doPaint(title);
    doPaint(subtitle);
    doPaint(trailing);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    for (final RenderBox child in children) {
      final BoxParentData parentData = child.parentData! as BoxParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - parentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }
}

class _LisTileDefaultsM2 extends ListTileThemeData {
  _LisTileDefaultsM2(this.context, ListTileStyle style)
    : super(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        minLeadingWidth: 40,
        minVerticalPadding: 4,
        shape: const Border(),
        style: style,
      );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  Color? get tileColor =>  Colors.transparent;

  @override
  TextStyle? get titleTextStyle {
    switch (style!) {
      case ListTileStyle.drawer:
        return _textTheme.bodyLarge;
      case ListTileStyle.list:
        return _textTheme.titleMedium;
    }
  }

  @override
  Color? get overlineTextColor => _theme.colorScheme.onSurfaceVariant;

  @override
  TextStyle? get overlineTextStyle => _textTheme.labelSmall;

  @override
  TextStyle? get subtitleTextStyle => _textTheme.bodyMedium;

  @override
  Color? get leadingAndTrailingTextColor => _textTheme.bodyMedium?.color;

  @override
  TextStyle? get leadingAndTrailingTextStyle => _textTheme.bodyMedium;

  @override
  Color? get selectedColor => _theme.colorScheme.primary;

  @override
  Color? get iconColor {
    switch (_theme.brightness) {
      case Brightness.light:
        // For the sake of backwards compatibility, the default for unselected
        // tiles is Colors.black45 rather than colorScheme.onSurface.withAlpha(0x73).
        return Colors.black45;
      case Brightness.dark:
        return null; // null, Use current icon theme color
    }
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - LisTile

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_162

class _LisTileDefaultsM3 extends ListTileThemeData {
  _LisTileDefaultsM3(this.context)
    : super(
        contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 24.0),
        minLeadingWidth: 24,
        minVerticalPadding: 8,
        shape: const RoundedRectangleBorder(),
      );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  Color? get tileColor =>  Colors.transparent;

  @override
  TextStyle? get titleTextStyle => _textTheme.bodyLarge;

  @override
  Color? get overlineTextColor => _colors.onSurfaceVariant;

  @override
  TextStyle? get overlineTextStyle => _textTheme.labelSmall;

  @override
  TextStyle? get subtitleTextStyle => _textTheme.bodyMedium;

  @override
  Color? get leadingAndTrailingTextColor => _colors.onSurfaceVariant;

  @override
  TextStyle? get leadingAndTrailingTextStyle => _textTheme.labelSmall;

  @override
  Color? get selectedColor => _colors.primary;

  @override
  Color? get iconColor => _colors.onSurfaceVariant;
}

// END GENERATED TOKEN PROPERTIES - LisTile
