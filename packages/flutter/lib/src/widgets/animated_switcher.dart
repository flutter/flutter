// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

// Internal representation of a child that, now or in the past, was set on the
// AnimatedSwitcher.child field, but is now in the process of
// transitioning. The internal representation includes fields that we don't want
// to expose to the public API (like the controller).
class _AnimatedSwitcherChildEntry {
  _AnimatedSwitcherChildEntry({
    @required this.animation,
    @required this.transition,
    @required this.controller,
    @required this.widgetChild,
  })  : assert(animation != null),
        assert(transition != null),
        assert(controller != null);

  final Animation<double> animation;

  // The currently built transition for this child.
  Widget transition;

  // The animation controller for the child's transition.
  final AnimationController controller;

  // The widget's child at the time this entry was created or updated.
  Widget widgetChild;
}

/// Signature for builders used to generate custom transitions for
/// [AnimatedSwitcher].
///
/// The [child] should be transitioning in when the [animation] is running in
/// the forward direction.
///
/// The function should return a widget which wraps the given [child]. It may
/// also use the [animation] to inform its transition. It must not return null.
typedef Widget AnimatedSwitcherTransitionBuilder(Widget child, Animation<double> animation);

/// Signature for builders used to generate custom layouts for
/// [AnimatedSwitcher].
///
/// The function should return a widget which contains the given children, laid
/// out as desired. It must not return null.
typedef Widget AnimatedSwitcherLayoutBuilder(List<Widget> children);

/// A widget that by default does a [FadeTransition] between a new widget and
/// the widget previously set on the [AnimatedSwitcher] as a child.
///
/// If they are swapped fast enough (i.e. before [duration] elapses), more than
/// one previous child can exist and be transitioning out while the newest one
/// is transitioning in.
///
/// If the "new" child is the same widget type as the "old" child, but with
/// different parameters, then [AnimatedSwitcher] will *not* do a
/// transition between them, since as far as the framework is concerned, they
/// are the same widget, and the existing widget can be updated with the new
/// parameters. If you wish to force the transition to occur, set a [Key]
/// (typically a [ValueKey] taking any widget data that would change the visual
/// appearance of the widget) on each child widget that you wish to be
/// considered unique.
///
/// ## Sample code
///
/// ```dart
/// class ClickCounter extends StatefulWidget {
///   const ClickCounter({Key key}) : super(key: key);
///
///   @override
///   _ClickCounterState createState() => new _ClickCounterState();
/// }
///
/// class _ClickCounterState extends State<ClickCounter> {
///   int _count = 0;
///
///   @override
///   Widget build(BuildContext context) {
///     return new Material(
///       child: Column(
///         mainAxisAlignment: MainAxisAlignment.center,
///         children: <Widget>[
///           new AnimatedSwitcher(
///             duration: const Duration(milliseconds: 200),
///             transitionBuilder: (Widget child, Animation<double> animation) {
///               return new ScaleTransition(child: child, scale: animation);
///             },
///             child: new Text(
///               '$_count',
///               // Must have this key to build a unique widget when _count changes.
///               key: new ValueKey<int>(_count),
///               textScaleFactor: 3.0,
///             ),
///           ),
///           new RaisedButton(
///             child: new Text('Click!'),
///             onPressed: () {
///               setState(() {
///                 _count += 1;
///               });
///             },
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// See also:
///
///  * [AnimatedCrossFade], which only fades between two children, but also
///    interpolates their sizes, and is reversible.
///  * [FadeTransition] which [AnimatedSwitcher] uses to perform the transition.
class AnimatedSwitcher extends StatefulWidget {
  /// Creates an [AnimatedSwitcher].
  ///
  /// The [duration], [transitionBuilder], [layoutBuilder], [switchInCurve], and
  /// [switchOutCurve] parameters must not be null.
  const AnimatedSwitcher({
    Key key,
    this.child,
    @required this.duration,
    this.switchInCurve: Curves.linear,
    this.switchOutCurve: Curves.linear,
    this.transitionBuilder: AnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder: AnimatedSwitcher.defaultLayoutBuilder,
  })  : assert(duration != null),
        assert(switchInCurve != null),
        assert(switchOutCurve != null),
        assert(transitionBuilder != null),
        assert(layoutBuilder != null),
        super(key: key);

  /// The current child widget to display.  If there was a previous child,
  /// then that child will be cross faded with this child using a
  /// [FadeTransition] using the [switchInCurve].
  ///
  /// If there was no previous child, then this child will fade in over the
  /// [duration].
  final Widget child;

  /// The duration of the transition from the old [child] value to the new one.
  final Duration duration;

  /// The animation curve to use when transitioning in [child].
  final Curve switchInCurve;

  /// The animation curve to use when transitioning the previous [child] out.
  final Curve switchOutCurve;

  /// A function that wraps the new [child] with an animation that transitions
  /// the [child] in when the animation runs in the forward direction and out
  /// when the animation runs in the reverse direction.
  ///
  /// The default is [AnimatedSwitcher.defaultTransitionBuilder].
  ///
  /// See also:
  ///
  ///  * [AnimatedSwitcherTransitionBuilder] for more information about
  ///    how a transition builder should function.
  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  /// A function that wraps all of the children that are transitioning out, and
  /// the [child] that's transitioning in, with a widget that lays all of them
  /// out.
  ///
  /// The default is [AnimatedSwitcher.defaultLayoutBuilder].
  ///
  /// See also:
  ///
  ///  * [AnimatedSwitcherLayoutBuilder] for more information about
  ///    how a layout builder should function.
  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  @override
  _AnimatedSwitcherState createState() => new _AnimatedSwitcherState();

  /// The default transition algorithm used by [AnimatedSwitcher].
  ///
  /// The new child is given a [FadeTransition] which increases opacity as
  /// the animation goes from 0.0 to 1.0, and decreases when the animation is
  /// reversed.
  ///
  /// The default value for the [transitionBuilder], an
  /// [AnimatedSwitcherTransitionBuilder] function.
  static Widget defaultTransitionBuilder(Widget child, Animation<double> animation) {
    return new FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// The default layout algorithm used by [AnimatedSwitcher].
  ///
  /// The new child is placed in a [Stack] that sizes itself to match the
  /// largest of the child or a previous child. The children are centered on
  /// each other.
  ///
  /// This is the default value for [layoutBuilder]. It implements
  /// [AnimatedSwitcherLayoutBuilder].
  static Widget defaultLayoutBuilder(List<Widget> children) {
    return new Stack(
      children: children,
      alignment: Alignment.center,
    );
  }
}

class _AnimatedSwitcherState extends State<AnimatedSwitcher> with TickerProviderStateMixin {
  final Set<_AnimatedSwitcherChildEntry> _children = new Set<_AnimatedSwitcherChildEntry>();
  _AnimatedSwitcherChildEntry _currentChild;

  @override
  void initState() {
    super.initState();
    _addEntry(animate: false);
  }

  Widget _generateTransition(Animation<double> animation) {
    return new KeyedSubtree(
      key: new UniqueKey(),
      child: widget.transitionBuilder(widget.child, animation),
    );
  }

  _AnimatedSwitcherChildEntry _newEntry({
    @required AnimationController controller,
    @required Animation<double> animation,
  }) {
    final _AnimatedSwitcherChildEntry entry = new _AnimatedSwitcherChildEntry(
      widgetChild: widget.child,
      transition: _generateTransition(animation),
      animation: animation,
      controller: controller,
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
    return entry;
  }

  void _addEntry({@required bool animate}) {
    if (widget.child == null) {
      if (animate && _currentChild != null) {
        _currentChild.controller.reverse();
        assert(!_children.contains(_currentChild));
        _children.add(_currentChild);
      }
      _currentChild = null;
      return;
    }
    final AnimationController controller = new AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    if (animate) {
      if (_currentChild != null) {
        _currentChild.controller.reverse();
        assert(!_children.contains(_currentChild));
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
    _currentChild = _newEntry(controller: controller, animation: animation);
  }

  @override
  void dispose() {
    if (_currentChild != null) {
      _currentChild.controller.dispose();
    }
    for (_AnimatedSwitcherChildEntry child in _children) {
      child.controller.dispose();
    }
    super.dispose();
  }

  bool get hasNewChild => widget.child != null;
  bool get hasOldChild => _currentChild != null;

  @override
  void didUpdateWidget(AnimatedSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (hasNewChild != hasOldChild || hasNewChild &&
        !Widget.canUpdate(widget.child, _currentChild.widgetChild)) {
      _addEntry(animate: true);
    } else {
      if (_currentChild != null) {
        _currentChild.widgetChild = widget.child;
        _currentChild.transition = _generateTransition(_currentChild.animation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _children.map<Widget>(
      (_AnimatedSwitcherChildEntry entry) {
        return entry.transition;
      },
    ).toList();
    if (_currentChild != null) {
      children.add(_currentChild.transition);
    }
    return widget.layoutBuilder(children);
  }
}
