// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'icon.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'shadows.dart';
import 'theme.dart';
import 'material.dart';

const Duration _kDropDownMenuDuration = const Duration(milliseconds: 300);
const double _kTopMargin = 6.0;
const double _kMenuItemHeight = 48.0;
const EdgeInsets _kMenuVerticalPadding = const EdgeInsets.symmetric(vertical: 8.0);
const EdgeInsets _kMenuHorizontalPadding = const EdgeInsets.symmetric(horizontal: 36.0);
const double _kBaselineOffsetFromBottom = 20.0;
const double _kBottomBorderHeight = 2.0;
const Border _kDropDownUnderline = const Border(bottom: const BorderSide(color: const Color(0xFFBDBDBD), width: _kBottomBorderHeight));

class _DropDownMenuPainter extends CustomPainter {
  _DropDownMenuPainter({
    Color color,
    int elevation,
    this.selectedIndex,
    Animation<double> resize
  }) : color = color,
       elevation = elevation,
       resize = resize,
       _painter = new BoxDecoration(
         backgroundColor: color,
         borderRadius: 2.0,
         boxShadow: kElevationToShadow[elevation]
       ).createBoxPainter(),
       super(repaint: resize);

  final Color color;
  final int elevation;
  final int selectedIndex;
  final Animation<double> resize;

  final BoxPainter _painter;

  @override
  void paint(Canvas canvas, Size size) {
    final Tween<double> top = new Tween<double>(
      begin: (selectedIndex * _kMenuItemHeight + _kMenuVerticalPadding.top).clamp(0.0, size.height - _kMenuItemHeight),
      end: 0.0
    );

    final Tween<double> bottom = new Tween<double>(
      begin: (top.begin + _kMenuItemHeight).clamp(_kMenuItemHeight, size.height),
      end: size.height
    );

    _painter.paint(canvas, new Rect.fromLTRB(0.0, top.evaluate(resize), size.width, bottom.evaluate(resize)));
  }

  @override
  bool shouldRepaint(_DropDownMenuPainter oldPainter) {
    return oldPainter.color != color
        || oldPainter.elevation != elevation
        || oldPainter.selectedIndex != selectedIndex
        || oldPainter.resize != resize;
  }
}

class _DropDownMenu<T> extends StatusTransitionWidget {
  _DropDownMenu({
    Key key,
    _DropDownRoute<T> route
  }) : route = route, super(key: key, animation: route.animation);

  final _DropDownRoute<T> route;

  @override
  Widget build(BuildContext context) {
    // The menu is shown in three stages (unit timing in brackets):
    // [0s - 0.25s] - Fade in a rect-sized menu container with the selected item.
    // [0.25s - 0.5s] - Grow the otherwise empty menu container from the center
    //   until it's big enough for as many items as we're going to show.
    // [0.5s - 1.0s] Fade in the remaining visible items from top to bottom.
    //
    // When the menu is dismissed we just fade the entire thing out
    // in the first 0.25s.

    final double unit = 0.5 / (route.items.length + 1.5);
    final List<Widget> children = <Widget>[];
    for (int itemIndex = 0; itemIndex < route.items.length; ++itemIndex) {
      CurvedAnimation opacity;
      Interval reverseCurve = const Interval(0.75, 1.0);
      if (itemIndex == route.selectedIndex) {
        opacity = new CurvedAnimation(parent: route.animation, curve: const Step(0.0), reverseCurve: reverseCurve);
      } else {
        final double start = (0.5 + (itemIndex + 1) * unit).clamp(0.0, 1.0);
        final double end = (start + 1.5 * unit).clamp(0.0, 1.0);
        opacity = new CurvedAnimation(parent: route.animation, curve: new Interval(start, end), reverseCurve: reverseCurve);
      }
      children.add(new FadeTransition(
        opacity: opacity,
        child: new InkWell(
          child: new Container(
            padding: _kMenuHorizontalPadding,
            child: route.items[itemIndex]
          ),
          onTap: () => Navigator.pop(
            context,
            new _DropDownRouteResult<T>(route.items[itemIndex].value)
          )
        )
      ));
    }

    return new FadeTransition(
      opacity: new CurvedAnimation(
        parent: route.animation,
        curve: const Interval(0.0, 0.25),
        reverseCurve: const Interval(0.75, 1.0)
      ),
      child: new CustomPaint(
        painter: new _DropDownMenuPainter(
          color: Theme.of(context).canvasColor,
          elevation: route.elevation,
          selectedIndex: route.selectedIndex,
          resize: new CurvedAnimation(
            parent: route.animation,
            curve: const Interval(0.25, 0.5),
            reverseCurve: const Step(0.0)
          )
        ),
        child: new Material(
          type: MaterialType.transparency,
          child: new ScrollableList(
            padding: _kMenuVerticalPadding,
            itemExtent: _kMenuItemHeight,
            children: children
          )
        )
      )
    );
  }
}

class _DropDownMenuRouteLayout extends SingleChildLayoutDelegate {
  _DropDownMenuRouteLayout(this.buttonRect, this.selectedIndex);

  final Rect buttonRect;
  final int selectedIndex;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The maximum height of a simple menu should be one or more rows less than
    // the view height. This ensures a tappable area outside of the simple menu
    // with which to dismiss the menu.
    //   -- https://www.google.com/design/spec/components/menus.html#menus-simple-menus
    final double maxHeight = math.max(0.0, constraints.maxHeight - 2 * _kMenuItemHeight);
    final double width = buttonRect.width;
    return new BoxConstraints(
      minWidth: width,
      maxWidth: width,
      minHeight: 0.0,
      maxHeight: maxHeight
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double buttonTop = buttonRect.top;
    double top = buttonTop - selectedIndex * _kMenuItemHeight - _kMenuVerticalPadding.top;
    double topPreferredLimit = _kMenuItemHeight;
    if (top < topPreferredLimit)
      top = math.min(buttonTop, topPreferredLimit);
    double bottom = top + childSize.height;
    double bottomPreferredLimit = size.height - _kMenuItemHeight;
    if (bottom > bottomPreferredLimit) {
      bottom = math.max(buttonTop + _kMenuItemHeight, bottomPreferredLimit);
      top = bottom - childSize.height;
    }
    assert(top >= 0.0);
    assert(top + childSize.height <= size.height);
    return new Offset(buttonRect.left, top);
  }

  @override
  bool shouldRelayout(_DropDownMenuRouteLayout oldDelegate) {
    return oldDelegate.buttonRect != buttonRect
        || oldDelegate.selectedIndex != selectedIndex;
  }
}

// We box the return value so that the return value can be null. Otherwise,
// canceling the route (which returns null) would get confused with actually
// returning a real null value.
class _DropDownRouteResult<T> {
  const _DropDownRouteResult(this.result);

  final T result;

  @override
  bool operator ==(dynamic other) {
    if (other is! _DropDownRouteResult<T>)
      return false;
    final _DropDownRouteResult<T> typedOther = other;
    return result == typedOther.result;
  }

  @override
  int get hashCode => result.hashCode;
}

class _DropDownRoute<T> extends PopupRoute<_DropDownRouteResult<T>> {
  _DropDownRoute({
    Completer<_DropDownRouteResult<T>> completer,
    this.items,
    this.buttonRect,
    this.selectedIndex,
    this.elevation: 8
  }) : super(completer: completer);

  final List<DropDownMenuItem<T>> items;
  final Rect buttonRect;
  final int selectedIndex;
  final int elevation;

  @override
  Duration get transitionDuration => _kDropDownMenuDuration;

  @override
  bool get barrierDismissable => true;

  @override
  Color get barrierColor => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    return new CustomSingleChildLayout(
      delegate: new _DropDownMenuRouteLayout(buttonRect, selectedIndex),
      child: new _DropDownMenu<T>(route: this)
    );
  }
}

/// An item in a menu created by a [DropDownButton].
///
/// The type `T` is the type of the value the entry represents. All the entries
/// in a given menu must represent values with consistent types.
class DropDownMenuItem<T> extends StatelessWidget {
  /// Creates an item for a drop down menu.
  ///
  /// The [child] argument is required.
  DropDownMenuItem({
    Key key,
    this.value,
    this.child
  }) : super(key: key) {
    assert(child != null);
  }

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// The value to return if the user selects this menu item.
  ///
  /// Eventually returned in a call to [DropDownButton.onChanged].
  final T value;

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: _kMenuItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: new DefaultTextStyle.explicit(
        style: Theme.of(context).textTheme.subhead,
        child: new Baseline(
          baselineType: TextBaseline.alphabetic,
          baseline: _kMenuItemHeight - _kBaselineOffsetFromBottom,
          child: child
        )
      )
    );
  }
}

/// An inherited widget that causes any descendant [DropDownButton]
/// widgets to not include their regular underline.
///
/// This is used by [DataTable] to remove the underline from any
/// [DropDownButton] widgets placed within material data tables, as
/// required by the material design specification.
class DropDownButtonHideUnderline extends InheritedWidget {
  /// Creates a [DropDownButtonHideUnderline]. A non-null [child] must
  /// be given.
  DropDownButtonHideUnderline({
    Key key,
    Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
  }

  /// Returns whether the underline of [DropDownButton] widgets should
  /// be hidden.
  static bool at(BuildContext context) {
    return context.inheritFromWidgetOfExactType(DropDownButtonHideUnderline) != null;
  }

  @override
  bool updateShouldNotify(DropDownButtonHideUnderline old) => false;
}

/// A material design button for selecting from a list of items.
///
/// A dropdown button lets the user select from a number of items. The button
/// shows the currently selected item as well as an arrow that opens a menu for
/// selecting another item.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [RaisedButton]
///  * [FlatButton]
///  * <https://www.google.com/design/spec/components/buttons.html#buttons-dropdown-buttons>
class DropDownButton<T> extends StatefulWidget {
  /// Creates a drop down button.
  ///
  /// The [items] must have distinct values and [value] must be among them.
  DropDownButton({
    Key key,
    this.items,
    this.value,
    this.onChanged,
    this.elevation: 8
  }) : super(key: key) {
    assert(items != null);
    assert(items.where((DropDownMenuItem<T> item) => item.value == value).length == 1);
  }

  /// The list of possible items to select among.
  final List<DropDownMenuItem<T>> items;

  /// The currently selected item.
  final T value;

  /// Called when the user selects an item.
  final ValueChanged<T> onChanged;

  /// The z-coordinate at which to place the menu when open.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int elevation;

  @override
  _DropDownButtonState<T> createState() => new _DropDownButtonState<T>();
}

class _DropDownButtonState<T> extends State<DropDownButton<T>> {
  final GlobalKey _itemKey = new GlobalKey(debugLabel: 'DropDownButton item key');

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
    assert(_selectedIndex != null);
  }

  @override
  void didUpdateConfig(DropDownButton<T> oldConfig) {
    if (config.items[_selectedIndex].value != config.value)
      _updateSelectedIndex();
  }

  int _selectedIndex;

  void _updateSelectedIndex() {
    for (int itemIndex = 0; itemIndex < config.items.length; itemIndex++) {
      if (config.items[itemIndex].value == config.value) {
        _selectedIndex = itemIndex;
        return;
      }
    }
  }

  void _handleTap() {
    final RenderBox itemBox = _itemKey.currentContext.findRenderObject();
    final Rect itemRect = itemBox.localToGlobal(Point.origin) & itemBox.size;
    final Completer<_DropDownRouteResult<T>> completer = new Completer<_DropDownRouteResult<T>>();
    Navigator.push(context, new _DropDownRoute<T>(
      completer: completer,
      items: config.items,
      buttonRect: _kMenuHorizontalPadding.inflateRect(itemRect),
      selectedIndex: _selectedIndex,
      elevation: config.elevation
    ));
    completer.future.then((_DropDownRouteResult<T> newValue) {
      if (!mounted || newValue == null)
        return;
      if (config.onChanged != null)
        config.onChanged(newValue.result);
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Widget result = new Row(
      mainAxisAlignment: MainAxisAlignment.collapse,
      children: <Widget>[
        // We use an IndexedStack to make sure we have enough width to show any
        // possible item as the selected item without changing size.
        new IndexedStack(
          children: config.items,
          key: _itemKey,
          index: _selectedIndex,
          alignment: FractionalOffset.centerLeft
        ),
        new Icon(icon: Icons.arrow_drop_down, size: 36.0)
      ]
    );
    if (DropDownButtonHideUnderline.at(context)) {
      result = new Padding(
        padding: const EdgeInsets.only(top: _kTopMargin, bottom: _kBottomBorderHeight),
        child: result
      );
    } else {
      result = new Container(
        padding: const EdgeInsets.only(top: _kTopMargin),
        decoration: const BoxDecoration(border: _kDropDownUnderline),
        child: result
      );
    }
    return new GestureDetector(
      onTap: _handleTap,
      child: result
    );
  }
}
