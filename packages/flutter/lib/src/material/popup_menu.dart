// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'ink_well.dart';
import 'material.dart';
import 'popup_menu_item.dart';

const Duration _kMenuDuration = const Duration(milliseconds: 300);
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuVerticalPadding = 8.0;

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
      children.add(new FadeTransition(
        performance: route.performance,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(start, end)),
        child: new InkWell(
          onTap: () => Navigator.pop(context, route.items[i].value),
          child: route.items[i]
        ))
      );
    }

    final AnimatedValue<double> opacity = new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, 1.0 / 3.0));
    final AnimatedValue<double> width = new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, unit));
    final AnimatedValue<double> height = new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, unit * route.items.length));

    return new BuilderTransition(
      performance: route.performance,
      variables: <AnimatedValue<double>>[opacity, width, height],
      builder: (BuildContext context) {
        return new Opacity(
          opacity: opacity.value,
          child: new Material(
            type: MaterialType.card,
            elevation: route.elevation,
            child: new Align(
              alignment: const FractionalOffset(1.0, 0.0),
              widthFactor: width.value,
              heightFactor: height.value,
              child: new ConstrainedBox(
                constraints: new BoxConstraints(
                  minWidth: _kMenuMinWidth,
                  maxWidth: _kMenuMaxWidth
                ),
                child: new IntrinsicWidth(
                  stepWidth: _kMenuWidthStep,
                  child: new Block(
                    children,
                    padding: const EdgeDims.symmetric(
                      horizontal: _kMenuHorizontalPadding,
                      vertical: _kMenuVerticalPadding
                    )
                  )
                )
              )
            )
          )
        );
      }
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

  Performance createPerformance() {
    Performance result = super.createPerformance();
    AnimationTiming timing = new AnimationTiming();
    timing.reverseCurve = new Interval(0.0, _kMenuCloseIntervalEnd);
    result.timing = timing;
    return result;
  }

  Duration get transitionDuration => _kMenuDuration;
  bool get barrierDismissable => true;
  Color get barrierColor => null;

  Widget buildPage(BuildContext context) => new _PopupMenu(route: this);
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
