// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/animated_container.dart';
import 'package:sky/widgets/animation_intentions.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/theme.dart';

export 'package:sky/animation/animation_performance.dart' show AnimationStatus;

typedef void SnackBarStatusChangedCallback(AnimationStatus status);

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

  SlideInIntention _intention;

  void initState() {
    _intention = new SlideInIntention(duration: _kSlideInDuration,
                                      start: const Point(0.0, 50.0),
                                      end: Point.origin);
    _intention.performance.addStatusListener(_onStatusChanged);
  }

  void syncFields(SnackBar source) {
    content = source.content;
    actions = source.actions;
    onStatusChanged = source.onStatusChanged;
    showing = source.showing;
  }

  void _onStatusChanged(AnimationStatus status) {
    if (onStatusChanged != null)
      scheduleMicrotask(() { onStatusChanged(status); });
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
