// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'divider.dart';
import 'icon.dart';
import 'icon_button.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'list_tile.dart';
import 'material.dart';
import 'theme.dart';

const Duration _kMenuDuration = const Duration(milliseconds: 300);
const double _kBaselineOffsetFromBottom = 20.0;
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuItemHeight = 48.0;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuVerticalPadding = 8.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuScreenPadding = 8.0;

/// A base class for entries in a material design popup menu.
///
/// The popup menu widget uses this interface to interact with the menu items.
/// To show a popup menu, use the [showMenu] function. To create a button that
/// shows a popup menu, consider using [PopupMenuButton].
///
/// The type `T` is the type of the value the entry represents. All the entries
/// in a given menu must represent values with consistent types.
///
/// See also:
///
///  * [PopupMenuItem]
///  * [PopupMenuDivider]
///  * [CheckedPopupMenuItem]
///  * [showMenu]
///  * [PopupMenuButton]
abstract class PopupMenuEntry<T> extends StatefulWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const PopupMenuEntry({ Key key }) : super(key: key);

  /// The amount of vertical space occupied by this entry.
  ///
  /// This value must remain constant for a given instance.
  double get height;

  /// The value that should be returned by [showMenu] when the user selects this entry.
  T get value => null;

  /// Whether the user is permitted to select this entry.
  bool get enabled;
}

/// A horizontal divider in a material design popup menu.
///
/// This widget adatps the [Divider] for use in popup menus.
///
/// See also:
///
///  * [PopupMenuItem]
///  * [showMenu]
///  * [PopupMenuButton]
class PopupMenuDivider extends PopupMenuEntry<dynamic> {
  /// Creates a horizontal divider for a popup menu.
  ///
  /// By default, the divider has a height of 16.0 logical pixels.
  PopupMenuDivider({ Key key, this.height: 16.0 }) : super(key: key);

  @override
  final double height;

  @override
  bool get enabled => false;

  @override
  _PopupMenuDividerState createState() => new _PopupMenuDividerState();
}

class _PopupMenuDividerState extends State<PopupMenuDivider> {
  @override
  Widget build(BuildContext context) => new Divider(height: config.height);
}

/// An item in a material design popup menu.
///
/// To show a popup menu, use the [showMenu] function. To create a button that
/// shows a popup menu, consider using [PopupMenuButton].
///
/// To show a checkmark next to a popup menu item, consider using
/// [CheckedPopupMenuItem].
///
/// See also:
///
///  * [PopupMenuDivider]
///  * [CheckedPopupMenuItem]
///  * [showMenu]
///  * [PopupMenuButton]
class PopupMenuItem<T> extends PopupMenuEntry<T> {
  /// Creates an item for a popup menu.
  ///
  /// By default, the item is enabled.
  PopupMenuItem({
    Key key,
    this.value,
    this.enabled: true,
    @required this.child,
  }) : super(key: key);

  @override
  final T value;

  @override
  final bool enabled;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  double get height => _kMenuItemHeight;

  @override
  _PopupMenuItemState<PopupMenuItem<T>> createState() => new _PopupMenuItemState<PopupMenuItem<T>>();
}

class _PopupMenuItemState<T extends PopupMenuItem<dynamic>> extends State<T> {
  // Override this to put something else in the menu entry.
  Widget buildChild() => config.child;

  void onTap() {
    Navigator.pop(context, config.value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    TextStyle style = theme.textTheme.subhead;
    if (!config.enabled)
      style = style.copyWith(color: theme.disabledColor);

    Widget item = new AnimatedDefaultTextStyle(
      style: style,
      duration: kThemeChangeDuration,
      child: new Baseline(
        baseline: config.height - _kBaselineOffsetFromBottom,
        baselineType: TextBaseline.alphabetic,
        child: buildChild()
      )
    );
    if (!config.enabled) {
      final bool isDark = theme.brightness == Brightness.dark;
      item = new IconTheme.merge(
        context: context,
        data: new IconThemeData(opacity: isDark ? 0.5 : 0.38),
        child: item
      );
    }

    return new InkWell(
      onTap: config.enabled ? onTap : null,
      child: new MergeSemantics(
        child: new Container(
          height: config.height,
          padding: const EdgeInsets.symmetric(horizontal: _kMenuHorizontalPadding),
          child: item
        )
      )
    );
  }
}

/// An item with a checkmark in a material design popup menu.
///
/// To show a popup menu, use the [showMenu] function. To create a button that
/// shows a popup menu, consider using [PopupMenuButton].
///
/// See also:
///
///  * [PopupMenuItem]
///  * [PopupMenuDivider]
///  * [CheckedPopupMenuItem]
///  * [showMenu]
///  * [PopupMenuButton]
class CheckedPopupMenuItem<T> extends PopupMenuItem<T> {
  /// Creates a popup menu item with a checkmark.
  ///
  /// By default, the menu item is enabled but unchecked.
  CheckedPopupMenuItem({
    Key key,
    T value,
    this.checked: false,
    bool enabled: true,
    Widget child
  }) : super(
    key: key,
    value: value,
    enabled: enabled,
    child: child
  );

  /// Whether to display a checkmark next to the menu item.
  final bool checked;

  @override
  _CheckedPopupMenuItemState<T> createState() => new _CheckedPopupMenuItemState<T>();
}

class _CheckedPopupMenuItemState<T> extends _PopupMenuItemState<CheckedPopupMenuItem<T>> with SingleTickerProviderStateMixin {
  static const Duration _kFadeDuration = const Duration(milliseconds: 150);
  AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(duration: _kFadeDuration, vsync: this)
      ..value = config.checked ? 1.0 : 0.0
      ..addListener(() => setState(() { /* animation changed */ }));
  }

  @override
  void onTap() {
    // This fades the checkmark in or out when tapped.
    if (config.checked)
      _controller.reverse();
    else
      _controller.forward();
    super.onTap();
  }

  @override
  Widget buildChild() {
    return new ListTile(
      enabled: config.enabled,
      leading: new FadeTransition(
        opacity: _opacity,
        child: new Icon(_controller.isDismissed ? null : Icons.done)
      ),
      title: config.child
    );
  }
}

class _PopupMenu<T> extends StatelessWidget {
  _PopupMenu({
    Key key,
    this.route
  }) : super(key: key);

  final _PopupMenuRoute<T> route;

  @override
  Widget build(BuildContext context) {
    final double unit = 1.0 / (route.items.length + 1.5); // 1.0 for the width and 0.5 for the last item's fade.
    final List<Widget> children = <Widget>[];

    for (int i = 0; i < route.items.length; ++i) {
      final double start = (i + 1) * unit;
      final double end = (start + 1.5 * unit).clamp(0.0, 1.0);
      final CurvedAnimation opacity = new CurvedAnimation(
        parent: route.animation,
        curve: new Interval(start, end)
      );
      Widget item = route.items[i];
      if (route.initialValue != null && route.initialValue == route.items[i].value) {
        item = new Container(
          color: Theme.of(context).highlightColor,
          child: item
        );
      }
      children.add(new FadeTransition(
        opacity: opacity,
        child: item
      ));
    }

    final CurveTween opacity = new CurveTween(curve: const Interval(0.0, 1.0 / 3.0));
    final CurveTween width = new CurveTween(curve: new Interval(0.0, unit));
    final CurveTween height = new CurveTween(curve: new Interval(0.0, unit * route.items.length));

    final Widget child = new ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _kMenuMinWidth,
        maxWidth: _kMenuMaxWidth,
      ),
      child: new IntrinsicWidth(
        stepWidth: _kMenuWidthStep,
        child: new SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: _kMenuVerticalPadding
          ),
          child: new BlockBody(children: children),
        )
      )
    );

    return new AnimatedBuilder(
      animation: route.animation,
      builder: (BuildContext context, Widget child) {
        return new Opacity(
          opacity: opacity.evaluate(route.animation),
          child: new Material(
            type: MaterialType.card,
            elevation: route.elevation,
            child: new Align(
              alignment: FractionalOffset.topRight,
              widthFactor: width.evaluate(route.animation),
              heightFactor: height.evaluate(route.animation),
              child: child,
            ),
          ),
        );
      },
      child: child
    );
  }
}

class _PopupMenuRouteLayout extends SingleChildLayoutDelegate {
  _PopupMenuRouteLayout(this.position, this.selectedItemOffset);

  final RelativeRect position;
  final double selectedItemOffset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  // Put the child wherever position specifies, so long as it will fit within the
  // specified parent size padded (inset) by 8. If necessary, adjust the child's
  // position so that it fits.
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = position?.left
      ?? (position?.right != null ? size.width - (position.right + childSize.width) : _kMenuScreenPadding);
    double y = position?.top
      ?? (position?.bottom != null ? size.height - (position.bottom - childSize.height) : _kMenuScreenPadding);

    if (selectedItemOffset != null)
      y -= selectedItemOffset + _kMenuVerticalPadding + _kMenuItemHeight / 2.0;

    if (x < _kMenuScreenPadding)
      x = _kMenuScreenPadding;
    else if (x + childSize.width > size.width - 2 * _kMenuScreenPadding)
      x = size.width - childSize.width - _kMenuScreenPadding;
    if (y < _kMenuScreenPadding)
      y = _kMenuScreenPadding;
    else if (y + childSize.height > size.height - 2 * _kMenuScreenPadding)
      y = size.height - childSize.height - _kMenuScreenPadding;
    return new Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupMenuRouteLayout oldDelegate) {
    return position != oldDelegate.position;
  }
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    this.position,
    this.items,
    this.initialValue,
    this.elevation,
    this.theme
  });

  final RelativeRect position;
  final List<PopupMenuEntry<T>> items;
  final dynamic initialValue;
  final int elevation;
  final ThemeData theme;

  @override
  Animation<double> createAnimation() {
    return new CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linear,
      reverseCurve: const Interval(0.0, _kMenuCloseIntervalEnd)
    );
  }

  @override
  Duration get transitionDuration => _kMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    double selectedItemOffset;
    if (initialValue != null) {
      selectedItemOffset = 0.0;
      for (int i = 0; i < items.length; i++) {
        if (initialValue == items[i].value)
          break;
        selectedItemOffset += items[i].height;
      }
    }

    Widget menu = new _PopupMenu<T>(route: this);
    if (theme != null)
      menu = new Theme(data: theme, child: menu);

    return new CustomSingleChildLayout(
      delegate: new _PopupMenuRouteLayout(position, selectedItemOffset),
      child: menu
    );
  }
}

/// Show a popup menu that contains the `items` at `position`. If `initialValue`
/// is specified then the first item with a matching value will be highlighted
/// and the value of `position` implies where the left, center point of the
/// highlighted item should appear. If `initialValue` is not specified then
/// `position` specifies the menu's origin.
///
/// The `context` argument is used to look up a [Navigator] to show the menu and
/// a [Theme] to use for the menu.
///
/// The `elevation` argument specifies the z-coordinate at which to place the
/// menu. The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9,
/// 12, 16, 24. The elevation defaults to 8, the appropriate elevation for popup
/// menus.
Future<T> showMenu<T>({
  @required BuildContext context,
  RelativeRect position,
  @required List<PopupMenuEntry<T>> items,
  T initialValue,
  int elevation: 8
}) {
  assert(context != null);
  assert(items != null && items.isNotEmpty);
  return Navigator.push(context, new _PopupMenuRoute<T>(
    position: position,
    items: items,
    initialValue: initialValue,
    elevation: elevation,
    theme: Theme.of(context, shadowThemeOnly: true),
  ));
}

/// Signature for the callback invoked when a menu item is selected. The
/// argument is the value of the [PopupMenuItem] that caused its menu to be
/// dismissed.
///
/// Used by [PopupMenuButton.onSelected].
typedef void PopupMenuItemSelected<T>(T value);

/// Signature used by [PopupMenuButton] to lazily construct the items shown when
/// the button is pressed.
///
/// Used by [PopupMenuButton.itemBuilder].
typedef List<PopupMenuEntry<T>> PopupMenuItemBuilder<T>(BuildContext context);

/// Displays a menu when pressed and calls [onSelected] when the menu is dismissed
/// because an item was selected. The value passed to [onSelected] is the value of
/// the selected menu item. If child is null then a standard 'navigation/more_vert'
/// icon is created.
class PopupMenuButton<T> extends StatefulWidget {
  /// Creates a button that shows a popup menu.
  ///
  /// The [itemBuilder] argument must not be null.
  PopupMenuButton({
    Key key,
    @required this.itemBuilder,
    this.initialValue,
    this.onSelected,
    this.tooltip: 'Show menu',
    this.elevation: 8,
    this.padding: const EdgeInsets.all(8.0),
    this.child
  }) : super(key: key) {
    assert(itemBuilder != null);
  }

  /// Called when the button is pressed to create the items to show in the menu.
  final PopupMenuItemBuilder<T> itemBuilder;

  /// The value of the menu item, if any, that should be highlighted when the menu opens.
  final T initialValue;

  /// Called when the user selects a value from the popup menu created by this button.
  final PopupMenuItemSelected<T> onSelected;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String tooltip;

  /// The z-coordinate at which to place the menu when open.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int elevation;

  /// Matches IconButton's 8 dps padding by default. In some cases, notably where
  /// this button appears as the trailing element of a list item, it's useful to be able
  /// to set the padding to zero.
  final EdgeInsets padding;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _PopupMenuButtonState<T> createState() => new _PopupMenuButtonState<T>();
}

class _PopupMenuButtonState<T> extends State<PopupMenuButton<T>> {
  void showButtonMenu() {
    final RenderBox renderBox = context.findRenderObject();
    final Point topLeft = renderBox.localToGlobal(Point.origin);
    showMenu<T>(
      context: context,
      elevation: config.elevation,
      items: config.itemBuilder(context),
      initialValue: config.initialValue,
      position: new RelativeRect.fromLTRB(
        topLeft.x, topLeft.y + (config.initialValue != null ? renderBox.size.height / 2.0 : 0.0),
        0.0, 0.0
      )
    )
    .then<Null>((T newValue) {
      if (!mounted || newValue == null)
        return null;
      if (config.onSelected != null)
        config.onSelected(newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (config.child == null) {
      return new IconButton(
        icon: new Icon(Icons.more_vert),
        padding: config.padding,
        tooltip: config.tooltip,
        onPressed: showButtonMenu,
      );
    }
    return new InkWell(
      onTap: showButtonMenu,
      child: config.child,
    );
  }
}
