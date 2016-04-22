// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
/// If the [onPressed] callback is not specified or null, then the button will
/// be disabled and by default will appear like a flat button in the
/// [disabledColor]. If you are trying to change the button's [color] and it is
/// not having any effect, check that you are passing a non-null [onPressed]
/// handler.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [FlatButton]
///  * [DropDownButton]
///  * [FloatingActionButton]
///  * <https://www.google.com/design/spec/components/buttons.html>
class RaisedButton extends MaterialButton {
  RaisedButton({
    Key key,
    Widget child,
    ThemeBrightness colorBrightness,
    this.color,
    this.disabledColor,
    this.elevation: 2,
    this.highlightElevation: 8,
    this.disabledElevation: 0,
    VoidCallback onPressed
  }) : super(key: key,
             child: child,
             colorBrightness: colorBrightness,
             onPressed: onPressed);

  /// The color of the button, as printed on the [Material]. Defaults to null,
  /// meaning that the color is automatically derived from the [Theme].
  final Color color;

  /// The color of the button when the button is disabled. Buttons are disabled
  /// by default. To enable a button, set its [onPressed] property to a non-null
  /// value.
  final Color disabledColor;

  /// The z-coordinate at which to place this button.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int elevation;

  /// The z-coordinate at which to place this button when highlighted.
  final int highlightElevation;

  /// The z-coordinate at which to place this button when disabled.
  final int disabledElevation;

  @override
  _RaisedButtonState createState() => new _RaisedButtonState();
}

class _RaisedButtonState extends MaterialButtonState<RaisedButton> {
  @override
  int get elevation {
    if (config.enabled) {
      if (highlight)
        return config.highlightElevation;
      return config.elevation;
    } else {
      return config.disabledElevation;
    }
  }

  @override
  Color getColor(BuildContext context) {
    if (config.enabled) {
      return config.color ?? Theme.of(context).buttonColor;
    } else {
      if (config.disabledColor != null)
        return config.disabledColor;
      switch (Theme.of(context).brightness) {
        case ThemeBrightness.light:
          return Colors.black12;
        case ThemeBrightness.dark:
          return Colors.white12;
      }
    }
  }
}
