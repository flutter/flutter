// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';

class SmoothlyResizingOverflowBox extends StatefulComponent {
  SmoothlyResizingOverflowBox({
    Key key,
    this.child,
    this.size,
    this.duration,
    this.curve: Curves.linear
  }) : super(key: key) {
    assert(duration != null);
    assert(curve != null);
  }

  final Widget child;
  final Size size;
  final Duration duration;
  final Curve curve;

  _SmoothlyResizingOverflowBoxState createState() => new _SmoothlyResizingOverflowBoxState();
}

class _SmoothlyResizingOverflowBoxState extends State<SmoothlyResizingOverflowBox> {
  SizeTween _sizeTween;
  CurveTween _curveTween;
  Animation<Size> _size;
  AnimationController _sizeController;

  void initState() {
    super.initState();
    _sizeController = new AnimationController(duration: config.duration);
    _sizeTween = new SizeTween(begin: config.size);
    _curveTween = new CurveTween(curve: config.curve);
    _size = _sizeTween.chain(_curveTween).animate(_sizeController)
      ..addListener(() {
        setState(() {});
      });
  }

  void didUpdateConfig(SmoothlyResizingOverflowBox oldConfig) {
    bool needsAnimation = false;
    if (config.size != oldConfig.size) {
      _sizeTween
        ..begin = _size.value
        ..end = config.size;
      needsAnimation = true;
    }
    _sizeController.duration = config.duration;
    _curveTween.curve = config.curve;
    if (needsAnimation) {
      _sizeController
        ..value = 0.0
        ..forward();
    }
  }

  void dispose() {
    _sizeController.stop();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return new SizedOverflowBox(
      size: _size.value,
      child: config.child
    );
  }
}

class _Entry {
  _Entry({
    this.child,
    this.enterController,
    this.enterTransition
  });

  final Widget child;
  final AnimationController enterController;
  final Widget enterTransition;

  Size childSize = Size.zero;

  AnimationController exitController;
  Widget exitTransition;

  Widget get currentTransition => exitTransition ?? enterTransition;

  void dispose() {
    enterController?.stop();
    exitController?.stop();
  }
}

typedef Widget TransitionBuilderCallback(Animation<double> animation, Widget child);

Widget _identityTransition(Animation<double> animation, Widget child) => child;

class EnterExitTransition extends StatefulComponent {
  EnterExitTransition({
    Key key,
    this.child,
    this.duration,
    this.curve: Curves.linear,
    this.onEnter: _identityTransition,
    this.onExit: _identityTransition
  }) : super(key: key) {
    assert(child != null);
    assert(duration != null);
    assert(curve != null);
    assert(onEnter != null);
    assert(onExit != null);
  }

  final Widget child;
  final Duration duration;
  final Curve curve;
  final TransitionBuilderCallback onEnter;
  final TransitionBuilderCallback onExit;

  _EnterExitTransitionState createState() => new _EnterExitTransitionState();
}

class _EnterExitTransitionState extends State<EnterExitTransition> {
  final List<_Entry> _entries = new List<_Entry>();

  void initState() {
    super.initState();
    _entries.add(_createEnterTransition());
  }

  _Entry _createEnterTransition() {
    AnimationController enterController = new AnimationController(duration: config.duration)..forward();
    return new _Entry(
      child: config.child,
      enterController: enterController,
      enterTransition: config.onEnter(enterController, new KeyedSubtree(
        key: new GlobalKey(),
        child: config.child
      ))
    );
  }

  Future _createExitTransition(_Entry entry) async {
    AnimationController exitController = new AnimationController(duration: config.duration);
    entry
      ..exitController = exitController
      ..exitTransition = config.onExit(exitController, entry.enterTransition);
    await exitController.forward();
    if (!mounted)
      return;
    setState(() {
      _entries.remove(entry);
    });
  }

  void didUpdateConfig(EnterExitTransition oldConfig) {
    if (config.child.key != oldConfig.child.key) {
      _createExitTransition(_entries.last);
      _entries.add(_createEnterTransition());
    }
  }

  void dispose() {
    for (_Entry entry in new List<_Entry>.from(_entries))
      entry.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return new SmoothlyResizingOverflowBox(
      size: _entries.last.childSize,
      duration: config.duration,
      curve: config.curve,
      child: new Stack(
        children: _entries.map((_Entry entry) {
          return new SizeObserver(
            key: new ObjectKey(entry),
            onSizeChanged: (Size newSize) {
              setState(() {
                entry.childSize = newSize;
              });
            },
            child: entry.currentTransition
          );
        }).toList()
      )
    );
  }
}
