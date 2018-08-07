// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';

/// Whether to show or hide a child.
///
/// By default, the [visible] property controls whether the [child] is included
/// in the subtree or not; when it is not [visible], the [replacement] child
/// (typically a zero-sized box) is included instead.
///
/// A variety of flags can be used to tweak exactly how the child is hidden.
///
/// These widgets provide some of the facets of this one:
///
///  * [Opacity], which can stop its child from being painted.
///  * [Offstage], which can stop its child from being laid out or painted.
///  * [TickerMode], which can stop its child from being animated.
///  * [ExcludeSemantics], which can hide the child from accessibility tools.
///  * [IgnorePointer], which can disable touch interactions with the child.
///
/// Using this widget is not necessary to hide children. The simplest way to
/// hide a child is just to not include it, or, if a child _must_ be given (e.g.
/// because this is a [StatelessWidget]) then to use [SizedBox.shrink] instead
/// of the child that would otherwise be included.
///
/// See also:
///
///  * [AnimatedSwitcher], which can fade from one child to the next as the
///    subtree changes.
///  * [AnimatedCrossFade], which can fade between two specific children.
class Visibility extends StatelessWidget {
  /// Control whether the given [child] is [visible].
  ///
  /// The [child] and [replacement] arguments must not be null.
  ///
  /// The boolean arguments must not be null.
  ///
  /// The [maintainSemantics] and [maintainInteractivity] arguments can only be
  /// set if [maintainSize] is set.
  ///
  /// The [maintainSize] argument can only be set if [maintainAnimation] is set.
  ///
  /// The [maintainAnimation] argument can only be set if [maintainState] is set.
  const Visibility({
    Key key,
    @required this.child,
    this.replacement = const SizedBox.shrink(),
    this.visible = true,
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
    this.maintainSemantics = false,
    this.maintainInteractivity = false,
  }) : assert(child != null),
       assert(replacement != null),
       assert(visible != null),
       assert(maintainState != null),
       assert(maintainAnimation != null),
       assert(maintainSize != null),
       assert(maintainState == true || maintainAnimation == false, 'Cannot maintain animations if the state is not also maintained.'),
       assert(maintainAnimation == true || maintainSize == false, 'Cannot maintain size if animations are not maintained.'),
       assert(maintainSize == true || maintainSemantics == false, 'Cannot maintain semantics if size is not maintained.'),
       assert(maintainSize == true || maintainInteractivity == false, 'Cannot maintain interactivity if size is not maintained.'),
       super(key: key);

  /// The widget to show or hide, as controlled by [visible].
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The widget to use when the child is not [visible], assuming that none of
  /// the `maintain` flags (in particular, [maintainState]) are set.
  ///
  /// The normal behavior is to replace the widget with a zero by zero box
  /// ([SizedBox.shrink]).
  ///
  /// See also:
  ///
  ///  * [AnimatedCrossFade], which can animate between two children.
  final Widget replacement;

  /// Switches between showing the [child] or hiding it.
  ///
  /// The `maintain` flags should be set to the same values regardless of the
  /// state of the [visible] property, otherwise they will not operate correctly
  /// (specifically, the state will be lost regardless of the state of
  /// [maintainState] whenever any of the `maintain` flags are changed, since
  /// doing so will result in a subtree shape change).
  final bool visible;

  /// Whether to maintain the [State] objects of the [child] subtree when it is
  /// not [visible].
  ///
  /// Keeping the state of the subtree is expensive. It should only be
  /// maintained if it cannot be recreated on demand. One example of when the
  /// state would be maintained is if the child subtree contains a [Navigator],
  /// since that widget maintains elaborate state that cannot be recreated on
  /// the fly.
  ///
  /// If this is true, an [Offstage] widget is used to hide the child instead of
  /// replacing it with [replacement].
  final bool maintainState;

  /// Whether to maintain animations within the [child] subtree when it is
  /// not [visible].
  ///
  /// To set this, [maintainState] must also be set.
  ///
  /// Keeping animations active when the widget is not visible is even more
  /// expensive than only maintaining the state.
  ///
  /// One example when this might be useful is if the subtree contains an
  /// animated [Image] that must be kept synchronized with other animated images
  /// elsewhere in the interface.
  ///
  /// If this is true, no [TickerMode] widget is used.
  final bool maintainAnimation;

  /// Whether to maintain space for where the widget would have been.
  ///
  /// To set this, [maintainAnimation] must also be set.
  ///
  /// Maintaining the size when the widget is not [visible] is roughly as
  /// expensive as keeping animations running, and may in some circumstances be
  /// cheaper if the subtree is simple and the [visible] property is frequently
  /// toggled, since it avoids triggering a layout change when the [visible]
  /// property is toggled. However, if the [child] subtree is not trivial then
  /// it is significantly cheaper to not even keep the state (see
  /// [maintainState]).
  ///
  /// If this is true, [Opacity] is used instead of [Offstage].
  ///
  /// See also:
  ///
  ///  * [AnimatedOpacity] and [FadeTransition], which apply animations to the
  ///    opacity for a more subtle effect.
  final bool maintainSize;

  /// Whether to maintain the semantics for the widget when it is hidden (e.g.
  /// for accessibility).
  ///
  /// To set this, [maintainSize] must also be set.
  ///
  /// By default, with [maintainSemantics] set to false, the [child] is not
  /// visible to accessibility tools when it is hidden from the user. If this
  /// flag is set to true, then accessibility tools will report the widget as if
  /// it was present.
  final bool maintainSemantics;

  /// Whether to allow the widget to be interactive when hidden.
  ///
  /// To set this, [maintainSize] must also be set.
  ///
  /// By default, with [maintainInteractivity] set to false, touch events cannot
  /// reach the [child] when it is hidden from the user. If this flag is set to
  /// true, then touch events will nonetheless be passed through.
  final bool maintainInteractivity;

  @override
  Widget build(BuildContext context) {
    if (maintainSize) {
      Widget result = child;
      if (!maintainInteractivity) {
        result = new IgnorePointer(
          child: child,
          ignoring: !visible,
          ignoringSemantics: !visible && !maintainSemantics,
        );
      }
      return new Opacity(
        opacity: visible ? 1.0 : 0.0,
        alwaysIncludeSemantics: maintainSemantics,
        child: result,
      );
    }
    assert(!maintainInteractivity);
    assert(!maintainSemantics);
    assert(!maintainSize);
    if (maintainState) {
      Widget result = child;
      if (!maintainAnimation)
        result = new TickerMode(child: child, enabled: visible);
      return new Offstage(
        child: result,
        offstage: !visible,
      );
    }
    assert(!maintainAnimation);
    assert(!maintainState);
    return visible ? child : replacement;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new FlagProperty('visible', value: visible, ifFalse: 'hidden', ifTrue: 'visible'));
    properties.add(new FlagProperty('maintainState', value: maintainState, ifFalse: 'maintainState'));
    properties.add(new FlagProperty('maintainAnimation', value: maintainAnimation, ifFalse: 'maintainAnimation'));
    properties.add(new FlagProperty('maintainSize', value: maintainSize, ifFalse: 'maintainSize'));
    properties.add(new FlagProperty('maintainSemantics', value: maintainSemantics, ifFalse: 'maintainSemantics'));
    properties.add(new FlagProperty('maintainInteractivity', value: maintainInteractivity, ifFalse: 'maintainInteractivity'));
  }
}
