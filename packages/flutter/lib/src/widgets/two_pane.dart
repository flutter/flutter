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
    this.padding,
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
  final EdgeInsets? padding;

  TextDirection _textDirection(BuildContext context) =>
      textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final DisplayFeature? displayFeature = _separatingDisplayFeature(mediaQuery);

    final EdgeInsets padding = this.padding ?? mediaQuery.padding;
    final Size size = Size(mediaQuery.size.width - padding.horizontal,
        mediaQuery.size.height - padding.vertical);
    final Rect? seam = displayFeature?.bounds.translate(
        -padding.left, -padding.top);


    late Axis _direction;
    late double _paneProportion;
    late Widget _pane1;
    late Widget _pane2;
    late Widget _delimiter;
    if (seam == null) {
      // There is no seam
      _direction = direction;
      _paneProportion = paneProportion;
      _pane1 = pane1;
      _pane2 = pane2;
      _delimiter = Container();
    } else if (seam.width < seam.height) {
      // Seam is tall. Panels are one left and one right
      _direction = Axis.horizontal;
      _delimiter = Container(width: seam.size.width);
      _paneProportion = seam.left / (size.width - seam.width);
    } else {
      // Seam is wide. Panels are one above and one below
      _direction = Axis.vertical;
      _delimiter = Container(height: seam.size.height);
      _paneProportion = seam.top / (size.height - seam.height);
    }

    if (_direction == Axis.vertical) {
      _pane1 = MediaQuery(
        data: mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(bottom: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0),
          viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0),
          systemGestureInsets:
          mediaQuery.systemGestureInsets.copyWith(bottom: 0),
        ),
        child: pane1,
      );
      _pane2 = MediaQuery(
        data: mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(top: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(top: 0),
          viewInsets: mediaQuery.viewInsets.copyWith(top: 0),
          systemGestureInsets: mediaQuery.systemGestureInsets.copyWith(top: 0),
        ),
        child: pane2,
      );
    } else {
      _pane1 = MediaQuery(
        data: mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(right: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(right: 0),
          viewInsets: mediaQuery.viewInsets.copyWith(right: 0),
          systemGestureInsets:
          mediaQuery.systemGestureInsets.copyWith(right: 0),
        ),
        child: pane1,
      );
      _pane2 = MediaQuery(
        data: mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(left: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(left: 0),
          viewInsets: mediaQuery.viewInsets.copyWith(left: 0),
          systemGestureInsets: mediaQuery.systemGestureInsets.copyWith(left: 0),
        ),
        child: pane2,
      );
    }

    const int fractionBase = 1000000;
    return Flex(
      children: <Widget>[
        if (panePriority != TwoPanePriority.pane2)
          Expanded(
            flex: (fractionBase * _paneProportion).toInt(),
            child: _pane1,
          ),
        if (panePriority == TwoPanePriority.both)
          _delimiter,
        if (panePriority != TwoPanePriority.pane1)
          Expanded(
            flex: (fractionBase * (1 - _paneProportion)).toInt(),
            child: _pane2,
          ),
      ],
      direction: _direction,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      textDirection: _textDirection(context),
      verticalDirection: verticalDirection,
    );
  }

  DisplayFeature? _separatingDisplayFeature(MediaQueryData mediaQuery) {
    for (final DisplayFeature displayFeature in mediaQuery.displayFeatures) {
      final bool largeEnough = displayFeature.bounds.width >=
          mediaQuery.size.width ||
          displayFeature.bounds.height >= mediaQuery.size.height;
      final bool makesTwoVerticalAreas = displayFeature.bounds.top > 0 &&
          displayFeature.bounds.bottom < mediaQuery.size.height;
      final bool makesTwoHorizontalAreas = displayFeature.bounds.left > 0 &&
          displayFeature.bounds.right < mediaQuery.size.width;
      final bool makesTwoAreas = makesTwoHorizontalAreas || makesTwoVerticalAreas;
      if (largeEnough && makesTwoAreas) {
        return displayFeature;
      }
    }
    return null;
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
