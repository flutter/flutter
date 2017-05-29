// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';
import 'tooltip.dart';

// TODO(eseidel): This needs to change based on device size?
// http://material.google.com/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double _kSize = 56.0;
const double _kSizeMini = 40.0;
final Object _kDefaultHeroTag = new Object();

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
  /// Creates a floating action button.
  ///
  /// Most commonly used in the [Scaffold.floatingActionButton] field.
  const FloatingActionButton({
    Key key,
    @required this.child,
    this.tooltip,
    this.backgroundColor,
    this.heroTag,
    this.elevation: 6.0,
    this.highlightElevation: 12.0,
    @required this.onPressed,
    this.mini: false
  }) : super(key: key);

  /// The widget below this widget in the tree.
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

  @override
  _FloatingActionButtonState createState() => new _FloatingActionButtonState();
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
    Color iconColor = Colors.white;
    Color materialColor = widget.backgroundColor;
    if (materialColor == null) {
      final ThemeData themeData = Theme.of(context);
      materialColor = themeData.accentColor;
      iconColor = themeData.accentIconTheme.color;
    }

    Widget result = new Center(
      child: IconTheme.merge(
        data: new IconThemeData(color: iconColor),
        child: widget.child
      )
    );

    if (widget.tooltip != null) {
      result = new Tooltip(
        message: widget.tooltip,
        child: result
      );
    }

    return new Hero(
      tag: widget.heroTag ?? _kDefaultHeroTag,
      child: new Material(
        color: materialColor,
        type: MaterialType.circle,
        elevation: _highlight ? widget.highlightElevation : widget.elevation,
        child: new Container(
          width: widget.mini ? _kSizeMini : _kSize,
          height: widget.mini ? _kSizeMini : _kSize,
          child: new InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: _handleHighlightChanged,
            child: result
          )
        )
      )
    );
  }
}
