// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'ink_well.dart';
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

class PopupMenuItem<T> extends StatelessComponent {
  PopupMenuItem({
    Key key,
    this.value,
    this.child
  }) : super(key: key);

  final Widget child;
  final T value;

  Widget build(BuildContext context) {
    return new Container(
      height: _kMenuItemHeight,
      padding: const EdgeDims.symmetric(horizontal: _kMenuHorizontalPadding),
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

class _PopupMenu<T> extends StatelessComponent {
  _PopupMenu({
    Key key,
    this.route
  }) : super(key: key);

  final _PopupMenuRoute<T> route;

  Widget build(BuildContext context) {
    double unit = 1.0 / (route.items.length + 1.5); // 1.0 for the width and 0.5 for the last item's fade.
    List<Widget> children = <Widget>[];

    for (int i = 0; i < route.items.length; ++i) {
      double start = (i + 1) * unit;
      double end = (start + 1.5 * unit).clamp(0.0, 1.0);
      CurvedAnimation opacity = new CurvedAnimation(
        parent: route.animation,
        curve: new Interval(start, end)
      );
      children.add(new FadeTransition(
        opacity: opacity,
        child: new InkWell(
          onTap: () => Navigator.pop(context, route.items[i].value),
          child: route.items[i]
        ))
      );
    }

    final CurveTween opacity = new CurveTween(curve: new Interval(0.0, 1.0 / 3.0));
    final CurveTween width = new CurveTween(curve: new Interval(0.0, unit));
    final CurveTween height = new CurveTween(curve: new Interval(0.0, unit * route.items.length));

    Widget child = new ConstrainedBox(
      constraints: new BoxConstraints(
        minWidth: _kMenuMinWidth,
        maxWidth: _kMenuMaxWidth
      ),
      child: new IntrinsicWidth(
        stepWidth: _kMenuWidthStep,
        child: new Block(
          children,
          padding: const EdgeDims.symmetric(
            vertical: _kMenuVerticalPadding
          )
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
              alignment: const FractionalOffset(1.0, 0.0),
              widthFactor: width.evaluate(route.animation),
              heightFactor: height.evaluate(route.animation),
              child: child
            )
          )
        );
      },
      child: child
    );
  }
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    Completer<T> completer,
    this.position,
    this.items,
    this.elevation
  }) : super(completer: completer);

  final ModalPosition position;
  final List<PopupMenuItem<T>> items;
  final int elevation;

  ModalPosition getPosition(BuildContext context) {
    return position;
  }

  Animation<double> createAnimation() {
    return new CurvedAnimation(
      parent: super.createAnimation(),
      reverseCurve: new Interval(0.0, _kMenuCloseIntervalEnd)
    );
  }

  Duration get transitionDuration => _kMenuDuration;
  bool get barrierDismissable => true;
  Color get barrierColor => null;

  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    return new _PopupMenu(route: this);
  }
}

Future showMenu({ BuildContext context, ModalPosition position, List<PopupMenuItem> items, int elevation: 8 }) {
  Completer completer = new Completer();
  Navigator.push(context, new _PopupMenuRoute(
    completer: completer,
    position: position,
    items: items,
    elevation: elevation
  ));
  return completer.future;
}
