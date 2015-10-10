// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as sky;

import 'package:sky/animation.dart';
import 'package:sky/painting.dart';
import 'package:sky/widgets.dart';

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

typedef List<PopupMenuItem> PopupMenuItemsBuilder(NavigatorState navigator);

class PopupMenu extends StatelessComponent {
  PopupMenu({
    Key key,
    this.items,
    this.level: 4,
    this.navigator,
    this.performance
  }) : super(key: key) {
    assert(items != null);
    assert(performance != null);
  }

  final List<PopupMenuItem> items;
  final int level;
  final NavigatorState navigator;
  final PerformanceView performance;

  Widget build(BuildContext context) {
    final BoxPainter painter = new BoxPainter(new BoxDecoration(
      backgroundColor: Theme.of(context).canvasColor,
      borderRadius: 2.0,
      boxShadow: shadows[level]
    ));

    double unit = 1.0 / (items.length + 1.5); // 1.0 for the width and 0.5 for the last item's fade.
    List<Widget> children = [];

    for (int i = 0; i < items.length; ++i) {
      double start = (i + 1) * unit;
      double end = (start + 1.5 * unit).clamp(0.0, 1.0);
      children.add(new FadeTransition(
        performance: performance,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(start, end)),
        child: new InkWell(
          onTap: () { navigator.pop(items[i].value); },
          child: items[i]
        ))
      );
    }

    final width = new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, unit));
    final height = new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, unit * items.length));

    return new FadeTransition(
      performance: performance,
      opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: new Interval(0.0, 1.0 / 3.0)),
      child: new BuilderTransition(
        performance: performance,
        variables: [width, height],
        builder: (BuildContext context) {
          return new CustomPaint(
            callback: (sky.Canvas canvas, Size size) {
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

class _MenuRoute extends PerformanceRoute {
  _MenuRoute({ this.completer, this.position, this.builder, this.level });

  final Completer completer;
  final MenuPosition position;
  final PopupMenuItemsBuilder builder;
  final int level;

  Performance createPerformance() {
    Performance result = super.createPerformance();
    AnimationTiming timing = new AnimationTiming();
    timing.reverseCurve = new Interval(0.0, _kMenuCloseIntervalEnd);
    result.timing = timing;
    return result;
  }

  bool get ephemeral => true;
  bool get modal => true;
  bool get opaque => false;
  Duration get transitionDuration => _kMenuDuration;

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance) {
    return new Positioned(
      top: position?.top,
      right: position?.right,
      bottom: position?.bottom,
      left: position?.left,
      child: new Focus(
        key: new GlobalObjectKey(this),
        autofocus: true,
        child: new PopupMenu(
          items: builder != null ? builder(navigator) : const <PopupMenuItem>[],
          level: level,
          navigator: navigator,
          performance: performance
        )
      )
    );
  }

  void didPop([dynamic result]) {
    completer.complete(result);
    super.didPop(result);
  }
}

Future showMenu({ NavigatorState navigator, MenuPosition position, PopupMenuItemsBuilder builder, int level: 4 }) {
  Completer completer = new Completer();
  navigator.push(new _MenuRoute(
    completer: completer,
    position: position,
    builder: builder,
    level: level
  ));
  return completer.future;
}
