// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'animated_component.dart';
import '../animation/animated_value.dart';
import '../fn.dart';
import '../theme/colors.dart';
import '../theme/view-configuration.dart';
import 'dart:math' as math;
import 'dart:sky' as sky;
import 'material.dart';
import 'popup_menu_item.dart';

const double _kItemFadeDuration = 300.0;
const double _kItemFadeDelay = 100.0;
const double _kMenuExpandDuration = 300.0;

class PopupMenuController {
  bool isOpen = false;
  AnimatedValue position = new AnimatedValue(0.0);

  void open() {
    isOpen = true;
    position.animateTo(1.0, _kMenuExpandDuration);
  }

  void close() {
    position.animateTo(0.0, _kMenuExpandDuration);
    // TODO(abarth): We shouldn't mark the menu as closed until the animation
    // completes.
    isOpen = false;
  }
}

class PopupMenu extends AnimatedComponent {
  static final Style _style = new Style('''
    border-radius: 2px;
    padding: 8px 0;
    box-sizing: border-box;
    background-color: ${Grey[50]};''');

  List<List<Node>> items;
  int level;
  PopupMenuController controller;

  double _position;
  List<AnimatedValue> _opacities;
  int _width;
  int _height;

  PopupMenu({ Object key, this.controller, this.items, this.level })
      : super(key: key) {
    animateField(controller.position, #_position);

    onDidMount(_measureSize);
  }

  void _ensureItemAnimations() {
    if (_opacities != null && controller.isOpen)
      return;
    _opacities = new List.from(items.map((_) => new AnimatedValue(0.0)));
    int i = 0;
    _opacities.forEach((opacity) {
      opacity.animateTo(1.0, _kItemFadeDuration,
                        initialDelay: _kItemFadeDelay * ++i);
    });
  }

  String _inlineStyle() {
    if (_position == null || _position == 1.0 || _height == null || _width == null)
      return null;
    return '''
      opacity: ${math.min(1.0, _position * 1.5)};
      width: ${math.min(_width, _width * _position * 3.0)}px;
      height: ${_height * _position}px;''';
  }

  void _measureSize() {
    setState(() {
      var root = getRoot();
      _width = root.clientWidth;
      _height = root.clientHeight;
    });
  }

  Node build() {
    _ensureItemAnimations();

    List<Node> children = [];

    if (controller.isOpen) {
      int i = 0;
      items.forEach((List<Node> item) {
        children.add(
            new PopupMenuItem(key: i, children: item, opacity: _opacities[i]));
        ++i;
      });
    }

    return new Material(
      style: _style,
      inlineStyle: _inlineStyle(),
      children: children,
      level: level
    );
  }
}
