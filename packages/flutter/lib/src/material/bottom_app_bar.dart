// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';

// Examples can assume:
// Widget bottomAppBarContents;

/// A container that s typically ised with [Scaffold.bottomNavigationBar], and
/// can have a notch along the top that makes room for an overlapping
/// [FloatingActionButton].
///
/// Typically used with a [Scaffold] and a [FloatingActionButton].
///
/// ## Sample code
///
/// ```dart
/// new Scaffold(
///   bottomNavigationBar: new BottomAppBar(
///     color: Colors.white,
///     child: bottomAppBarContents,
///   ),
///   floatingActionButton: new FloatingActionButton(onPressed: null),
/// )
/// ```
///
/// See also:
///
///  * [ComputeNotch] a function used for creating a notch in a shape.
///  * [ScaffoldGeometry.floatingActionBarComputeNotch] the [ComputeNotch] used to
///    make a notch for the [FloatingActionButton]
///  * [FloatingActionButton] which the [BottomAppBar] makes a notch for.
///  * [AppBar] for a toolbar that is shown at the top of the screen.
class BottomAppBar extends StatefulWidget {
  /// Creates a bottom application bar.
  ///
  /// The [color] and [elevation] arguments must not be null.
  const BottomAppBar({
    Key key,
    this.color,
    this.elevation: 8.0,
    this.hasNotch: true,
    this.child,
  }) : assert(elevation != null),
       assert(elevation >= 0.0),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  ///
  /// Typically this the child will be a [Row], with the first child
  /// being an [IconButton] with the [Icons.menu] icon.
  final Widget child;

  /// The bottom app bar's background color.
  ///
  /// When null defaults to [ThemeData.bottomAppBarColor].
  final Color color;

  /// The z-coordinate at which to place this bottom app bar. This controls the
  /// size of the shadow below the bottom app bar.
  ///
  /// Defaults to 8, the appropriate elevation for bottom app bars.
  final double elevation;

  /// Whether to make a notch in the bottom app bar's shape for the floating
  /// action button.
  ///
  /// When true, the bottom app bar uses
  /// [ScaffoldGeometry.floatingActionButtonNotch] to make a notch along its
  /// top edge, where it is overlapped by the
  /// [ScaffoldGeometry.floatingActionButtonArea].
  ///
  /// When false, the shape of the bottom app bar is a rectangle.
  final bool hasNotch;

  @override
  State createState() => new _BottomAppBarState();
}

class _BottomAppBarState extends State<BottomAppBar> {
  ValueListenable<ScaffoldGeometry> geometryListenable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    geometryListenable = Scaffold.geometryOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final CustomClipper<Path> clipper = widget.hasNotch
      ? new _BottomAppBarClipper(geometry: geometryListenable)
      : const ShapeBorderClipper(shape: const RoundedRectangleBorder());
    return new PhysicalShape(
      clipper: clipper,
      elevation: widget.elevation,
      color: widget.color ?? Theme.of(context).bottomAppBarColor,
      child: new Material(
        type: MaterialType.transparency,
        child: widget.child == null
          ? null
          : new SafeArea(child: widget.child),
      ),
    );
  }
}

class _BottomAppBarClipper extends CustomClipper<Path> {
  const _BottomAppBarClipper({
    @required this.geometry
  }) : assert(geometry != null),
       super(reclip: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;

  @override
  Path getClip(Size size) {
    final Rect appBar = Offset.zero & size;
    if (geometry.value.floatingActionButtonArea == null ||
        geometry.value.floatingActionButtonNotch == null) {
      return new Path()..addRect(appBar);
    }

    // button is the floating action button's bounding rectangle in the
    // coordinate system that origins at the appBar's top left corner.
    final Rect button = geometry.value.floatingActionButtonArea
      .translate(0.0, geometry.value.bottomNavigationBarTop * -1.0);

    final ComputeNotch computeNotch = geometry.value.floatingActionButtonNotch;
    return new Path()
      ..moveTo(appBar.left, appBar.top)
      ..addPath(
        computeNotch(
          appBar,
          button,
          new Offset(appBar.left, appBar.top),
          new Offset(appBar.right, appBar.top)
        ),
        Offset.zero
      )
      ..lineTo(appBar.right, appBar.top)
      ..lineTo(appBar.right, appBar.bottom)
      ..lineTo(appBar.left, appBar.bottom)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    if (oldClipper.runtimeType != _BottomAppBarClipper)
      return true;

    final _BottomAppBarClipper typedOldClipper = oldClipper;
    return typedOldClipper.geometry != geometry;
  }
}
