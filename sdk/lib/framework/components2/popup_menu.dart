// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../fn2.dart';
import '../theme2/colors.dart';
import '../theme2/shadows.dart';
import 'animated_component.dart';
import 'dart:async';
import 'dart:math' as math;
import 'material.dart';
import 'popup_menu_item.dart';

const double _kMenuOpenDuration = 300.0;
const double _kMenuCloseDuration = 200.0;
const double _kMenuCloseDelay = 100.0;

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
  List<List<UINode>> items;
  int level;
  PopupMenuController controller;

  double _position;
  // int _width;
  // int _height;

  PopupMenu({ Object key, this.controller, this.items, this.level })
      : super(key: key) {
    animateField(controller.position, #_position);
    // onDidMount(_measureSize);
  }

  double _opacityFor(int i) {
    if (_position == null || _position == 1.0)
      return null;
    double unit = 1.0 / items.length;
    double duration = 1.5 * unit;
    double start = i * unit;
    return math.max(0.0, math.min(1.0, (_position - start) / duration));
  }

  // String _inlineStyle() {
  //   if (_position == null || _position == 1.0 ||
  //       _height == null || _width == null)
  //     return null;
  //   return '''
  //     opacity: ${math.min(1.0, _position * 3.0)};
  //     width: ${math.min(_width, _width * (0.5 + _position * 2.0))}px;
  //     height: ${math.min(_height, _height * _position * 1.5)}px;''';
  // }

  // void _measureSize() {
  //   setState(() {
  //     var root = getRoot();
  //     _width = root.width.round();
  //     _height = root.height.round();
  //   });
  // }

  UINode build() {
    int i = 0;
    List<UINode> children = new List.from(items.map((List<UINode> item) {
      double opacity = _opacityFor(i);
      return new PopupMenuItem(key: i++, children: item, opacity: opacity);
    }));

    // border-radius: 2px
    // inlineStyle: _inlineStyle(),
    return new ShrinkWrapWidth(
      child: new Container(
        padding: const EdgeDims.all(8.0),
        decoration: new BoxDecoration(
          backgroundColor: Grey[50],
          boxShadow: Shadow[level]),
        child: new BlockContainer(children: children)
      )
    );
  }
}
