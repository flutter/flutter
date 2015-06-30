// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;

import '../animation/animated_value.dart';
import '../painting/box_painter.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import 'animated_component.dart';
import 'basic.dart';
import 'popup_menu_item.dart';

const double _kMenuOpenDuration = 300.0;
const double _kMenuCloseDuration = 200.0;
const double _kMenuCloseDelay = 100.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuMinWidth = 1.5 * _kMenuWidthStep;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuVerticalPadding = 8.0;

enum MenuState { hidden, opening, open, closing }

class PopupMenuController {
  AnimatedValue position = new AnimatedValue(0.0);
  MenuState _state = MenuState.hidden;
  MenuState get state => _state;

  bool get canReact => (_state == MenuState.opening) || (_state == MenuState.open);

  open() async {
    if (_state != MenuState.hidden)
      return;
    _state = MenuState.opening;
    if (await position.animateTo(1.0, _kMenuOpenDuration) == 1.0)
      _state = MenuState.open;
  }

  Future _closeState;
  close() async {
    var result = new Completer();
    _closeState = result.future;
    if ((_state == MenuState.opening) || (_state == MenuState.open)) {
      _state = MenuState.closing;
      await position.animateTo(0.0, _kMenuCloseDuration, initialDelay: _kMenuCloseDelay);
      _state = MenuState.hidden;
      _closeState = null;
      result.complete();
      return result.future;
    }
    assert(_closeState != null);
    return _closeState;
  }
}

class PopupMenu extends AnimatedComponent {

  PopupMenu({ String key, this.controller, this.items, this.level })
      : super(key: key) {
    _painter = new BoxPainter(new BoxDecoration(
      backgroundColor: Grey[50],
      borderRadius: 2.0,
      boxShadow: shadows[level]));
    watch(controller.position);
  }

  PopupMenuController controller;
  List<PopupMenuItem> items;
  int level;

  void syncFields(PopupMenu source) {
    controller = source.controller;
    items = source.items;
    level = source.level;
    _painter = source._painter;
    super.syncFields(source);
  }

  BoxPainter _painter;

  double _opacityFor(int i) {
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
      child: new CustomPaint(
        callback: (sky.Canvas canvas, Size size) {
          double width = math.min(size.width, size.width * (0.5 + controller.position.value * 2.0));
          double height = math.min(size.height, size.height * controller.position.value * 1.5);
          _painter.paint(canvas, new Rect.fromLTRB(size.width - width, 0.0, width, height));
        },
        child: new ConstrainedBox(
          constraints: new BoxConstraints(
            minWidth: _kMenuMinWidth
          ),
          child: new ShrinkWrapWidth(
            stepWidth: _kMenuWidthStep,
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

}
