// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bottom_app_bar_theme.dart';
import 'elevation_overlay.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';

// Examples can assume:
// late Widget bottomAppBarContents;

/// A container that is typically used with [Scaffold.bottomNavigationBar], and
/// can have a notch along the top that makes room for an overlapping
/// [FloatingActionButton].
///
/// Typically used with a [Scaffold] and a [FloatingActionButton].
///
/// {@tool snippet}
/// ```dart
/// Scaffold(
///   bottomNavigationBar: BottomAppBar(
///     color: Colors.white,
///     child: bottomAppBarContents,
///   ),
///   floatingActionButton: const FloatingActionButton(onPressed: null),
/// )
/// ```
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows the [BottomAppBar], which can be configured to have a notch using the
/// [BottomAppBar.shape] property. This also includes an optional [FloatingActionButton], which illustrates
/// the [FloatingActionButtonLocation]s in relation to the [BottomAppBar].
///
/// ** See code in examples/api/lib/material/bottom_app_bar/bottom_app_bar.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [NotchedShape] which calculates the notch for a notched [BottomAppBar].
///  * [FloatingActionButton] which the [BottomAppBar] makes a notch for.
///  * [AppBar] for a toolbar that is shown at the top of the screen.
class BottomAppBar extends StatefulWidget {
  /// Creates a bottom application bar.
  ///
  /// The [clipBehavior] argument defaults to [Clip.none] and must not be null.
  /// Additionally, [elevation] must be non-negative.
  ///
  /// If [color], [elevation], or [shape] are null, their [BottomAppBarTheme] values will be used.
  /// If the corresponding [BottomAppBarTheme] property is null, then the default
  /// specified in the property's documentation will be used.
  const BottomAppBar({
    Key? key,
    this.color,
    this.elevation,
    this.shape,
    this.clipBehavior = Clip.none,
    this.notchMargin = 4.0,
    this.child,
  }) : assert(elevation == null || elevation >= 0.0),
       assert(notchMargin != null),
       assert(clipBehavior != null),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  ///
  /// Typically this the child will be a [Row], with the first child
  /// being an [IconButton] with the [Icons.menu] icon.
  final Widget? child;

  /// The bottom app bar's background color.
  ///
  /// If this property is null then [BottomAppBarTheme.color] of
  /// [ThemeData.bottomAppBarTheme] is used. If that's null then
  /// [ThemeData.bottomAppBarColor] is used.
  final Color? color;

  /// The z-coordinate at which to place this bottom app bar relative to its
  /// parent.
  ///
  /// This controls the size of the shadow below the bottom app bar. The
  /// value is non-negative.
  ///
  /// If this property is null then [BottomAppBarTheme.elevation] of
  /// [ThemeData.bottomAppBarTheme] is used. If that's null, the default value
  /// is 8.
  final double? elevation;

  /// The notch that is made for the floating action button.
  ///
  /// If this property is null then [BottomAppBarTheme.shape] of
  /// [ThemeData.bottomAppBarTheme] is used. If that's null then the shape will
  /// be rectangular with no notch.
  final NotchedShape? shape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  final Clip clipBehavior;

  /// The margin between the [FloatingActionButton] and the [BottomAppBar]'s
  /// notch.
  ///
  /// Not used if [shape] is null.
  final double notchMargin;

  @override
  State createState() => _BottomAppBarState();
}

class _BottomAppBarState extends State<BottomAppBar> {
  late ValueListenable<ScaffoldGeometry> geometryListenable;
  final GlobalKey materialKey = GlobalKey();
  static const double _defaultElevation = 8.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    geometryListenable = Scaffold.geometryOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final BottomAppBarTheme babTheme = BottomAppBarTheme.of(context);
    final NotchedShape? notchedShape = widget.shape ?? babTheme.shape;
    final CustomClipper<Path> clipper = notchedShape != null
      ? _BottomAppBarClipper(
          geometry: geometryListenable,
          shape: notchedShape,
          materialKey: materialKey,
          notchMargin: widget.notchMargin,
        )
      : const ShapeBorderClipper(shape: RoundedRectangleBorder());
    final double elevation = widget.elevation ?? babTheme.elevation ?? _defaultElevation;
    final Color color = widget.color ?? babTheme.color ?? Theme.of(context).bottomAppBarColor;
    final Color effectiveColor = ElevationOverlay.applyOverlay(context, color, elevation);
    return PhysicalShape(
      clipper: clipper,
      elevation: elevation,
      color: effectiveColor,
      clipBehavior: widget.clipBehavior,
      child: Material(
        key: materialKey,
        type: MaterialType.transparency,
        child: widget.child == null
          ? null
          : SafeArea(child: widget.child!),
      ),
    );
  }
}

class _BottomAppBarClipper extends CustomClipper<Path> {
  const _BottomAppBarClipper({
    required this.geometry,
    required this.shape,
    required this.materialKey,
    required this.notchMargin,
  }) : assert(geometry != null),
       assert(shape != null),
       assert(notchMargin != null),
       super(reclip: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;
  final NotchedShape shape;
  final GlobalKey materialKey;
  final double notchMargin;

  // Returns the top of the BottomAppBar in global coordinates.
  //
  // If the Scaffold's bottomNavigationBar was specified, then we can use its
  // geometry value, otherwise we compute the location based on the AppBar's
  // Material widget.
  double get bottomNavigationBarTop {
    final double? bottomNavigationBarTop = geometry.value.bottomNavigationBarTop;
    if (bottomNavigationBarTop != null)
      return bottomNavigationBarTop;
    final RenderBox? box = materialKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero).dy ?? 0;
  }

  @override
  Path getClip(Size size) {
    // button is the floating action button's bounding rectangle in the
    // coordinate system whose origin is at the appBar's top left corner,
    // or null if there is no floating action button.
    final Rect? button = geometry.value.floatingActionButtonArea?.translate(0.0, bottomNavigationBarTop * -1.0);
    return shape.getOuterPath(Offset.zero & size, button?.inflate(notchMargin));
  }

  @override
  bool shouldReclip(_BottomAppBarClipper oldClipper) {
    return oldClipper.geometry != geometry
        || oldClipper.shape != shape
        || oldClipper.notchMargin != notchMargin;
  }
}
