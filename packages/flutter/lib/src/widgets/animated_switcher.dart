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
/// The `child` should be transitioning in when the `animation` is running in
/// the forward direction.
///
/// The function should return a widget which wraps the given `child`. It may
/// also use the `animation` to inform its transition. It must not return null.
typedef Widget AnimatedSwitcherTransitionBuilder(Widget child, Animation<double> animation);

/// Signature for builders used to generate custom layouts for
/// [AnimatedSwitcher].
///
/// The builder should return a widget which contains the given children, laid
/// out as desired. It must not return null. The builder should be able to
/// handle an empty list of `previousChildren`, or a null `currentChild`.
///
/// The `previousChildren` list is an unmodifiable list, sorted with the oldest
/// at the beginning and the newest at the end. It does not include the
/// `currentChild`.
typedef Widget AnimatedSwitcherLayoutBuilder(Widget currentChild, List<Widget> previousChildren);

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
/// parameters. To force the transition to occur, set a [Key] (typically a
/// [ValueKey] taking any widget data that would change the visual appearance
/// of the widget) on each child widget that you wish to be considered unique.
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
///     return new MaterialApp(
///       home: new Material(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: <Widget>[
///             new AnimatedSwitcher(
///               duration: const Duration(milliseconds: 500),
///               transitionBuilder: (Widget child, Animation<double> animation) {
///                 return new ScaleTransition(child: child, scale: animation);
///               },
///               child: new Text(
///                 '$_count',
///                 // This key causes the AnimatedSwitcher to interpret this as a "new"
///                 // child each time the count changes, so that it will begin its animation
///                 // when the count changes.
///                 key: new ValueKey<int>(_count),
///                 style: Theme.of(context).textTheme.display1,
///               ),
///             ),
///             new RaisedButton(
///               child: const Text('Increment'),
///               onPressed: () {
///                 setState(() {
///                   _count += 1;
///                 });
///               },
///             ),
///           ],
///         ),
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
    this.switchInCurve = Curves.linear,
    this.switchOutCurve = Curves.linear,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
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

  /// A function that wraps a new [child] with an animation that transitions
  /// the [child] in when the animation runs in the forward direction and out
  /// when the animation runs in the reverse direction. This is only called
  /// when a new [child] is set (not for each build), or when a new
  /// [transitionBuilder] is set. If a new [transitionBuilder] is set, then
  /// the transition is rebuilt for the current child and all previous children
  /// using the new [transitionBuilder]. The function must not return null.
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
  /// out. This is called every time this widget is built. The function must not
  /// return null.
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

  /// The transition builder used as the default value of [transitionBuilder].
  ///
  /// The new child is given a [FadeTransition] which increases opacity as
  /// the animation goes from 0.0 to 1.0, and decreases when the animation is
  /// reversed.
  ///
  /// This is an [AnimatedSwitcherTransitionBuilder] function.
  static Widget defaultTransitionBuilder(Widget child, Animation<double> animation) {
    return new FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// The layout builder used as the default value of [layoutBuilder].
  ///
  /// The new child is placed in a [Stack] that sizes itself to match the
  /// largest of the child or a previous child. The children are centered on
  /// each other.
  ///
  /// This is an [AnimatedSwitcherLayoutBuilder] function.
  static Widget defaultLayoutBuilder(Widget currentChild, List<Widget> previousChildren) {
    List<Widget> children = previousChildren;
    if (currentChild != null) {
      children = children.toList()..add(currentChild);
    }
    return new Stack(
      children: children,
      alignment: Alignment.center,
    );
  }
}

class _AnimatedSwitcherState extends State<AnimatedSwitcher> with TickerProviderStateMixin {
  final Set<_AnimatedSwitcherChildEntry> _previousChildren = new Set<_AnimatedSwitcherChildEntry>();
  _AnimatedSwitcherChildEntry _currentChild;
  List<Widget> _previousChildWidgetCache = const <Widget>[];
  int serialNumber = 0;

  @override
  void initState() {
    super.initState();
    _addEntry(animate: false);
  }

  _AnimatedSwitcherChildEntry _newEntry({
    @required AnimationController controller,
    @required Animation<double> animation,
  }) {
    final _AnimatedSwitcherChildEntry entry = new _AnimatedSwitcherChildEntry(
      widgetChild: widget.child,
      transition: new KeyedSubtree.wrap(
        widget.transitionBuilder(
          widget.child,
          animation,
        ),
        serialNumber++,
      ),
      animation: animation,
      controller: controller,
    );
    animation.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _removeExpiredChild(entry);
        });
        controller.dispose();
      }
    });
    return entry;
  }

  void _removeExpiredChild(_AnimatedSwitcherChildEntry child) {
    assert(_previousChildren.contains(child));
    _previousChildren.remove(child);
    _markChildWidgetCacheAsDirty();
  }

  void _retireCurrentChild() {
    assert(!_previousChildren.contains(_currentChild));
    _currentChild.controller.reverse();
    _previousChildren.add(_currentChild);
    _markChildWidgetCacheAsDirty();
  }

  void _markChildWidgetCacheAsDirty() {
    _previousChildWidgetCache = null;
  }

  void _addEntry({@required bool animate}) {
    if (widget.child == null) {
      if (animate && _currentChild != null) {
        _retireCurrentChild();
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
        _retireCurrentChild();
      }
      controller.forward();
    } else {
      assert(_currentChild == null);
      assert(_previousChildren.isEmpty);
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
    for (_AnimatedSwitcherChildEntry child in _previousChildren) {
      child.controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    void updateTransition(_AnimatedSwitcherChildEntry entry) {
      entry.transition = new KeyedSubtree(
        key: entry.transition.key,
        child: widget.transitionBuilder(entry.widgetChild, entry.animation),
      );
    }

    // If the transition builder changed, then update all of the previous transitions
    if (widget.transitionBuilder != oldWidget.transitionBuilder) {
      _previousChildren.forEach(updateTransition);
      if (_currentChild != null) {
        updateTransition(_currentChild);
      }
      _markChildWidgetCacheAsDirty();
    }

    final bool hasNewChild = widget.child != null;
    final bool hasOldChild = _currentChild != null;
    if (hasNewChild != hasOldChild ||
        hasNewChild && !Widget.canUpdate(widget.child, _currentChild.widgetChild)) {
      _addEntry(animate: true);
    } else {
      // Make sure we update the child widget and transition in _currentChild
      // even if we're not going to start a new animation, but keep the key from
      // the previous transition so that we update the transition instead of
      // replacing it.
      if (_currentChild != null) {
        _currentChild.widgetChild = widget.child;
        updateTransition(_currentChild);
        _markChildWidgetCacheAsDirty();
      }
    }
  }

  void _rebuildChildWidgetCacheIfNeeded() {
    _previousChildWidgetCache ??= new List<Widget>.unmodifiable(
      _previousChildren.map<Widget>((_AnimatedSwitcherChildEntry child) {
        return child.transition;
      }),
    );
    assert(_previousChildren.length == _previousChildWidgetCache.length);
    assert(_previousChildren.isEmpty || _previousChildren.last.transition == _previousChildWidgetCache.last);
  }

  @override
  Widget build(BuildContext context) {
    _rebuildChildWidgetCacheIfNeeded();
    return widget.layoutBuilder(_currentChild?.transition, _previousChildWidgetCache);
  }
}
