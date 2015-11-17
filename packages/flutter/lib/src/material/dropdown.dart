// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'icon.dart';
import 'ink_well.dart';
import 'shadows.dart';
import 'theme.dart';

const Duration _kMenuDuration = const Duration(milliseconds: 300);
const double _kMenuItemHeight = 48.0;
const EdgeDims _kMenuHorizontalPadding = const EdgeDims.only(left: 36.0, right: 36.0);
const double _kBaselineOffsetFromBottom = 20.0;
const Border _kDropdownUnderline = const Border(bottom: const BorderSide(color: const Color(0xFFBDBDBD), width: 2.0));

class _DropdownMenu extends StatusTransitionComponent {
  _DropdownMenu({
    Key key,
    _MenuRoute route
  }) : route = route, super(key: key, performance: route.performance);

  final _MenuRoute route;

  Widget build(BuildContext context) {
    // The menu is shown in three stages (unit timing in brackets):
    // [0 - 0.25] - Fade in a rect-sized menu container with the selected item.
    // [0.25 - 0.5] - Grow the otherwise empty menu container from the center
    //   until it's big enough for as many items as we're going to show.
    // [0.5 - 1.0] Fade in the remaining visible items from top to bottom.
    //
    // When the menu is dismissed we just fade the entire thing out
    // in the first 0.25.

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
          onTap: () {
            Navigator.of(context).pop(route.items[itemIndex].value);
          }
        )
      ));
    }

    final AnimatedValue<double> menuOpacity = new AnimatedValue<double>(0.0,
      end: 1.0,
      curve: new Interval(0.0, 0.25),
      reverseCurve: new Interval(0.75, 1.0)
    );

    final AnimatedValue<double> menuTop = new AnimatedValue<double>(route.rect.top,
      end: route.rect.top - route.selectedIndex * route.rect.height,
      curve: new Interval(0.25, 0.5),
      reverseCurve: const Interval(0.0, 0.001)
    );
    final AnimatedValue<double> menuBottom = new AnimatedValue<double>(route.rect.bottom,
      end: menuTop.end + route.items.length * route.rect.height,
      curve: new Interval(0.25, 0.5),
      reverseCurve: const Interval(0.0, 0.001)
    );

    final BoxPainter menuPainter = new BoxPainter(new BoxDecoration(
      backgroundColor: Theme.of(context).canvasColor,
      borderRadius: 2.0,
      boxShadow: elevationToShadow[route.elevation]
    ));

    final RenderBox renderBox = Navigator.of(context).context.findRenderObject();
    final Size navigatorSize = renderBox.size;
    final RelativeRect menuRect = new RelativeRect.fromSize(route.rect, navigatorSize);

    return new Positioned(
      top: menuRect.top - (route.selectedIndex * route.rect.height),
      right: menuRect.right,
      left: menuRect.left,
      child: new Focus(
        key: new GlobalObjectKey(route),
        child: new FadeTransition(
          performance: route.performance,
          opacity: menuOpacity,
          child: new BuilderTransition(
            performance: route.performance,
            variables: <AnimatedValue<double>>[menuTop, menuBottom],
            builder: (BuildContext context) {
              RenderBox renderBox = context.findRenderObject();
              return new CustomPaint(
                child: new Block(children),
                onPaint: (ui.Canvas canvas, Size size) {
                  double top = renderBox.globalToLocal(new Point(0.0, menuTop.value)).y;
                  double bottom = renderBox.globalToLocal(new Point(0.0, menuBottom.value)).y;
                  menuPainter.paint(canvas, new Rect.fromLTRB(0.0, top, size.width, bottom));
                }
              );
            }
          )
        )
      )
    );
  }
}

// TODO(abarth): This should use ModalRoute.
class _MenuRoute extends TransitionRoute {
  _MenuRoute({
    this.completer,
    this.items,
    this.selectedIndex,
    this.rect,
    this.elevation: 8
  });

  final Completer completer;
  final Rect rect;
  final List<DropdownMenuItem> items;
  final int elevation;
  final int selectedIndex;

  bool get opaque => false;
  Duration get transitionDuration => _kMenuDuration;

  Widget _buildModalBarrier(BuildContext context) => new ModalBarrier();
  Widget _buildDropDownMenu(BuildContext context) => new _DropdownMenu(route: this);

  List<WidgetBuilder> get builders => <WidgetBuilder>[ _buildModalBarrier, _buildDropDownMenu ];

  void didPop([dynamic result]) {
    completer.complete(result);
    super.didPop(result);
  }
}

class DropdownMenuItem<T> extends StatelessComponent {
  DropdownMenuItem({
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

class DropdownButton<T> extends StatelessComponent {
  DropdownButton({
    Key key,
    this.items,
    this.value,
    this.onChanged,
    this.elevation: 8
  }) : super(key: key);

  final List<DropdownMenuItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final int elevation;

  void _showDropdown(BuildContext context, int selectedIndex, GlobalKey indexedStackKey) {
    final RenderBox renderBox = indexedStackKey.currentContext.findRenderObject();
    final Rect rect = renderBox.localToGlobal(Point.origin) & renderBox.size;
    final Completer completer = new Completer();
    Navigator.of(context).pushEphemeral(new _MenuRoute(
      completer: completer,
      items: items,
      selectedIndex: selectedIndex,
      rect: _kMenuHorizontalPadding.inflateRect(rect),
      elevation: elevation
    ));
    completer.future.then((T newValue) {
      if (onChanged != null)
        onChanged(newValue);
    });
  }

  Widget build(BuildContext context) {
    GlobalKey indexedStackKey = new GlobalKey(label: 'DropdownButton.IndexedStack');
    int selectedIndex = 0;
    for (int itemIndex = 0; itemIndex < items.length; itemIndex++) {
      if (items[itemIndex].value == value) {
        selectedIndex = itemIndex;
        break;
      }
    }

    return new GestureDetector(
      child: new Container(
        decoration: new BoxDecoration(border: _kDropdownUnderline),
        child: new Row(<Widget>[
          new IndexedStack(items,
            key: indexedStackKey,
            index: selectedIndex,
            alignment: const FractionalOffset(0.5, 0.0)
          ),
          new Container(
            child: new Icon(icon: 'navigation/arrow_drop_down', size: IconSize.s36),
            padding: const EdgeDims.only(top: 6.0)
          )
        ],
          justifyContent: FlexJustifyContent.collapse
        )
      ),
      onTap: () {
        _showDropdown(context, selectedIndex, indexedStackKey);
      }
    );
  }
}
