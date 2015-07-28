// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/animated_container.dart';
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/theme.dart';

import 'package:vector_math/vector_math.dart';

enum SnackBarStatus {
  active,
  inactive,
}

typedef void SnackBarStatusChangedCallback(SnackBarStatus status);

const Duration _kSlideInDuration = const Duration(milliseconds: 200);

class SnackBarAction extends Component {
  SnackBarAction({Key key, this.label, this.onPressed }) : super(key: key) {
    assert(label != null);
  }

  final String label;
  final Function onPressed;

  Widget build() {
    return new Listener(
      onGestureTap: (_) => onPressed(),
      child: new Container(
        margin: const EdgeDims.only(left: 24.0),
        padding: const EdgeDims.only(top: 14.0, bottom: 14.0),
        child: new Text(label)
      )
    );
  }
}

// TODO(mpcomplete): generalize this to a SlideIn class.
class SnackBarSlideInIntention extends AnimationIntention {
  SnackBarSlideInIntention(this.duration, this.onStatusChanged);

  Duration duration;
  SnackBarStatusChangedCallback onStatusChanged;
  AnimatedValue<Point> _position;
  AnimationPerformance _performance;

  void initFields(AnimatedContainer container) {
    _position = new AnimatedValue<Point>(new Point(0.0, 50.0), end: Point.origin);
    _performance = new AnimationPerformance()
      ..duration = _kSlideInDuration
      ..variable = _position
      ..addListener(() { _updateProgress(container); });
    _performance.progress = 0.0;
    if (container.tag)
      _show();
  }

  void syncFields(AnimatedContainer original, AnimatedContainer updated) {
    if (original.tag != updated.tag) {
      original.tag = updated.tag;
      original.tag ? _show() : _hide();
    }
  }

  void _show() {
    _performance.play();
  }

  void _hide() {
    _performance.reverse();
  }

  SnackBarStatus _lastStatus;
  void _updateProgress(AnimatedContainer container) {
    container.setState(() {
      container.transform = new Matrix4.identity()
        ..translate(_position.value.x, _position.value.y);
    });

    SnackBarStatus status = _status;
    if (_lastStatus != null && status != _lastStatus && onStatusChanged != null)
      scheduleMicrotask(() { onStatusChanged(status); });
    _lastStatus = status;
  }

  SnackBarStatus get _status => _performance.isDismissed ? SnackBarStatus.inactive : SnackBarStatus.active;
}

class SnackBar extends StatefulComponent {

  SnackBar({
    Key key,
    this.content,
    this.actions,
    this.showing,
    this.onStatusChanged
  }) : super(key: key) {
    assert(content != null);
  }

  Widget content;
  List<SnackBarAction> actions;
  bool showing;
  SnackBarStatusChangedCallback onStatusChanged;

  SnackBarSlideInIntention _intention;

  void initState() {
    _intention = new SnackBarSlideInIntention(_kSlideInDuration, onStatusChanged);
  }

  void syncFields(SnackBar source) {
    content = source.content;
    actions = source.actions;
    onStatusChanged = source.onStatusChanged;
    showing = source.showing;
  }

  Widget build() {
    List<Widget> children = [
      new Flexible(
        child: new Container(
          margin: const EdgeDims.symmetric(vertical: 14.0),
          child: new DefaultTextStyle(
            style: typography.white.subhead,
            child: content
          )
        )
      )
    ]..addAll(actions);

    return new AnimatedContainer(
      intentions: [_intention],
      tag: showing,
      child: new Material(
        level: 2,
        color: const Color(0xFF323232),
        type: MaterialType.canvas,
        child: new Container(
          margin: const EdgeDims.symmetric(horizontal: 24.0),
          child: new DefaultTextStyle(
            style: new TextStyle(color: Theme.of(this).accentColor),
            child: new Flex(children)
          )
        )
      )
    );
  }
}
