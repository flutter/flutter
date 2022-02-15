// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show DisplayFeature;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'container.dart';
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
/// the panes are laid out (e.g [TextDirection.ltr] would position [pane1] on
/// the left and [pane2] on the right).
///
/// The [panePriority] parameter can be used to display only one pane on screens
/// without any separating [DisplayFeature], by using [TwoPanePriority.pane1]
/// or [TwoPanePriority.pane2]. When [TwoPanePriority.both] is used or when the
/// screen has a separating [DisplayFeature], both panes are visible.
///
/// Similarly to [SafeArea] and [DisplayFeatureSubScreen], this widget assumes
/// there is no added padding between it and the first [MediaQuery] ancestor.
/// Pane widgets are wrapped in modified [MediaQuery] parents, removing padding,
/// insets and display features that no longer intersect with them.
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
    required this.pane1,
    required this.pane2,
    this.paneProportion = 0.5,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.direction = Axis.horizontal,
    this.panePriority = TwoPanePriority.both,
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
  /// If [panePriority] is [TwoPanePriority.pane1], this is the only pane
  /// visible.
  final Widget pane1;

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
  /// If [panePriority] is [TwoPanePriority.pane2], this is the only pane
  /// visible.
  final Widget pane2;

  /// Proportion of the available space occupied by the first pane. The second
  /// pane takes over the rest of the screen.
  ///
  /// A value of 0.5 will make the 2 panes equal.
  ///
  /// This property is ignored is the screen is split into sub-screens by a
  /// [DisplayFeature], in which case each pane takes over one sub-screen.
  final double paneProportion;

  /// Same as [Flex.textDirection].
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

  TextDirection? _getTextDirection(BuildContext context) =>
      textDirection ?? Directionality.maybeOf(context);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    final DisplayFeature? displayFeature = _separatingDisplayFeature(mediaQuery);

    late Axis _direction;
    late int pane1Flex;
    late int pane2Flex;
    late Widget _pane1;
    late Widget _pane2;
    late Widget _delimiter;
    final TextDirection? _textDirection = _getTextDirection(context);
    const int fractionBase = 1000000000000;

    if (mediaQuery == null || displayFeature == null) {
      // The display is continuous, nothing is overridden.
      _direction = direction;
      pane1Flex = (fractionBase * paneProportion).toInt();
      pane2Flex = fractionBase - pane1Flex;
      _pane1 = pane1;
      _pane2 = pane2;
      _delimiter = Container();
    } else {
      // The display has a seam that splits it in two panels.
      final Size size = mediaQuery.size;
      final Rect seam = displayFeature.bounds;

      if (seam.width < seam.height) {
        // Seam is tall. Panels are left and right.
        _direction = Axis.horizontal;
        _delimiter = Container(width: seam.size.width);
        assert(_textDirection != null);
        final int leftPane = (seam.left * fractionBase).toInt();
        final int rightPane = ((size.width - seam.right) * fractionBase).toInt();
        if (_textDirection == TextDirection.ltr) {
          pane1Flex = leftPane;
          pane2Flex = rightPane;
        } else {
          pane1Flex = rightPane;
          pane2Flex = leftPane;
        }
      } else {
        // Seam is wide. Panels are above and below.
        _direction = Axis.vertical;
        _delimiter = Container(height: seam.size.height);
        final int topPane = (seam.top * fractionBase).toInt();
        final int bottomPane = ((size.height - seam.bottom) * fractionBase).toInt();
        if (verticalDirection == VerticalDirection.down) {
          pane1Flex = topPane;
          pane2Flex = bottomPane;
        } else {
          pane1Flex = bottomPane;
          pane2Flex = topPane;
        }
      }
    }

    if (mediaQuery==null || panePriority != TwoPanePriority.both) {
      _pane1 = pane1;
      _pane2 = pane2;
    } else if (_direction == Axis.vertical) {
      final bool pane1Top = verticalDirection == VerticalDirection.down;
      _pane1 = MediaQuery(
        data: _removeMediaQueryPaddingAndInset(
          mediaQuery: mediaQuery,
          removeBottom: pane1Top,
          removeTop: !pane1Top,
        ),
        child: pane1,
      );
      _pane2 = MediaQuery(
        data: _removeMediaQueryPaddingAndInset(
          mediaQuery: mediaQuery,
          removeBottom: !pane1Top,
          removeTop: pane1Top,
        ),
        child: pane2,
      );
    } else {
      assert(_textDirection != null);
      final bool pane1Left = _textDirection == TextDirection.ltr;
      _pane1 = MediaQuery(
        data: _removeMediaQueryPaddingAndInset(
          mediaQuery: mediaQuery,
          removeRight: pane1Left,
          removeLeft: !pane1Left,
        ),
        child: pane1,
      );
      _pane2 = MediaQuery(
        data: _removeMediaQueryPaddingAndInset(
          mediaQuery: mediaQuery,
          removeRight: !pane1Left,
          removeLeft: pane1Left,
        ),
        child: pane2,
      );
    }

    return Flex(
      direction: _direction,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      textDirection: _textDirection,
      verticalDirection: verticalDirection,
      mainAxisAlignment: panePriority != TwoPanePriority.both
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: <Widget>[
        if (panePriority != TwoPanePriority.pane2)
          Expanded(
            flex: pane1Flex,
            child: _pane1,
          ),
        if (panePriority == TwoPanePriority.both)
          _delimiter,
        if (panePriority != TwoPanePriority.pane1)
          Expanded(
            flex: pane2Flex,
            child: _pane2,
          ),
      ],
    );
  }

  DisplayFeature? _separatingDisplayFeature(MediaQueryData? mediaQuery) {
    if (mediaQuery == null) {
      return null;
    } else {
      for (final DisplayFeature displayFeature in mediaQuery.displayFeatures) {
        final bool largeEnough = displayFeature.bounds.width >=
            mediaQuery.size.width ||
            displayFeature.bounds.height >= mediaQuery.size.height;
        final bool makesTwoVerticalAreas = displayFeature.bounds.top > 0 &&
            displayFeature.bounds.bottom < mediaQuery.size.height;
        final bool makesTwoHorizontalAreas = displayFeature.bounds.left > 0 &&
            displayFeature.bounds.right < mediaQuery.size.width;
        final bool makesTwoAreas = makesTwoHorizontalAreas ||
            makesTwoVerticalAreas;
        if (largeEnough && makesTwoAreas) {
          return displayFeature;
        }
      }
      return null;
    }
  }

  MediaQueryData _removeMediaQueryPaddingAndInset({
    required MediaQueryData mediaQuery,
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
  }){
    return mediaQuery.copyWith(
      padding: mediaQuery.padding.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      viewPadding: mediaQuery.viewPadding.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      viewInsets: mediaQuery.viewInsets.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      systemGestureInsets: mediaQuery.systemGestureInsets.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
    );
  }
}

/// Describes which pane to show or if both should be shown.
enum TwoPanePriority {
  /// Show both panes
  both,

  /// Show only the first pane
  pane1,

  /// Show only the second pane
  pane2,
}
