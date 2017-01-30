// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'image_icon.dart';
import 'ink_well.dart';
import 'theme.dart';

/// An item in a material design drawer.
///
/// Part of the material design [Drawer].
///
/// Requires one of its ancestors to be a [Material] widget. This condition is
/// satisfied by putting the [DrawerItem] in a [Drawer].
///
/// See also:
///
///  * [Drawer]
///  * [DrawerHeader]
///  * <https://material.google.com/patterns/navigation-drawer.html>
class DrawerItem extends StatelessWidget {
  /// Creates a material design drawer item.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  const DrawerItem({
    Key key,
    this.icon: const Icon(null),
    @required this.child,
    this.onPressed,
    this.selected: false
  }) : super(key: key);

  /// The icon to display before the child widget.
  ///
  /// The size and color of the icon is configured automatically using an
  /// [IconTheme] and therefore do not need to be explicitly given in the
  /// icon widget.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the user taps this drawer item.
  ///
  /// If null, the drawer item is displayed as disabled.
  ///
  /// To close the [Drawer] when an item is pressed, call [Navigator.pop].
  final VoidCallback onPressed;

  /// Whether this drawer item is currently selected.
  ///
  /// The currently selected item is highlighted to distinguish it from other
  /// drawer items.
  final bool selected;

  Color _getIconColor(ThemeData themeData) {
    switch (themeData.brightness) {
      case Brightness.light:
        if (selected)
          return themeData.primaryColor;
        if (onPressed == null)
          return Colors.black26;
        return Colors.black45;
      case Brightness.dark:
        if (selected)
          return themeData.accentColor;
        if (onPressed == null)
          return Colors.white30;
        return null; // use default icon theme color unmodified
    }
    assert(themeData.brightness != null);
    return null;
  }

  TextStyle _getTextStyle(ThemeData themeData) {
    TextStyle result = themeData.textTheme.body2;
    if (selected) {
      switch (themeData.brightness) {
        case Brightness.light:
          return result.copyWith(color: themeData.primaryColor);
        case Brightness.dark:
          return result.copyWith(color: themeData.accentColor);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);

    List<Widget> children = <Widget>[];
    if (icon != null) {
      children.add(
        new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: new IconTheme.merge(
            context: context,
            data: new IconThemeData(
              color: _getIconColor(themeData),
              size: 24.0
            ),
            child: icon
          )
        )
      );
    }
    if (child != null) {
      children.add(
        new Expanded(
          child: new Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: new AnimatedDefaultTextStyle(
              style: _getTextStyle(themeData),
              duration: kThemeChangeDuration,
              child: child
            )
          )
        )
      );
    }

    return new MergeSemantics(
      child: new Container(
        height: 48.0,
        child: new InkWell(
          onTap: onPressed,
          child: new Row(children: children)
        )
      )
    );
  }

}
