// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show DisplayFeature;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

/// A widget that positions two panes side by side on uninterrupted screens or
/// on either side of a separating [DisplayFeature] on screens interrupted by a
/// separating [DisplayFeature].
///
/// A [DisplayFeature] separates the screen into sub-screens when both these
/// conditions are met:
///
///   * it obstructs the screen, meaning the area it occupies is not 0. Display
///     features of type [DisplayFeatureType.fold] can have height 0 or width 0
///     and not be obstructing the screen.
///   * it is at least as tall as the screen, producing a left and right
///     sub-screen or it is at least as wide as the screen, producing a top and
///     bottom sub-screen.
///
/// When positioning the two panes, [direction], [paneProportion] and
/// [panePriority] parameters are ignored and values are replaced in order to
/// avoid the separating [DisplayFeature]:
///
///   * On screens with a separating [DisplayFeature], the two panes are
///     positioned on each side of the feature. If the [DisplayFeature] splits
///     the screen left and right, [direction] is [Axis.horizontal]. Otherwise,
///     [direction] is [Axis.vertical]. The [paneProportion] and [panePriority]
///     parameters are also ignored and each pane occupies a sub-screen.
///   * On screens without a separating [DisplayFeature], [direction] is used
///     for deciding if the 2 panes are laid out horizontally or vertically and
///     [paneProportion] is used for deciding how much space each pane takes.
///
/// On screens that have multiple separating [DisplayFeature]s, [textDirection]
/// and [verticalDirection] parameters are used to decide which one is first and
/// is used as a separator between the two panes. If both horizontal and
/// vertical [DisplayFeature]s exist, the [direction] parameter is used to
/// ignore the [DisplayFeature]s that would conflict with it.
///
/// This widget is similar to [Flex] and also takes [textDirection] and
/// [verticalDirection] parameters, which are used for deciding in what order
/// the panes are laid out (e.g [TextDirection.ltr] would position [startPane]
/// on the left and [endPane] on the right).
///
/// The [panePriority] parameter can be used to display only one pane on screens
/// without any separating [DisplayFeature], by using [TwoPanePriority.start]
/// or [TwoPanePriority.end]. When [TwoPanePriority.both] is used or when the
/// screen has a separating [DisplayFeature], both panes are visible.
///
/// Similarly to [SafeArea] and [DisplayFeatureSubScreen], this widget assumes
/// there is no distance between it and the first [MediaQuery] ancestor. If this
/// is not true, the bounds of display features will not align with the
/// separation between the two panes. The [inset] parameter can be used to align
/// TwoPane with the real position of display features. The [inset] parameter is
/// the padding between TwoPane and the edges of the screen.
///
/// Pane widgets are wrapped in modified [MediaQuery] parents, removing padding,
/// insets and display features that no longer intersect with them.
///
/// If not provided, [textDirection] defaults to the ambient [Directionality].
/// If none are provided, then the widget asserts during build in debug mode.
/// The resolved [direction] of TwoPane is [Axis.horizontal] when there are
/// display features separating the screen into two horizontal sub-screens, in
/// which case the provided [direction] is ignored.
///
/// See also
///
///  * [DisplayFeature] and [MediaQueryData.displayFeatures], to further
///    understand display features
///  * [MediaQueryData.removeDisplayFeatures] which is used to remove padding,
///    insets and display features for each pane.
class TwoPane extends StatelessWidget {
  /// Create a layout that shows two pane widgets side by side.
  const TwoPane({
    Key? key,
    required this.startPane,
    required this.endPane,
    this.paneProportion = 0.5,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.direction = Axis.horizontal,
    this.panePriority = TwoPanePriority.both,
    this.inset = EdgeInsets.zero,
  }) : super(key: key);

  /// The first pane.
  ///
  /// On a horizontal layout, where [direction] is [Axis.horizontal]:
  ///
  ///   * The first pane is on the left when [textDirection] is
  ///     [TextDirection.ltr]
  ///   * The first pane is on the right when [textDirection] is
  ///     [TextDirection.rtl]
  ///
  /// On a vertical layout, where [direction] is [Axis.vertical]:
  ///
  ///   * The first pane is at the top when [verticalDirection] is
  ///     [VerticalDirection.down]
  ///   * The first pane is at the bottom when [verticalDirection] is
  ///     [VerticalDirection.up]
  ///
  /// If [panePriority] is [TwoPanePriority.start], this is the only pane
  /// visible.
  final Widget startPane;

  /// The second pane.
  ///
  /// On a horizontal layout, where [direction] is [Axis.horizontal]:
  ///
  ///   * The second pane is on the right when [textDirection] is
  ///     [TextDirection.ltr]
  ///   * The second pane is on the left when [textDirection] is
  ///     [TextDirection.rtl]
  ///
  /// On a vertical layout, where [direction] is [Axis.vertical]:
  ///
  ///   * The second pane is at the bottom when [verticalDirection] is
  ///     [VerticalDirection.down]
  ///   * The second pane is at the top when [verticalDirection] is
  ///     [VerticalDirection.up]
  ///
  /// If [panePriority] is [TwoPanePriority.end], this is the only pane
  /// visible.
  final Widget endPane;

  /// Proportion of the available space occupied by the first pane. The second
  /// pane takes over the rest of the screen.
  ///
  /// A value of 0.5 will make the 2 panes equal.
  ///
  /// This property is ignored is the screen is split into sub-screens by a
  /// [DisplayFeature], in which case each pane takes over one sub-screen.
  final double paneProportion;

  /// Same as [Flex.textDirection].
  ///
  /// If the resolved [direction] is [Axis.horizontal], [textDirection] defaults
  /// to the ambient [Directionality]. If none is provided, then the widget
  /// asserts during build in debug mode.
  final TextDirection? textDirection;

  /// Same as [Flex.verticalDirection].
  ///
  /// Defaults to [VerticalDirection.down].
  final VerticalDirection verticalDirection;

  /// Same as [Flex.direction].
  ///
  /// This property is ignored is the screen is split into sub-screens by a
  /// [DisplayFeature], in which case the direction is:
  ///
  ///   * [Axis.horizontal] when the sub-screens are located left and right.
  ///   * [Axis.vertical] when the sub-screens are located top and bottom.
  ///
  /// Defaults to [Axis.horizontal].
  final Axis direction;

  /// Whether to show only one pane and which one, or both.
  ///
  /// This property is ignored is the screen is split into sub-screens by a
  /// [DisplayFeature], in which case each pane takes over one sub-screen.
  ///
  /// Defaults to [TwoPanePriority.both].
  final TwoPanePriority panePriority;

  /// The padding between TwoPane and the edges of the screen.
  ///
  /// Used to align TwoPane with the real position of display features. It
  /// measures the distance between TwoPane and the ambient MediaQuery.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsets inset;

  TextDirection _resolveTextDirection(BuildContext context) =>
      textDirection ?? Directionality.of(context);

  @override
  Widget build(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(
      context,
      why: 'to determine what pane goes on the right or left side. The real '
          'direction of TwoPane is horizontal when there are display features '
          'separating the screen into two horizontal sub-screens, in which case '
          'the provided "direction" is ignored.',
      alternative: "Alternatively, consider specifying the 'textDirection' argument on the TwoPane.",
    ));
    final TextDirection resolvedTextDirection = _resolveTextDirection(context);

    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    late Rect? displayFeatureBounds;
    late final Size size;
    late final Axis resolvedDirection;
    late final int startPaneFlex;
    late final int endPaneFlex;
    late final Widget resolvedStartPane;
    late final Widget resolvedEndPane;
    late final Widget resolvedDelimiter;
    late final TwoPanePriority resolvedPanePriority;
    const int fractionBase = 1000000000000;

    if (mediaQuery == null){
      resolvedDirection = direction;
      resolvedPanePriority = panePriority;
    } else {
      final Rect position = inset.deflateRect(Offset.zero & mediaQuery.size);
      size = position.size;
      final Iterable<DisplayFeature> separatingDisplayFeatures = _separatingDisplayFeatures(mediaQuery.displayFeatures, position);
      resolvedDirection = _resolveDirection(separatingDisplayFeatures, position);
      final DisplayFeature? displayFeature = _firstDisplayFeature(separatingDisplayFeatures, resolvedDirection, resolvedTextDirection, verticalDirection);
      if (displayFeature == null) {
        displayFeatureBounds = null;
        resolvedPanePriority = panePriority;
      } else {
        displayFeatureBounds = displayFeature.bounds.intersect(position).shift(-position.topLeft);
        resolvedPanePriority = TwoPanePriority.both;
      }
    }

    if (mediaQuery == null || resolvedPanePriority != TwoPanePriority.both) {
      // Only showing one pane or there is no padding to remove from pane MediaQueries
      startPaneFlex = (fractionBase * paneProportion).toInt();
      endPaneFlex = fractionBase - startPaneFlex;
      resolvedStartPane = startPane;
      resolvedEndPane = endPane;
      resolvedDelimiter = const SizedBox();
    } else {
      // We are showing both panes
      switch (resolvedDirection){
        case Axis.horizontal: {
          // Panels are left and right.
          late final Rect seam;
          if (displayFeatureBounds == null) {
            // Simulate a display feature using paneProportion
            // This is then used to remove padding from pane MediaQueries
            seam = Rect.fromLTWH(paneProportion*size.width, 0, 0, size.height);
          } else {
            seam = displayFeatureBounds;
          }
          resolvedDelimiter = SizedBox(width: seam.size.width);
          final int leftFlex = (seam.left * fractionBase).toInt();
          final int rightFlex = ((size.width - seam.right) * fractionBase).toInt();
          final Rect leftScreen = Offset.zero & Size(seam.left, size.height);
          final Rect rightScreen = seam.topRight & Size(size.width - seam.right, size.height);
          switch (resolvedTextDirection){
            case TextDirection.ltr: {
              startPaneFlex = leftFlex;
              endPaneFlex = rightFlex;
              resolvedStartPane = MediaQuery(
                data: mediaQuery.removeDisplayFeatures(leftScreen),
                child: startPane,
              );
              resolvedEndPane = MediaQuery(
                data: mediaQuery.removeDisplayFeatures(rightScreen),
                child: endPane,
              );
            }
            break;
            case TextDirection.rtl: {
              startPaneFlex = rightFlex;
              endPaneFlex = leftFlex;
              resolvedStartPane = MediaQuery(
                data: mediaQuery.removeDisplayFeatures(rightScreen),
                child: startPane,
              );
              resolvedEndPane = MediaQuery(
                data: mediaQuery.removeDisplayFeatures(leftScreen),
                child: endPane,
              );
            }
            break;
          }
        }
        break;
        case Axis.vertical: {
          // Panels are top and bottom.
          late final Rect seam;
          if (displayFeatureBounds == null) {
            // Simulate a display feature using paneProportion
            // This is then used to remove padding from pane MediaQueries
            seam = Rect.fromLTWH(0, paneProportion*size.height, size.width, 0);
          } else {
            seam = displayFeatureBounds;
          }
          resolvedDelimiter = SizedBox(height: seam.size.height);
          final int topPane = (seam.top * fractionBase).toInt();
          final int bottomPane = ((size.height - seam.bottom) * fractionBase).toInt();
          final Rect topScreen = Offset.zero & Size(size.width, seam.top);
          final Rect bottomScreen = seam.bottomLeft & Size(size.width, size.height - seam.bottom);
          switch (verticalDirection) {
            case VerticalDirection.down: {
              startPaneFlex = topPane;
              endPaneFlex = bottomPane;
              resolvedStartPane = MediaQuery(
                data: mediaQuery.removeDisplayFeatures(topScreen),
                child: startPane,
              );
              resolvedEndPane = MediaQuery(
                data: mediaQuery.removeDisplayFeatures(bottomScreen),
                child: endPane,
              );
            }
            break;
            case VerticalDirection.up: {
              startPaneFlex = bottomPane;
              endPaneFlex = topPane;
              resolvedStartPane = MediaQuery(
                data: mediaQuery.removeDisplayFeatures(bottomScreen),
                child: startPane,
              );
              resolvedEndPane = MediaQuery(
                data: mediaQuery.removeDisplayFeatures(topScreen),
                child: endPane,
              );
            }
            break;
          }
        }
        break;
      }
    }

    return Flex(
      direction: resolvedDirection,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      textDirection: resolvedTextDirection,
      verticalDirection: verticalDirection,
      mainAxisAlignment: resolvedPanePriority != TwoPanePriority.both
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: <Widget>[
        if (resolvedPanePriority != TwoPanePriority.end)
          KeyedSubtree.wrap( Expanded(
            flex: startPaneFlex,
            child: resolvedStartPane,
          ), 1),
        if (resolvedPanePriority == TwoPanePriority.both)
          resolvedDelimiter,
        if (resolvedPanePriority != TwoPanePriority.start)
          KeyedSubtree.wrap( Expanded(
            flex: endPaneFlex,
            child: resolvedEndPane,
          ), 2),
      ],
    );
  }

  /// Determines what direction to use while laying out panes.
  ///
  /// It first looks for separating display features.
  ///
  ///   * If one is found, the direction is determined by how it splits the
  ///     screen into sub-screens.
  ///   * If multiple are found in the same direction, the same rule applies.
  ///   * If multiple are found in both directions, then the provided
  ///     [direction] is used.
  Axis _resolveDirection(Iterable<DisplayFeature> displayFeatures, Rect position) {
    final Iterable<DisplayFeature> separatingFeatures = _separatingDisplayFeatures(displayFeatures, position);
    bool verticalSubScreensExist = false;
    bool horizontalSubScreensExist = false;
    for (final DisplayFeature displayFeature in separatingFeatures){
      if (_splitsHorizontally(displayFeature.bounds, position)) {
        horizontalSubScreensExist = true;
      }
      if (_splitsVertically(displayFeature.bounds, position)) {
        verticalSubScreensExist = true;
      }
    }
    if (verticalSubScreensExist && !horizontalSubScreensExist) {
      return Axis.vertical;
    } else if (horizontalSubScreensExist && !verticalSubScreensExist) {
      return Axis.horizontal;
    } else {
      return direction;
    }
  }

  /// Retrieves the first [DisplayFeature] that splits the screen into separate
  /// sub-screens.
  ///
  /// In case there are multiple display features, [textDirection] or
  /// [verticalDirection] are used to determine the first one, according
  /// [direction].
  static DisplayFeature? _firstDisplayFeature(Iterable<DisplayFeature> displayFeatures,
      Axis direction, TextDirection textDirection, VerticalDirection verticalDirection) {
    if (displayFeatures.isEmpty) {
      return null;
    }
    DisplayFeature result = displayFeatures.first;
    for (final DisplayFeature displayFeature in displayFeatures){
      switch (direction) {
        case Axis.horizontal: {
          switch (textDirection) {
            case TextDirection.ltr: {
              if (displayFeature.bounds.left < result.bounds.left) {
                result = displayFeature;
              }
            }
            break;
            case TextDirection.rtl: {
              if (displayFeature.bounds.right > result.bounds.right) {
                result = displayFeature;
              }
            }
            break;
          }
        }
        break;
        case Axis.vertical: {
          switch (verticalDirection) {
            case VerticalDirection.down: {
              if (displayFeature.bounds.top < result.bounds.top) {
                result = displayFeature;
              }
            }
            break;
            case VerticalDirection.up: {
              if (displayFeature.bounds.bottom > result.bounds.bottom) {
                result = displayFeature;
              }
            }
            break;
          }
        }
        break;
      }
    }
    return result;
  }

  /// Returns only the display features that separate the screen into
  /// sub-screens.
  ///
  /// A [DisplayFeature] separates the screen into sub-screens when both these
  /// conditions are met:
  ///
  ///   * it obstructs the screen, meaning the area it occupies is not 0. Display
  ///     features of type [DisplayFeatureType.fold] can have height 0 or width 0
  ///     and not be obstructing the screen.
  ///   * it is at least as tall as the screen, producing a left and right
  ///     sub-screen or it is at least as wide as the screen, producing a top and
  ///     bottom sub-screen.
  static Iterable<DisplayFeature> _separatingDisplayFeatures(Iterable<DisplayFeature> displayFeatures, Rect position) {
    final List<DisplayFeature> result = <DisplayFeature>[];
    for (final DisplayFeature displayFeature in displayFeatures) {
      final Rect bounds = displayFeature.bounds;
      if (_splitsHorizontally(bounds, position) || _splitsVertically(bounds, position)) {
        result.add(displayFeature);
      }
    }
    return result;
  }

  static bool _splitsHorizontally(Rect bounds, Rect position){
    final bool tallEnough = bounds.top <= position.top && bounds.bottom >= position.bottom;
    final bool splitsHorizontally = bounds.left > position.left && bounds.right < position.right;
    return tallEnough && splitsHorizontally;
  }

  static bool _splitsVertically(Rect bounds, Rect position){
    final bool wideEnough = bounds.left <= position.left && bounds.right >= position.right;
    final bool splitsVertically = bounds.top > position.top && bounds.bottom < position.bottom;
    return wideEnough && splitsVertically;
  }
}

/// Describes if showing both panes at the same time or which one if only one is
/// shown.
enum TwoPanePriority {
  /// Show both panes
  both,

  /// Show only the first pane
  start,

  /// Show only the second pane
  end,
}
