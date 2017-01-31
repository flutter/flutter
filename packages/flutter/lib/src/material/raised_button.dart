// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'theme.dart';

/// A material design "raised button".
///
/// A raised button consists of a rectangular piece of material that hovers over
/// the interface.
///
/// Use raised buttons to add dimension to otherwise mostly flat layouts, e.g.
/// in long busy lists of content, or in wide spaces. Avoid using raised buttons
/// on already-raised content such as dialogs or cards.
///
/// If the [onPressed] callback is null, then the button will be disabled and by
/// default will appear like a flat button in the [disabledColor]. If you are
/// trying to change the button's [color] and it is not having any effect, check
/// that you are passing a non-null [onPressed] handler.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [FlatButton]
///  * [DropdownButton]
///  * [FloatingActionButton]
///  * <https://material.google.com/components/buttons.html>
class RaisedButton extends StatelessWidget {
  /// Creates a raised button.
  ///
  /// The [child] argument is required and is typically a [Text] widget in all
  /// caps.
  RaisedButton({
    Key key,
    @required this.onPressed,
    this.color,
    this.disabledColor,
    this.elevation: 2,
    this.highlightElevation: 8,
    this.disabledElevation: 0,
    this.colorBrightness,
    this.child
  }) : super(key: key);

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// The color of the button, as printed on the [Material]. Defaults to null,
  /// meaning that the color is automatically derived from the [Theme].
  ///
  /// ```dart
  ///  new RaisedButton(
  ///    color: Colors.blue[500],
  ///    onPressed: _handleTap,
  ///    child: new Text('DEMO'),
  ///  ),
  /// ```
  final Color color;

  /// The color of the button when the button is disabled. Buttons are disabled
  /// by default. To enable a button, set its [onPressed] property to a non-null
  /// value.
  final Color disabledColor;

  /// The z-coordinate at which to place this button.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  ///
  /// Defaults to 2, the appropriate elevation for raised buttons.
  final int elevation;

  /// The z-coordinate at which to place this button when highlighted.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  ///
  /// Defaults to 8, the appropriate elevation for raised buttons while they are
  /// being touched.
  final int highlightElevation;

  /// The z-coordinate at which to place this button when disabled.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  ///
  /// Defaults to 0, the appropriate elevation for disabled raised buttons.
  final int disabledElevation;

  /// The theme brightness to use for this button.
  ///
  /// Defaults to the brightness from [ThemeData.brightness].
  final Brightness colorBrightness;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget in all caps.
  final Widget child;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  Color _getColor(BuildContext context) {
    if (enabled) {
      return color ?? Theme.of(context).buttonColor;
    } else {
      if (disabledColor != null)
        return disabledColor;
      Brightness brightness = Theme.of(context).brightness;
      assert(brightness != null);
      switch (brightness) {
        case Brightness.light:
          return Colors.black12;
        case Brightness.dark:
          return Colors.white12;
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialButton(
      onPressed: onPressed,
      color: _getColor(context),
      elevation: enabled ? elevation : disabledElevation,
      highlightElevation: enabled ? highlightElevation : disabledElevation,
      colorBrightness: colorBrightness,
      child: child,
    );
  }
}
