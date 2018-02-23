// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'ink_well.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';
import 'tooltip.dart';

// TODO(eseidel): This needs to change based on device size?
// http://material.google.com/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double _kSize = 56.0;
const double _kSizeMini = 40.0;

class _DefaultHeroTag {
  const _DefaultHeroTag();
  @override
  String toString() => '<default FloatingActionButton tag>';
}

// TODO(amirh): update the documentation once the BAB notch can be disabled.
/// A material design floating action button.
///
/// A floating action button is a circular icon button that hovers over content
/// to promote a primary action in the application. Floating action buttons are
/// most commonly used in the [Scaffold.floatingActionButton] field.
///
/// Use at most a single floating action button per screen. Floating action
/// buttons should be used for positive actions such as "create", "share", or
/// "navigate".
///
/// If the [onPressed] callback is null, then the button will be disabled and
/// will not react to touch.
///
/// If the floating action button is a descendant of a [Scaffold] that also has a
/// [BottomAppBar], the [BottomAppBar] will show a notch to accomodate the
/// [FloatingActionButton] when it overlaps the [BottomAppBar]. The notch's
/// shape is an arc for a circle whose radius is the floating action button's
/// radius plus [FloatingActionButton.notchMargin].
///
/// See also:
///
///  * [Scaffold]
///  * [RaisedButton]
///  * [FlatButton]
///  * <https://material.google.com/components/buttons-floating-action-button.html>
class FloatingActionButton extends StatefulWidget {
  /// Creates a floating action button.
  ///
  /// Most commonly used in the [Scaffold.floatingActionButton] field.
  const FloatingActionButton({
    Key key,
    this.child,
    this.tooltip,
    this.backgroundColor,
    this.heroTag: const _DefaultHeroTag(),
    this.elevation: 6.0,
    this.highlightElevation: 12.0,
    @required this.onPressed,
    this.mini: false,
    this.notchMargin: 4.0,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// Typically an [Icon].
  final Widget child;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String tooltip;

  /// The color to use when filling the button.
  ///
  /// Defaults to the accent color of the current theme.
  final Color backgroundColor;

  /// The tag to apply to the button's [Hero] widget.
  ///
  /// Defaults to a tag that matches other floating action buttons.
  ///
  /// Set this to null explicitly if you don't want the floating action button to
  /// have a hero tag.
  ///
  /// If this is not explicitly set, then there can only be one
  /// [FloatingActionButton] per route (that is, per screen), since otherwise
  /// there would be a tag conflict (multiple heroes on one route can't have the
  /// same tag). The material design specification recommends only using one
  /// floating action button per screen.
  final Object heroTag;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// The z-coordinate at which to place this button. This controls the size of
  /// the shadow below the floating action button.
  ///
  /// Defaults to 6, the appropriate elevation for floating action buttons.
  final double elevation;

  /// The z-coordinate at which to place this button when the user is touching
  /// the button. This controls the size of the shadow below the floating action
  /// button.
  ///
  /// Defaults to 12, the appropriate elevation for floating action buttons
  /// while they are being touched.
  ///
  /// See also:
  ///
  ///  * [elevation], the default elevation.
  final double highlightElevation;

  /// Controls the size of this button.
  ///
  /// By default, floating action buttons are non-mini and have a height and
  /// width of 56.0 logical pixels. Mini floating action buttons have a height
  /// and width of 40.0 logical pixels.
  final bool mini;

  /// The margin to keep around the floating action button when creating a
  /// notch for it.
  ///
  /// The notch is an arc of a circle with radius r+[notchMargin] where r is the
  /// radius of the floating action button. This expanded radius leaves a margin
  /// around the floating action button.
  ///
  /// See also:
  ///
  ///  * [BottomAppBar], a material design elements that shows a notch for the
  ///    floating action button.
  final double notchMargin;

  @override
  _FloatingActionButtonState createState() => new _FloatingActionButtonState();
}

class _FloatingActionButtonState extends State<FloatingActionButton> {
  bool _highlight = false;

  VoidCallback _clearComputeNotch;

  void _handleHighlightChanged(bool value) {
    setState(() {
      _highlight = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor = Colors.white;
    Color materialColor = widget.backgroundColor;
    if (materialColor == null) {
      final ThemeData themeData = Theme.of(context);
      materialColor = themeData.accentColor;
      iconColor = themeData.accentIconTheme.color;
    }

    Widget result;

    if (widget.child != null) {
      result = new Center(
        child: IconTheme.merge(
          data: new IconThemeData(color: iconColor),
          child: widget.child,
        ),
      );
    }

    if (widget.tooltip != null) {
      result = new Tooltip(
        message: widget.tooltip,
        child: result,
      );
    }

    result = new Material(
      color: materialColor,
      type: MaterialType.circle,
      elevation: _highlight ? widget.highlightElevation : widget.elevation,
      child: new Container(
        width: widget.mini ? _kSizeMini : _kSize,
        height: widget.mini ? _kSizeMini : _kSize,
        child: new Semantics(
          button: true,
          enabled: widget.onPressed != null,
          child: new InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: _handleHighlightChanged,
            child: result,
          ),
        ),
      ),
    );

    if (widget.heroTag != null) {
      result = new Hero(
        tag: widget.heroTag,
        child: result,
      );
    }

    return result;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clearComputeNotch = Scaffold.setFloatingActionButtonNotchFor(context, _computeNotch);
  }

  @override
  void deactivate() {
    if (_clearComputeNotch != null)
      _clearComputeNotch();
    super.deactivate();
  }

  Path _computeNotch(Rect host, Rect guest, Offset start, Offset end) {
    // The FAB's shape is a circle bounded by the guest rectangle.
    // So the FAB's radius is half the guest width.
    final double fabRadius = guest.width / 2.0;
    final double notchRadius = fabRadius + widget.notchMargin;

    assert(_notchAssertions(host, guest, start, end, fabRadius, notchRadius));

    // If there's no overlap between the guest's margin boundary and the host,
    // don't make a notch, just return a straight line from start to end.
    if (!host.overlaps(guest.inflate(widget.notchMargin)))
      return new Path()..lineTo(end.dx, end.dy);

    // We build a path for the notch from 3 segments:
    // Segment A - a Bezier curve from the host's top edge to segment B.
    // Segment B - an arc with radius notchRadius.
    // Segment C - a Bezier curver from segment B back to the host's top edge.
    //
    // A detailed explanation and the derivation of the formulas below is
    // available at: https://goo.gl/Ufzrqn

    const double s1 = 15.0;
    const double s2 = 1.0;

    final double r = notchRadius;
    final double a = -1.0 * r - s2;
    final double b = host.top - guest.center.dy;

    final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final double p2yA = math.sqrt(r * r - p2xA * p2xA);
    final double p2yB = math.sqrt(r * r - p2xB * p2xB);

    final List<Offset> p = new List<Offset>(6);

    // p0, p1, and p2 are the control points for segment A.
    p[0] = new Offset(a - s1, b);
    p[1] = new Offset(a, b);
    final double cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB ? new Offset(p2xA, p2yA) : new Offset(p2xB, p2yB);

    // p3, p4, and p5 are the control points for segment B, which is a mirror
    // of segment A around the y axis.
    p[3] = new Offset(-1.0 * p[2].dx, p[2].dy);
    p[4] = new Offset(-1.0 * p[1].dx, p[1].dy);
    p[5] = new Offset(-1.0 * p[0].dx, p[0].dy);

    // translate all points back to the absolute coordinate system.
    for (int i = 0; i < p.length; i += 1)
      p[i] += guest.center;

    return new Path()
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(
        p[3],
        radius: new Radius.circular(notchRadius),
        clockwise: false,
      )
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(end.dx, end.dy);
  }

  bool _notchAssertions(Rect host, Rect guest, Offset start, Offset end,
    double fabRadius, double notchRadius) {
    if (end.dy != host.top)
      throw new FlutterError(
        'The notch of the floating action button must end at the top edge of the host.\n'
        'The notch\'s path end point: $end is not in the top edge of $host'
      );

    if (start.dy != host.top)
      throw new FlutterError(
        'The notch of the floating action button must start at the top edge of the host.\n'
        'The notch\'s path start point: $start is not in the top edge of $host'
      );

    if (guest.center.dx - notchRadius < start.dx)
      throw new FlutterError(
        'The notch\'s path start point must be to the left of the floating action button.\n'
        'Start point was $start, guest was $guest, notchMargin was ${widget.notchMargin}.'
      );

    if (guest.center.dx + notchRadius > end.dx)
      throw new FlutterError(
        'The notch\'s end point must be to the right of the floating action button.\n'
        'End point was $start, notch was $guest, notchMargin was ${widget.notchMargin}.'
      );

    return true;
  }
}
