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
  ValuePerformance<Size> _size;

  void initState() {
    super.initState();
    _size = new ValuePerformance(
      variable: new AnimatedSizeValue(config.size, curve: config.curve),
      duration: config.duration
    )..addListener(() {
      setState(() {});
    });
  }

  void didUpdateConfig(SmoothlyResizingOverflowBox oldConfig) {
    _size.duration = config.duration;
    _size.variable.curve = config.curve;
    if (config.size != oldConfig.size) {
      AnimatedSizeValue variable = _size.variable;
      variable.begin = variable.value;
      variable.end = config.size;
      _size.progress = 0.0;
      _size.play();
    }
  }

  void dispose() {
    _size.stop();
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
    this.enterPerformance,
    this.enterTransition
  });

  final Widget child;
  final Performance enterPerformance;
  final Widget enterTransition;

  Size childSize = Size.zero;

  Performance exitPerformance;
  Widget exitTransition;

  Widget get currentTransition => exitTransition ?? enterTransition;

  void dispose() {
    enterPerformance?.stop();
    exitPerformance?.stop();
  }
}

typedef Widget TransitionBuilderCallback(PerformanceView performance, Widget child);

Widget _identityTransition(PerformanceView performance, Widget child) => child;

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
    Performance enterPerformance = new Performance(duration: config.duration)..play();
    return new _Entry(
      child: config.child,
      enterPerformance: enterPerformance,
      enterTransition: config.onEnter(enterPerformance, new KeyedSubtree(
        key: new GlobalKey(),
        child: config.child
      ))
    );
  }

  Future _createExitTransition(_Entry entry) async {
    Performance exitPerformance = new Performance(duration: config.duration);
    entry
      ..exitPerformance = exitPerformance
      ..exitTransition = config.onExit(exitPerformance, entry.enterTransition);
    await exitPerformance.play();
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
      child: new Stack(_entries.map((_Entry entry) {
        return new SizeObserver(
          key: new ObjectKey(entry),
          onSizeChanged: (Size newSize) {
            setState(() {
              entry.childSize = newSize;
            });
          },
          child: entry.currentTransition
        );
      }).toList())
    );
  }
}
