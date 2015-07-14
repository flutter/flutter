// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

enum PopupMenuStatus {
  active,
  inactive,
}

typedef void PopupMenuStatusChangedCallback(PopupMenuStatus status);

class PopupMenu extends AnimatedComponent {

  PopupMenu({
    String key,
    this.showing,
    this.onStatusChanged,
    this.items,
    this.level
  }) : super(key: key);

  bool showing;
  PopupMenuStatusChangedCallback onStatusChanged;
  List<PopupMenuItem> items;
  int level;

  AnimatedType<double> _position;
  AnimationPerformance _performance;

  void initState() {
    _position = new AnimatedType<double>(0.0, end: 1.0);
    _performance = new AnimationPerformance()
      ..variable = _position
      ..addListener(_checkForStateChanged);
    watch(_performance);
    _updateBoxPainter();
    if (showing)
      _open();
  }

  void syncFields(PopupMenu source) {
    if (showing != source.showing) {
      showing = source.showing;
      if (showing)
        _open();
      else
        _close();
    }
    onStatusChanged = source.onStatusChanged;
    if (level != source.level) {
      level = source.level;
      _updateBoxPainter();
    }
    items = source.items;
    super.syncFields(source);
  }

  void _updateBoxPainter() {
    _painter = new BoxPainter(new BoxDecoration(
      backgroundColor: Grey[50],
      borderRadius: 2.0,
      boxShadow: shadows[level]));
  }

  PopupMenuStatus get _status => _position.value != 0.0 ? PopupMenuStatus.active : PopupMenuStatus.inactive;

  PopupMenuStatus _lastStatus;
  void _checkForStateChanged() {
    PopupMenuStatus status = _status;
    if (_lastStatus != null && status != _lastStatus && onStatusChanged != null)
      onStatusChanged(status);
    _lastStatus = status;
  }

  void _open() {
    _performance
      ..duration = _kMenuOpenDuration
      ..play();
  }

  void _close() {
    _performance
      ..duration = _kMenuCloseDuration
      ..reverse();
  }

  BoxPainter _painter;

  double _opacityFor(int i) {
    assert(_position.value != null);
    if (_position.value == null || _position.value == 1.0)
      return 1.0;
    double unit = 1.0 / items.length;
    double duration = 1.5 * unit;
    double start = i * unit;
    return math.max(0.0, math.min(1.0, (_position.value - start) / duration));
  }

  Widget build() {
    int i = 0;
    List<Widget> children = new List.from(items.map((Widget item) {
      double opacity = _opacityFor(i);
      return new PopupMenuItem(child: item, opacity: opacity);
    }));

    return new Opacity(
      opacity: math.min(1.0, _position.value * 3.0),
      child: new Container(
        margin: new EdgeDims.all(_kMenuMargin),
        child: new CustomPaint(
          callback: (sky.Canvas canvas, Size size) {
            double width = math.min(size.width, size.width * (0.5 + _position.value * 2.0));
            double height = math.min(size.height, size.height * _position.value * 1.5);
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
