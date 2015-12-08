// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'icon.dart';
import 'ink_well.dart';
import 'shadows.dart';
import 'theme.dart';
import 'material.dart';

const Duration _kDropDownMenuDuration = const Duration(milliseconds: 300);
const double _kMenuItemHeight = 48.0;
const EdgeDims _kMenuHorizontalPadding = const EdgeDims.only(left: 36.0, right: 36.0);
const double _kBaselineOffsetFromBottom = 20.0;
const Border _kDropDownUnderline = const Border(bottom: const BorderSide(color: const Color(0xFFBDBDBD), width: 2.0));

class _DropDownMenuPainter extends CustomPainter {
  const _DropDownMenuPainter({
    this.color,
    this.elevation,
    this.menuTop,
    this.menuBottom,
    this.renderBox
  });

  final Color color;
  final int elevation;
  final double menuTop;
  final double menuBottom;
  final RenderBox renderBox;

  void paint(Canvas canvas, Size size) {
    final BoxPainter painter = new BoxDecoration(
      backgroundColor: color,
      borderRadius: 2.0,
      boxShadow: elevationToShadow[elevation]
    ).createBoxPainter();

    double top = renderBox.globalToLocal(new Point(0.0, menuTop)).y;
    double bottom = renderBox.globalToLocal(new Point(0.0, menuBottom)).y;
    painter.paint(canvas, new Rect.fromLTRB(0.0, top, size.width, bottom));
  }

  bool shouldRepaint(_DropDownMenuPainter oldPainter) {
    return oldPainter.color != color
        || oldPainter.elevation != elevation
        || oldPainter.menuTop != menuTop
        || oldPainter.menuBottom != menuBottom
        || oldPainter.renderBox != renderBox;
  }
}

class _DropDownMenu<T> extends StatusTransitionComponent {
  _DropDownMenu({
    Key key,
    _DropDownRoute<T> route
  }) : route = route, super(key: key, performance: route.performance);

  final _DropDownRoute<T> route;

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
      AnimatedValue<double> opacity;
      if (itemIndex == route.selectedIndex) {
        opacity = new AnimatedValue<double>(0.0, end: 1.0, curve: const Interval(0.0, 0.001), reverseCurve: const Interval(0.75, 1.0));
      } else {
        final double start = (0.5 + (itemIndex + 1) * unit).clamp(0.0, 1.0);
        final double end = (start + 1.5 * unit).clamp(0.0, 1.0);
        opacity = new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(start, end), reverseCurve: const Interval(0.75, 1.0));
      }
      children.add(new FadeTransition(
        performance: route.performance,
        opacity: opacity,
        child: new InkWell(
          child: new Container(
            padding: _kMenuHorizontalPadding,
            child: route.items[itemIndex]
          ),
          onTap: () => Navigator.pop(context, route.items[itemIndex].value)
        )
      ));
    }

    final AnimatedValue<double> menuOpacity = new AnimatedValue<double>(0.0,
      end: 1.0,
      curve: const Interval(0.0, 0.25),
      reverseCurve: const Interval(0.75, 1.0)
    );

    final AnimatedValue<double> menuTop = new AnimatedValue<double>(route.rect.top,
      end: route.rect.top - route.selectedIndex * route.rect.height,
      curve: const Interval(0.25, 0.5),
      reverseCurve: const Interval(0.0, 0.001)
    );
    final AnimatedValue<double> menuBottom = new AnimatedValue<double>(route.rect.bottom,
      end: menuTop.end + route.items.length * route.rect.height,
      curve: const Interval(0.25, 0.5),
      reverseCurve: const Interval(0.0, 0.001)
    );

    return new FadeTransition(
      performance: route.performance,
      opacity: menuOpacity,
      child: new BuilderTransition(
        performance: route.performance,
        variables: <AnimatedValue<double>>[menuTop, menuBottom],
        builder: (BuildContext context) {
          return new CustomPaint(
            painter: new _DropDownMenuPainter(
              color: Theme.of(context).canvasColor,
              elevation: route.elevation,
              menuTop: menuTop.value,
              menuBottom: menuBottom.value,
              renderBox: context.findRenderObject()
            ),
            child: new Material(
              type: MaterialType.transparency,
              child: new Block(children)
            )
          );
        }
      )
    );
  }
}

class _DropDownRoute<T> extends PopupRoute<T> {
  _DropDownRoute({
    Completer<T> completer,
    this.items,
    this.selectedIndex,
    this.rect,
    this.elevation: 8
  }) : super(completer: completer);

  final List<DropDownMenuItem<T>> items;
  final int selectedIndex;
  final Rect rect;
  final int elevation;

  Duration get transitionDuration => _kDropDownMenuDuration;
  bool get barrierDismissable => true;
  Color get barrierColor => null;

  ModalPosition getPosition(BuildContext context) {
    RenderBox overlayBox = Overlay.of(context).context.findRenderObject();
    Size overlaySize = overlayBox.size;
    RelativeRect menuRect = new RelativeRect.fromSize(rect, overlaySize);
    return new ModalPosition(
      top: menuRect.top - selectedIndex * rect.height,
      left: menuRect.left,
      right: menuRect.right
    );
  }

  Widget buildPage(BuildContext context, PerformanceView performance, PerformanceView forwardPerformance) {
    return new _DropDownMenu(route: this);
  }
}

class DropDownMenuItem<T> extends StatelessComponent {
  DropDownMenuItem({
    Key key,
    this.value,
    this.child
  }) : super(key: key);

  final Widget child;
  final T value;

  Widget build(BuildContext context) {
    return new Container(
      height: _kMenuItemHeight,
      padding: const EdgeDims.only(left: 8.0, right: 8.0, top: 6.0),
      child: new DefaultTextStyle(
        style: Theme.of(context).text.subhead,
        child: new Baseline(
          baseline: _kMenuItemHeight - _kBaselineOffsetFromBottom,
          child: child
        )
      )
    );
  }
}

class DropDownButton<T> extends StatefulComponent {
  DropDownButton({
    Key key,
    this.items,
    this.value,
    this.onChanged,
    this.elevation: 8
  }) : super(key: key);

  final List<DropDownMenuItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final int elevation;

  _DropDownButtonState<T> createState() => new _DropDownButtonState<T>();
}

class _DropDownButtonState<T> extends State<DropDownButton<T>> {
  final GlobalKey indexedStackKey = new GlobalKey(debugLabel: 'DropDownButton.IndexedStack');

  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

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
    final RenderBox renderBox = indexedStackKey.currentContext.findRenderObject();
    final Rect rect = renderBox.localToGlobal(Point.origin) & renderBox.size;
    final Completer completer = new Completer<T>();
    Navigator.push(context, new _DropDownRoute<T>(
      completer: completer,
      items: config.items,
      selectedIndex: _selectedIndex,
      rect: _kMenuHorizontalPadding.inflateRect(rect),
      elevation: config.elevation
    ));
    completer.future.then((T newValue) {
      if (!mounted)
        return;
      if (config.onChanged != null)
        config.onChanged(newValue);
    });
  }

  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new GestureDetector(
      onTap: _handleTap,
      child: new Container(
        decoration: new BoxDecoration(border: _kDropDownUnderline),
        child: new Row(<Widget>[
          new IndexedStack(
            config.items,
            key: indexedStackKey,
            index: _selectedIndex,
            alignment: const FractionalOffset(0.5, 0.0)
          ),
          new Container(
            child: new Icon(icon: 'navigation/arrow_drop_down', size: IconSize.s36),
            padding: const EdgeDims.only(top: 6.0)
          )
        ],
          justifyContent: FlexJustifyContent.collapse
        )
      )
    );
  }
}
