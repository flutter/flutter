// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

import 'ink_well.dart';
import 'popup_menu_item.dart';
import 'shadows.dart';
import 'theme.dart';

const Duration _kMenuDuration = const Duration(milliseconds: 300);
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuVerticalPadding = 8.0;

class _PopupMenu extends StatelessComponent {
  _PopupMenu({
    Key key,
    this.route
  }) : super(key: key);

  final _MenuRoute route;

  Widget build(BuildContext context) {
    final BoxPainter painter = new BoxPainter(new BoxDecoration(
      backgroundColor: Theme.of(context).canvasColor,
      borderRadius: 2.0,
      boxShadow: shadows[route.level]
    ));

    double unit = 1.0 / (route.items.length + 1.5); // 1.0 for the width and 0.5 for the last item's fade.
    List<Widget> children = <Widget>[];

    for (int i = 0; i < route.items.length; ++i) {
      double start = (i + 1) * unit;
      double end = (start + 1.5 * unit).clamp(0.0, 1.0);
      children.add(new FadeTransition(
        performance: route.performance,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(start, end)),
        child: new InkWell(
          onTap: () { Navigator.of(context).pop(route.items[i].value); },
          child: route.items[i]
        ))
      );
    }

    final AnimatedValue<double> width = new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, unit));
    final AnimatedValue<double> height = new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, unit * route.items.length));

    return new Positioned(
      top: route.position?.top,
      right: route.position?.right,
      bottom: route.position?.bottom,
      left: route.position?.left,
      child: new Focus(
        key: new GlobalObjectKey(route),
        autofocus: true,
        child: new FadeTransition(
          performance: route.performance,
          opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, 1.0 / 3.0)),
          child: new BuilderTransition(
            performance: route.performance,
            variables: <AnimatedValue<double>>[width, height],
            builder: (BuildContext context) {
              return new CustomPaint(
                onPaint: (ui.Canvas canvas, Size size) {
                  double widthValue = width.value * size.width;
                  double heightValue = height.value * size.height;
                  painter.paint(canvas, new Rect.fromLTWH(size.width - widthValue, 0.0, widthValue, heightValue));
                },
                child: new ConstrainedBox(
                  constraints: new BoxConstraints(
                    minWidth: _kMenuMinWidth,
                    maxWidth: _kMenuMaxWidth
                  ),
                  child: new IntrinsicWidth(
                    stepWidth: _kMenuWidthStep,
                    child: new ScrollableViewport(
                      child: new Container(
                        // TODO(abarth): Teach Block about padding.
                        padding: const EdgeDims.symmetric(
                          horizontal: _kMenuHorizontalPadding,
                          vertical: _kMenuVerticalPadding
                        ),
                        child: new BlockBody(children)
                      )
                    )
                  )
                )
              );
            }
          )
        )
      )
    );
  }
}

class MenuPosition {
  const MenuPosition({ this.top, this.right, this.bottom, this.left });
  final double top;
  final double right;
  final double bottom;
  final double left;
}

class _MenuRoute extends TransitionRoute {
  _MenuRoute({ this.completer, this.position, this.items, this.level });

  final Completer completer;
  final MenuPosition position;
  final List<PopupMenuItem> items;
  final int level;

  Performance createPerformance() {
    Performance result = super.createPerformance();
    AnimationTiming timing = new AnimationTiming();
    timing.reverseCurve = new Interval(0.0, _kMenuCloseIntervalEnd);
    result.timing = timing;
    return result;
  }

  bool get opaque => false;
  Duration get transitionDuration => _kMenuDuration;

  List<Widget> createWidgets() => [
    new ModalBarrier(),
    new _PopupMenu(route: this),
  ];

  void didPop([dynamic result]) {
    completer.complete(result);
    super.didPop(result);
  }
}

Future showMenu({ BuildContext context, MenuPosition position, List<PopupMenuItem> items, int level: 4 }) {
  Completer completer = new Completer();
  Navigator.of(context).pushEphemeral(new _MenuRoute(
    completer: completer,
    position: position,
    items: items,
    level: level
  ));
  return completer.future;
}
