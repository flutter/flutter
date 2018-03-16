// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

class _AutoFadeChildEntry {
  _AutoFadeChildEntry(this.widget, this.controller, this.animation);

  Widget widget;

  final AnimationController controller;
  final Animation<double> animation;
}

/// A widget that automatically does a [FadeTransition] between a new widget and
/// any widgets previously set on the [AutoFade] as a child.
///
/// See also:
///
///  * [FadeTransition] which [AutoFade] uses to perform the transition.
class AutoFade extends StatefulWidget {
  const AutoFade({
    Key key,
    this.child,
    this.curve: Curves.linear,
    this.alignment: Alignment.center,
    @required this.duration,
  })  : assert(curve != null),
        assert(duration != null),
        super(key: key);

  /// The current child widget to display.  If there was a previous child,
  /// then that child will be cross faded with this child using a
  /// [FadeTransition] using the [curve].
  ///
  /// If there was no previous child, then this child will fade in over the
  /// [duration].
  final Widget child;

  /// The animation curve to use when performing the cross fade between the
  /// the current and previous widgets.
  final Curve curve;

  /// The duration over which to perform the cross fade using [FadeTransition].
  final Duration duration;

  /// The alignment of the current and previous [child] widgets inside of this
  /// widget.
  final AlignmentGeometry alignment;

  @override
  _AutoFadeState createState() => new _AutoFadeState();
}

class _AutoFadeState extends State<AutoFade> with TickerProviderStateMixin {
  final Set<_AutoFadeChildEntry> _children = new Set<_AutoFadeChildEntry>();
  _AutoFadeChildEntry _currentChild;

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
      curve: widget.curve,
    );
    final _AutoFadeChildEntry entry = new _AutoFadeChildEntry(
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
    for (_AutoFadeChildEntry child in _children) {
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
    for (_AutoFadeChildEntry child in _children) {
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
      alignment: widget.alignment,
    );
  }
}
