// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'media_query.dart';
import 'container.dart';

/// A widget that displays 2 children side-by-side or one below the other, while
/// also avoiding any hinge or fold that the screen might contain.
///
///  * By "hinge" we mean any [ui.DisplayFeature] reported by [MediaQueryData.displayFeatures]
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
/// For narrow screens where you want to display only one pane, you can use [singlePane]
/// to pick either [TwoPaneSinglePane.pane1] or [TwoPaneSinglePane.pane2].
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
///  * [ui.DisplayFeature] and [MediaQueryData.displayFeatures], to further
///  understand display features, such as hinge areas
class TwoPane extends StatelessWidget {
  /// First pane, which can sit on the left for left to right layouts,
  /// or at the top for top to bottom layouts.
  /// If [singlePane] is [TwoPaneSinglePane.pane1], this is the only pane visible.
  final Widget pane1;

  /// Second pane, which can sit on the right for left to right layouts,
  /// or at the bottom for top to bottom layouts.
  /// If [singlePane] is [TwoPaneSinglePane.pane2], this is the only pane visible.
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
  /// Defaults to [TwoPaneSinglePane.both]
  final TwoPaneSinglePane singlePane;

  const TwoPane({
    Key? key,
    required this.pane1,
    required this.pane2,
    this.paneProportion = 0.5,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.direction = Axis.horizontal,
    this.singlePane = TwoPaneSinglePane.both,
  }) : super(key: key);

  TextDirection _textDirection(BuildContext context) =>
      textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    Size size = mediaQuery.size;
    ui.DisplayFeature? displayFeature;
    for (final e in mediaQuery.displayFeatures) {
      if (e.bounds.width >= size.width || e.bounds.height >= size.height) {
        displayFeature = e;
        break;
      }
    }
    Rect? seam = displayFeature?.bounds;

    late Axis _direction;
    late double _paneProportion;
    late Widget _pane1;
    late Widget _pane2;
    late Widget _delimiter;
    late Rect _pane1Bounds;
    late Rect _pane2Bounds;
    if (seam == null) {
      // There is no seam
      _direction = direction;
      _paneProportion = paneProportion;
      _pane1 = pane1;
      _pane2 = pane2;
      _delimiter = Container();
      if (direction == Axis.horizontal) {
        _pane1Bounds =
            Rect.fromLTWH(0, 0, size.width * _paneProportion, size.height);
        _pane2Bounds = Rect.fromLTWH(
            _pane1Bounds.width, 0, size.width - _pane1Bounds.width, size.height);
      } else {
        _pane1Bounds =
            Rect.fromLTWH(0, 0, size.width, size.height * _paneProportion);
        _pane2Bounds = Rect.fromLTWH(
            0, _pane1Bounds.height, size.width, size.height - _pane1Bounds.height);
      }
    } else if (seam.width < seam.height) {
      // Seam is tall. Panels are one left and one right
      _direction = Axis.horizontal;
      _delimiter = Container(width: seam.size.width);
      _paneProportion = seam.left / (size.width - seam.width);
      _pane1Bounds = Rect.fromLTWH(0, 0, seam.left, size.height);
      _pane2Bounds =
          Rect.fromLTWH(seam.right, 0, size.width - seam.right, size.height);
    } else {
      // Seam is wide. Panels are one above and one below
      _direction = Axis.vertical;
      _delimiter = Container(height: seam.size.height);
      _paneProportion = seam.top / (size.height - seam.height);
      _pane1Bounds = Rect.fromLTWH(0, 0, size.width, seam.top);
      _pane2Bounds =
          Rect.fromLTWH(0, seam.bottom, size.width, size.height - seam.bottom);
    }

    if (_direction == Axis.vertical) {
      _pane1 = MediaQuery(
        data: mediaQuery.copyWith(
          // size: _pane1Bounds.size,
          padding: mediaQuery.padding.copyWith(bottom: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0),
          viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0),
          systemGestureInsets:
          mediaQuery.systemGestureInsets.copyWith(bottom: 0),
          // displayFeatures: mediaQuery.displayFeatures
          //     .where((e) => e.bounds.overlaps(_pane1Bounds))
          //     .toList(),
        ),
        child: pane1,
      );
      _pane2 = MediaQuery(
        data: mediaQuery.copyWith(
          // size: _pane2Bounds.size,
          padding: mediaQuery.padding.copyWith(top: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(top: 0),
          viewInsets: mediaQuery.viewInsets.copyWith(top: 0),
          systemGestureInsets: mediaQuery.systemGestureInsets.copyWith(top: 0),
          // displayFeatures: mediaQuery.displayFeatures
          //     .where((e) => e.bounds.overlaps(_pane2Bounds))
          //     .toList(),
        ),
        child: pane2,
      );
    } else {
      _pane1 = MediaQuery(
        data: mediaQuery.copyWith(
          // size: _pane1Bounds.size,
          padding: mediaQuery.padding.copyWith(right: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(right: 0),
          viewInsets: mediaQuery.viewInsets.copyWith(right: 0),
          systemGestureInsets:
          mediaQuery.systemGestureInsets.copyWith(right: 0),
          // displayFeatures: mediaQuery.displayFeatures
          //     .where((e) => e.bounds.overlaps(_pane1Bounds))
          //     .toList(),
        ),
        child: pane1,
      );
      _pane2 = MediaQuery(
        data: mediaQuery.copyWith(
          // size: _pane2Bounds.size,
          padding: mediaQuery.padding.copyWith(left: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(left: 0),
          viewInsets: mediaQuery.viewInsets.copyWith(left: 0),
          systemGestureInsets: mediaQuery.systemGestureInsets.copyWith(left: 0),
          // displayFeatures: mediaQuery.displayFeatures
          //     .where((e) => e.bounds.overlaps(_pane2Bounds))
          //     .toList(),
        ),
        child: pane2,
      );
    }

    return Flex(
      children: [
        if (singlePane != TwoPaneSinglePane.pane2)
          Expanded(
            flex: (100 * _paneProportion).toInt(),
            child: _pane1,
          ),
        if (singlePane == TwoPaneSinglePane.both)
          _delimiter,
        if (singlePane != TwoPaneSinglePane.pane1)
          Expanded(
            flex: (100 * (1 - _paneProportion)).toInt(),
            child: _pane2,
          ),
      ],
      direction: _direction,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      textDirection: _textDirection(context),
      verticalDirection: verticalDirection,
    );
  }
}

/// Describes which pane to show or if both should be shown.
enum TwoPaneSinglePane{
  both, pane1, pane2,
}
