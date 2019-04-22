// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'scaffold.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'tooltip.dart';

const BoxConstraints _kSizeConstraints = BoxConstraints.tightFor(
  width: 56.0,
  height: 56.0,
);

const BoxConstraints _kMiniSizeConstraints = BoxConstraints.tightFor(
  width: 40.0,
  height: 40.0,
);

const BoxConstraints _kExtendedSizeConstraints = BoxConstraints(
  minHeight: 48.0,
  maxHeight: 48.0,
);

class _DefaultHeroTag {
  const _DefaultHeroTag();
  @override
  String toString() => '<default FloatingActionButton tag>';
}

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
/// See also:
///
///  * [Scaffold]
///  * [RaisedButton]
///  * [FlatButton]
///  * <https://material.google.com/components/buttons-floating-action-button.html>
class FloatingActionButton extends StatefulWidget {
  /// Creates a circular floating action button.
  ///
  /// The [elevation], [highlightElevation], [mini], [shape], and [clipBehavior]
  /// arguments must not be null.
  const FloatingActionButton({
    Key key,
    this.child,
    this.tooltip,
    this.foregroundColor,
    this.backgroundColor,
    this.heroTag = const _DefaultHeroTag(),
    this.elevation = 6.0,
    this.highlightElevation = 12.0,
    @required this.onPressed,
    this.mini = false,
    this.shape = const CircleBorder(),
    this.clipBehavior = Clip.none,
    this.materialTapTargetSize,
    this.isExtended = false,
  }) :  assert(elevation != null),
        assert(highlightElevation != null),
        assert(mini != null),
        assert(shape != null),
        assert(isExtended != null),
        _sizeConstraints = mini ? _kMiniSizeConstraints : _kSizeConstraints,
        super(key: key);

  /// Creates a wider [StadiumBorder] shaped floating action button with both
  /// an [icon] and a [label].
  ///
  /// The [label], [icon], [elevation], [highlightElevation], [clipBehavior]
  /// and [shape] arguments must not be null.
  FloatingActionButton.extended({
    Key key,
    this.tooltip,
    this.foregroundColor,
    this.backgroundColor,
    this.heroTag = const _DefaultHeroTag(),
    this.elevation = 6.0,
    this.highlightElevation = 12.0,
    @required this.onPressed,
    this.shape = const StadiumBorder(),
    this.isExtended = true,
    this.materialTapTargetSize,
    this.clipBehavior = Clip.none,
    @required Widget icon,
    @required Widget label,
  }) :  assert(elevation != null),
        assert(highlightElevation != null),
        assert(shape != null),
        assert(isExtended != null),
        assert(clipBehavior != null),
        _sizeConstraints = _kExtendedSizeConstraints,
        mini = false,
        child = _ChildOverflowBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(width: 16.0),
              icon,
              const SizedBox(width: 8.0),
              label,
              const SizedBox(width: 20.0),
            ],
          ),
        ),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// Typically an [Icon].
  final Widget child;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String tooltip;

  /// The default icon and text color.
  ///
  /// Defaults to [ThemeData.accentIconTheme.color] for the current theme.
  final Color foregroundColor;

  /// The color to use when filling the button.
  ///
  /// Defaults to [ThemeData.accentColor] for the current theme.
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
  /// and width of 40.0 logical pixels with a layout width and height of 48.0
  /// logical pixels.
  final bool mini;

  /// The shape of the button's [Material].
  ///
  /// The button's highlight and splash are clipped to this shape. If the
  /// button has an elevation, then its drop shadow is defined by this
  /// shape as well.
  final ShapeBorder shape;

  /// {@macro flutter.widgets.Clip}
  final Clip clipBehavior;

  /// True if this is an "extended" floating action button.
  ///
  /// Typically [extended] buttons have a [StadiumBorder] [shape]
  /// and have been created with the [FloatingActionButton.extended]
  /// constructor.
  ///
  /// The [Scaffold] animates the appearance of ordinary floating
  /// action buttons with scale and rotation transitions. Extended
  /// floating action buttons are scaled and faded in.
  final bool isExtended;

  /// Configures the minimum size of the tap target.
  ///
  /// Defaults to [ThemeData.materialTapTargetSize].
  ///
  /// See also:
  ///
  ///   * [MaterialTapTargetSize], for a description of how this affects tap targets.
  final MaterialTapTargetSize materialTapTargetSize;

  final BoxConstraints _sizeConstraints;

  @override
  _FloatingActionButtonState createState() => _FloatingActionButtonState();
}

class _FloatingActionButtonState extends State<FloatingActionButton> {
  bool _highlight = false;

  void _handleHighlightChanged(bool value) {
    setState(() {
      _highlight = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foregroundColor = widget.foregroundColor ?? theme.accentIconTheme.color;
    Widget result;

    if (widget.child != null) {
      result = IconTheme.merge(
        data: IconThemeData(
          color: foregroundColor,
        ),
        child: widget.child,
      );
    }

    result = RawMaterialButton(
      onPressed: widget.onPressed,
      onHighlightChanged: _handleHighlightChanged,
      elevation: _highlight ? widget.highlightElevation : widget.elevation,
      constraints: widget._sizeConstraints,
      materialTapTargetSize: widget.materialTapTargetSize ?? theme.materialTapTargetSize,
      fillColor: widget.backgroundColor ?? theme.accentColor,
      textStyle: theme.accentTextTheme.button.copyWith(
        color: foregroundColor,
        letterSpacing: 1.2,
      ),
      shape: widget.shape,
      clipBehavior: widget.clipBehavior,
      child: result,
    );

    if (widget.tooltip != null) {
      result = MergeSemantics(
        child: Tooltip(
          message: widget.tooltip,
          child: result,
        ),
      );
    }

    if (widget.heroTag != null) {
      result = Hero(
        tag: widget.heroTag,
        child: result,
      );
    }

    return result;
  }
}

// This widget's size matches its child's size unless its constraints
// force it to be larger or smaller. The child is centered.
//
// Used to encapsulate extended FABs whose size is fixed, using Row
// and MainAxisSize.min, to be as wide as their label and icon.
class _ChildOverflowBox extends SingleChildRenderObjectWidget {
  const _ChildOverflowBox({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  _RenderChildOverflowBox createRenderObject(BuildContext context) {
    return _RenderChildOverflowBox(
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderChildOverflowBox renderObject) {
    renderObject
      ..textDirection = Directionality.of(context);
  }
}

class _RenderChildOverflowBox extends RenderAligningShiftedBox {
  _RenderChildOverflowBox({
    RenderBox child,
    TextDirection textDirection,
  }) : super(child: child, alignment: Alignment.center, textDirection: textDirection);

  @override
  double computeMinIntrinsicWidth(double height) => 0.0;

  @override
  double computeMinIntrinsicHeight(double width) => 0.0;

  @override
  void performLayout() {
    if (child != null) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      size = Size(
        math.max(constraints.minWidth, math.min(constraints.maxWidth, child.size.width)),
        math.max(constraints.minHeight, math.min(constraints.maxHeight, child.size.height)),
      );
      alignChild();
    } else {
      size = constraints.biggest;
    }
  }
}
