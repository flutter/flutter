// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/painting/box_painter.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/theme/shadows.dart';
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/popup_menu_item.dart';
import 'package:sky/widgets/scrollable_viewport.dart';

const Duration _kMenuOpenDuration = const Duration(milliseconds: 300);
const Duration _kMenuCloseDuration = const Duration(milliseconds: 200);
const Duration _kMenuCloseDelay = const Duration(milliseconds: 100);
const double _kMenuWidthStep = 56.0;
const double _kMenuMargin = 16.0; // 24.0 on tablet
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuVerticalPadding = 8.0;

enum MenuState { closed, opening, open, closing }

class PopupMenuController {

  PopupMenuController() {
    position = new AnimatedType<double>(0.0, end: 1.0);
    performance = new AnimationPerformance()
      ..variable = position
      ..addListener(_updateState);
  }

  AnimatedType<double> position;
  AnimationPerformance performance;

  MenuState _state = MenuState.closed;
  MenuState get state => _state;

  bool get canReact => (_state == MenuState.opening) || (_state == MenuState.open);

  void _updateState() {
    if (position.value == 0.0) {
      _state = MenuState.closed;
      if (_closeCompleter != null)
        _closeCompleter.complete();
      return;
    }

    if (position.value == 1.0)
      _state = MenuState.open;
  }

  Completer _closeCompleter;
  Timer _closeTimer;

  void open() {
    if (_state != MenuState.closed)
      return;
    if (_closeTimer != null) {
      _closeTimer.cancel();
      _closeTimer = null;
    }
    _closeCompleter = null;
    _state = MenuState.opening;
    performance..duration = _kMenuOpenDuration
               ..play();
  }

  Future close() {
    if (_state == MenuState.closing || _state == MenuState.closed)
      return _closeCompleter.future;

    _state = MenuState.closing;
    assert(_closeCompleter == null);
    _closeCompleter = new Completer();
    performance.duration = _kMenuCloseDuration;

    assert(_closeTimer == null);
    _closeTimer = new Timer(_kMenuCloseDelay, performance.reverse);

    return _closeCompleter.future;
  }
}

class PopupMenu extends AnimatedComponent {

  PopupMenu({ String key, this.controller, this.items, this.level })
      : super(key: key);

  PopupMenuController controller;
  List<PopupMenuItem> items;
  int level;

  void initState() {
    _painter = new BoxPainter(new BoxDecoration(
      backgroundColor: Grey[50],
      borderRadius: 2.0,
      boxShadow: shadows[level]));
    watch(controller.performance);
  }

  void syncFields(PopupMenu source) {
    controller = source.controller;
    items = source.items;
    level = source.level;
    _painter = source._painter;
    super.syncFields(source);
  }

  BoxPainter _painter;

  double _opacityFor(int i) {
    assert(controller.position.value != null);
    if (controller.position.value == null || controller.position.value == 1.0)
      return 1.0;
    double unit = 1.0 / items.length;
    double duration = 1.5 * unit;
    double start = i * unit;
    return math.max(0.0, math.min(1.0, (controller.position.value - start) / duration));
  }

  Widget build() {
    int i = 0;
    List<Widget> children = new List.from(items.map((Widget item) {
      double opacity = _opacityFor(i);
      return new PopupMenuItem(child: item, opacity: opacity);
    }));

    return new Opacity(
      opacity: math.min(1.0, controller.position.value * 3.0),
      child: new Container(
        margin: new EdgeDims.all(_kMenuMargin),
        child: new CustomPaint(
          callback: (sky.Canvas canvas, Size size) {
            double width = math.min(size.width, size.width * (0.5 + controller.position.value * 2.0));
            double height = math.min(size.height, size.height * controller.position.value * 1.5);
            _painter.paint(canvas, new Rect.fromLTRB(size.width - width, 0.0, width, height));
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
        )
      )
    );
  }

}
