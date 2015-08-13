// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/painting/box_painter.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/theme/shadows.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/popup_menu_item.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/transitions.dart';

export 'package:sky/animation/animation_performance.dart' show AnimationStatus;

const Duration _kMenuDuration = const Duration(milliseconds: 300);
double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuMargin = 16.0; // 24.0 on tablet
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuVerticalPadding = 8.0;

typedef void PopupMenuDismissedCallback();

class PopupMenu extends StatefulComponent {

  PopupMenu({
    Key key,
    this.showing,
    this.onDismissed,
    this.items,
    this.level,
    this.navigator
  }) : super(key: key);

  bool showing;
  PopupMenuDismissedCallback onDismissed;
  List<PopupMenuItem> items;
  int level;
  Navigator navigator;

  AnimationPerformance _performance;

  void initState() {
    _performance = new AnimationPerformance()
      ..duration = _kMenuDuration;
    _performance.timing = new AnimationTiming()
      ..reverseInterval = new Interval(0.0, _kMenuCloseIntervalEnd);
    _updateBoxPainter();

    if (showing)
      _open();
  }

  void syncFields(PopupMenu source) {
    if (!showing && source.showing)
      _open();
    showing = source.showing;
    if (level != source.level) {
      level = source.level;
      _updateBoxPainter();
    }
    items = source.items;
    navigator = source.navigator;
  }

  void _open() {
    navigator.pushState(this, (_) => _close());
  }

  void _close() {
    _performance.reverse();
  }

  void _updateBoxPainter() {
    _painter = new BoxPainter(new BoxDecoration(
      backgroundColor: Grey[50],
      borderRadius: 2.0,
      boxShadow: shadows[level]));
  }

  void _onDismissed() {
    if (navigator != null &&
        navigator.currentRoute is RouteState &&
        (navigator.currentRoute as RouteState).owner == this) // TODO(ianh): remove cast once analyzer is cleverer
      navigator.pop();
    if (onDismissed != null)
      onDismissed();
  }

  BoxPainter _painter;

  Widget build() {
    double unit = 1.0 / (items.length + 1.5); // 1.0 for the width and 0.5 for the last item's fade.
    List<Widget> children = [];
    for (int i = 0; i < items.length; ++i) {
      double start = (i + 1) * unit;
      double end = (start + 1.5 * unit).clamp(0.0, 1.0);
      children.add(new FadeTransition(
        direction: showing ? Direction.forward : Direction.reverse,
        performance: _performance,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, interval: new Interval(start, end)),
        child: items[i]));
    }

    final width = new AnimatedValue<double>(0.0, end: 1.0, interval: new Interval(0.0, unit));
    final height = new AnimatedValue<double>(0.0, end: 1.0, interval: new Interval(0.0, unit * items.length));
    return new FadeTransition(
      direction: showing ? Direction.forward : Direction.reverse,
      performance: _performance,
      onDismissed: _onDismissed,
      opacity: new AnimatedValue<double>(0.0, end: 1.0, interval: new Interval(0.0, 1.0 / 3.0)),
      child: new Container(
        margin: new EdgeDims.all(_kMenuMargin),
        child: new BuilderTransition(
          direction: showing ? Direction.forward : Direction.reverse,
          performance: _performance,
          variables: [width, height],
          builder: () {
            return new CustomPaint(
              callback: (sky.Canvas canvas, Size size) {
                double widthValue = width.value * size.width;
                double heightValue = height.value * size.height;
                _painter.paint(canvas, new Rect.fromLTWH(size.width - widthValue, 0.0, widthValue, heightValue));
              },
              child: new ConstrainedBox(
                constraints: new BoxConstraints(
                  minWidth: _kMenuMinWidth,
                  maxWidth: _kMenuMaxWidth
                ),
                child: new ShrinkWrapWidth(
                  stepWidth: _kMenuWidthStep,
                  child: new ScrollableViewport(
                    child: new Container(
                      padding: const EdgeDims.symmetric(
                        horizontal: _kMenuHorizontalPadding,
                        vertical: _kMenuVerticalPadding
                      ),
                      child: new Block(children)
                    )
                  )
                )
              )
            );
          }
        )
      )
    );
  }

}
