// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show DisplayFeature;

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'container.dart';
import 'framework.dart';
import 'media_query.dart';

/// A widget that displays 2 children side-by-side or one below the other, while
/// also avoiding any hinge or fold that the screen might contain.
///
///  * By "hinge" we mean any [DisplayFeature] reported by [MediaQueryData.displayFeatures]
///  that completely splits the screen area in 2 parts. For phones with a
///  continuous screen that folds, the "fold" area is 0-width and does not visualy
///  create 2 separate screens.
///  * On screens with a hinge, the 2 panes are positioned on each side of the
///  hinge. In this case, both [paneProportion] and [direction] are ignored.
///  * On screens without a hinge, [paneProportion] is used for deciding how
///  much space each pane uses and [direction] is used for deciding if the 2
///  panes are laid out horizontally or vertically.
///
/// This widget is similar to [Flex], in that it also takes [textDirection] and
/// [verticalDirection] parameters, which are used for deciding in what order the
/// panes are laid out (e.g left to right would position pane 1 on the left and
/// pane 2 on the right).
///
/// For narrow screens where you want to display only one pane, you can use [panePriority]
/// to pick either [TwoPanePriority.pane1] or [TwoPanePriority.pane2].
///
/// In addition, this widget also wraps children in [MediaQuery] parents that
/// makes sense for their side of the screen. For example, let's consider a flip
/// phone with a notch at the top of the screen. The hinge is horizontal, so the
/// 2 halves of the screen are one at the top and one at the bottom. In this case
/// the top pane will have top padding in order to avoid the notch, but the bottom
/// pane does not have top padding, since it does not have the notch.
///
/// See also
///
///  * [DisplayFeature] and [MediaQueryData.displayFeatures], to further
///  understand display features, such as hinge areas
class TwoPane extends StatelessWidget {
  /// Create a layout that shows both child widgets or just one of them according
  /// to available space and device form factor.
  const TwoPane({
    Key? key,
    required this.pane1,
    required this.pane2,
    this.paneProportion = 0.5,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.direction = Axis.horizontal,
    this.panePriority = TwoPanePriority.both,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  /// First pane, which can sit on the left for left to right layouts,
  /// or at the top for top to bottom layouts.
  /// If [panePriority] is [TwoPanePriority.pane1], this is the only pane visible.
  final Widget pane1;

  /// Second pane, which can sit on the right for left to right layouts,
  /// or at the bottom for top to bottom layouts.
  /// If [panePriority] is [TwoPanePriority.pane2], this is the only pane visible.
  final Widget pane2;

  /// Proportion of the screen ocupied by the first pane. The second pane takes
  /// over the rest of the screen. A value of 0.5 will make the 2 panes equal.
  /// This property is ignored for displays with a hinge, in which case each
  /// pane takes over one screen.
  final double paneProportion;

  /// Same as [Flex.textDirection]
  final TextDirection? textDirection;

  /// Same as [Flex.verticalDirection]
  ///
  /// Defaults to [VerticalDirection.down]
  final VerticalDirection verticalDirection;

  /// Same as [Flex.direction]
  ///
  /// This property is ignored for displays with a hinge, in which case the
  /// direction is [Axis.horizontal] for vertical hinges and [Axis.vertical] for
  /// horizontal hinges.
  ///
  /// Defaults to [Axis.horizontal]
  final Axis direction;

  /// Whether to show only one pane and which one, or both. This is useful for
  /// defining behaviour on narrow devices, where the 2 panes cannot be shown at
  /// the same time.
  ///
  /// Defaults to [TwoPanePriority.both]
  final TwoPanePriority panePriority;

  /// The distance from the edge of the screen, used to determine how [TwoPane]
  /// intersects [MediaQueryData.displayFeatures].
  ///
  /// When [TwoPane] is not the root layout and the distance from the screen
  /// edge increases, the [padding] needs to take into account the extra space.
  ///
  /// For example, when TwoPane is the body of a Scaffold, the appbar adds extra
  /// spacing between TwoPane and the edge of the screen. If TwoPane is used
  /// with a [Axis.vertical] [direction], the separation between the two panes
  /// will not align with [DisplayFeature]s unless the [padding] also includes
  /// the height of the appbar.
  ///
  /// Defaults to [MediaQueryData.padding].
  final EdgeInsets padding;

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
      // final EdgeInsets padding = this.padding;
      final Size size = Size(
          mediaQuery.size.width - padding.horizontal,
          mediaQuery.size.height - padding.vertical);
      final Rect seam = displayFeature.bounds.translate(-padding.left, -padding.top);

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
