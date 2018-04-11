// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

class _AnimatedChildSwitcherChildEntry {
  _AnimatedChildSwitcherChildEntry(this.widget, this.controller, this.animation);

  Widget widget;

  final AnimationController controller;
  final Animation<double> animation;
}

/// A widget that automatically does a [FadeTransition] between a new widget and
/// the widget previously set on the [AnimatedChildSwitcher] as a child.
///
/// More than one previous child can exist and be fading out while the newest
/// one is fading in if they are swapped fast enough (i.e. before [duration]
/// elapses).
///
/// See also:
///
///  * [AnimatedCrossFade], which only fades between two children, but also
///    interpolates their sizes, and is reversible.
///  * [FadeTransition] which [AnimatedChildSwitcher] uses to perform the transition.
class AnimatedChildSwitcher extends StatefulWidget {
  /// The [duration], [switchInCurve], and [switchOutCurve] parameters must not
  /// be null.
  const AnimatedChildSwitcher({
    Key key,
    this.child,
    this.switchInCurve: Curves.linear,
    this.switchOutCurve: Curves.linear,
    @required this.duration,
  })  : assert(switchInCurve != null),
        assert(switchOutCurve != null),
        assert(duration != null),
        super(key: key);

  /// The current child widget to display.  If there was a previous child,
  /// then that child will be cross faded with this child using a
  /// [FadeTransition] using the [switchInCurve].
  ///
  /// If there was no previous child, then this child will fade in over the
  /// [duration].
  final Widget child;

  /// The animation curve to use when fading in the current widget.
  final Curve switchInCurve;

  /// The animation curve to use when fading out the previous widgets.
  final Curve switchOutCurve;

  /// The duration over which to perform the cross fade using [FadeTransition].
  final Duration duration;

  @override
  _AnimatedChildSwitcherState createState() => new _AnimatedChildSwitcherState();
}

class _AnimatedChildSwitcherState extends State<AnimatedChildSwitcher> with TickerProviderStateMixin {
  final Set<_AnimatedChildSwitcherChildEntry> _children = new Set<_AnimatedChildSwitcherChildEntry>();
  _AnimatedChildSwitcherChildEntry _currentChild;

  @override
  void initState() {
    super.initState();
    addEntry(false);
  }

  void addEntry(bool animate) {
    final AnimationController controller = new AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    if (animate) {
      if (_currentChild != null) {
        _currentChild.controller.reverse();
        _children.add(_currentChild);
      }
      controller.forward();
    } else {
      assert(_currentChild == null);
      assert(_children.isEmpty);
      controller.value = 1.0;
    }
    final Animation<double> animation = new CurvedAnimation(
      parent: controller,
      curve: widget.switchInCurve,
      reverseCurve: widget.switchOutCurve,
    );
    final _AnimatedChildSwitcherChildEntry entry = new _AnimatedChildSwitcherChildEntry(
      widget.child,
      controller,
      animation,
    );
    animation.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        assert(_children.contains(entry));
        setState(() {
          _children.remove(entry);
        });
        controller.dispose();
      }
    });
    _currentChild = entry;
  }

  @override
  void dispose() {
    if (_currentChild != null) {
      _currentChild.controller.dispose();
    }
    for (_AnimatedChildSwitcherChildEntry child in _children) {
      child.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child != _currentChild.widget) {
      addEntry(true);
    }
    final List<Widget> children = <Widget>[];
    for (_AnimatedChildSwitcherChildEntry child in _children) {
      children.add(
        new FadeTransition(
          opacity: child.animation,
          child: child.widget,
        ),
      );
    }
    if (_currentChild != null) {
      children.add(
        new FadeTransition(
          opacity: _currentChild.animation,
          child: _currentChild.widget,
        ),
      );
    }
    return new Stack(
      children: children,
      alignment: Alignment.center,
    );
  }
}
