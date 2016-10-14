// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'basic.dart';
import 'focus.dart';
import 'framework.dart';
import 'modal_barrier.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'page_storage.dart';
import 'pages.dart';

const Color _kTransparent = const Color(0x00000000);

/// A route that displays widgets in the [Navigator]'s [Overlay].
abstract class OverlayRoute<T> extends Route<T> {
  /// Subclasses should override this getter to return the builders for the overlay.
  Iterable<OverlayEntry> createOverlayEntries();

  /// The entries this route has placed in the overlay.
  @override
  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

  @override
  void install(OverlayEntry insertionPoint) {
    assert(_overlayEntries.isEmpty);
    _overlayEntries.addAll(createOverlayEntries());
    navigator.overlay?.insertAll(_overlayEntries, above: insertionPoint);
    super.install(insertionPoint);
  }

  /// Controls whether [didPop] calls [finished].
  ///
  /// If true, this route removes its overlay entries during [didPop].
  /// Subclasses can override this getter if they want to delay the [finished]
  /// call (for example to animate the route's exit before removing it from the
  /// overlay).
  @protected
  bool get finishedWhenPopped => true;

  @override
  bool didPop(T result) {
    if (finishedWhenPopped)
      finished();
    return super.didPop(result);
  }

  /// Clears out the overlay entries.
  ///
  /// This method is intended to be used by subclasses who don't call
  /// super.didPop() because they want to have control over the timing of the
  /// overlay removal.
  ///
  /// Do not call this method outside of this context.
  @protected
  void finished() {
    for (OverlayEntry entry in _overlayEntries)
      entry.remove();
    _overlayEntries.clear();
  }

  @override
  void dispose() {
    finished();
    super.dispose();
  }
}

/// A route with entrance and exit transitions.
abstract class TransitionRoute<T> extends OverlayRoute<T> {
  /// Creates a route with entrance and exit transitions.
  TransitionRoute({
    Completer<T> transitionCompleter
  }) : _transitionCompleter = transitionCompleter;

  /// The same as the default constructor but callable with mixins.
  TransitionRoute.explicit(
    Completer<T> transitionCompleter
  ) : this(transitionCompleter: transitionCompleter);

  /// This future completes only once the transition itself has finished, after
  /// the overlay entries have been removed from the navigator's overlay.
  ///
  /// This future completes once the animation has been dismissed. That will be
  /// after [popped], because [popped] completes before the animation even
  /// starts, as soon as the route is popped.
  Future<T> get completed => _transitionCompleter?.future;
  final Completer<T> _transitionCompleter;

  /// The duration the transition lasts.
  Duration get transitionDuration;

  /// Whether the route obscures previous routes when the transition is complete.
  ///
  /// When an opaque route's entrance transition is complete, the routes behind
  /// the opaque route will not be built to save resources.
  bool get opaque;

  @override
  bool get finishedWhenPopped => false;

  /// The animation that drives the route's transition and the previous route's
  /// forward transition.
  Animation<double> get animation => _animation;
  Animation<double> _animation;

  /// The animation controller that the route uses to drive the transitions.
  ///
  /// The animation itself is exposed by the [animation] property.
  @protected
  AnimationController get controller => _controller;
  AnimationController _controller;

  /// Called to create the animation controller that will drive the transitions to
  /// this route from the previous one, and back to the previous route from this
  /// one.
  AnimationController createAnimationController() {
    Duration duration = transitionDuration;
    assert(duration != null && duration >= Duration.ZERO);
    return new AnimationController(
      duration: duration,
      debugLabel: debugLabel,
      vsync: navigator,
    );
  }

  /// Called to create the animation that exposes the current progress of
  /// the transition controlled by the animation controller created by
  /// [createAnimationController()].
  Animation<double> createAnimation() {
    assert(_controller != null);
    return _controller.view;
  }

  T _result;

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        if (overlayEntries.isNotEmpty)
          overlayEntries.first.opaque = opaque;
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        if (overlayEntries.isNotEmpty)
          overlayEntries.first.opaque = false;
        break;
      case AnimationStatus.dismissed:
        assert(!overlayEntries.first.opaque);
        finished(); // clear the overlays
        assert(overlayEntries.isEmpty);
        break;
    }
  }

  /// The animation for the route being pushed on top of this route. This
  /// animation lets this route coordinate with the entrance and exit transition
  /// of routes pushed on top of this route.
  Animation<double> get forwardAnimation => _forwardAnimation;
  final ProxyAnimation _forwardAnimation = new ProxyAnimation(kAlwaysDismissedAnimation);

  @override
  void install(OverlayEntry insertionPoint) {
    _controller = createAnimationController();
    assert(_controller != null);
    _animation = createAnimation();
    assert(_animation != null);
    super.install(insertionPoint);
  }

  @override
  void didPush() {
    _animation.addStatusListener(_handleStatusChanged);
    _controller.forward();
    super.didPush();
  }

  @override
  void didReplace(Route<dynamic> oldRoute) {
    if (oldRoute is TransitionRoute<dynamic>)
      _controller.value = oldRoute._controller.value;
    _animation.addStatusListener(_handleStatusChanged);
    super.didReplace(oldRoute);
  }

  @override
  bool didPop(T result) {
    _result = result;
    _controller.reverse();
    return super.didPop(result);
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    _updateForwardAnimation(nextRoute);
    super.didPopNext(nextRoute);
  }

  @override
  void didChangeNext(Route<dynamic> nextRoute) {
    _updateForwardAnimation(nextRoute);
    super.didChangeNext(nextRoute);
  }

  void _updateForwardAnimation(Route<dynamic> nextRoute) {
    if (nextRoute is TransitionRoute<dynamic> && canTransitionTo(nextRoute) && nextRoute.canTransitionFrom(this)) {
      Animation<double> current = _forwardAnimation.parent;
      if (current != null) {
        if (current is TrainHoppingAnimation) {
          TrainHoppingAnimation newAnimation;
          newAnimation = new TrainHoppingAnimation(
            current.currentTrain,
            nextRoute._animation,
            onSwitchedTrain: () {
              assert(_forwardAnimation.parent == newAnimation);
              assert(newAnimation.currentTrain == nextRoute._animation);
              _forwardAnimation.parent = newAnimation.currentTrain;
              newAnimation.dispose();
            }
          );
          _forwardAnimation.parent = newAnimation;
          current.dispose();
        } else {
          _forwardAnimation.parent = new TrainHoppingAnimation(current, nextRoute._animation);
        }
      } else {
        _forwardAnimation.parent = nextRoute._animation;
      }
    } else {
      _forwardAnimation.parent = kAlwaysDismissedAnimation;
    }
  }

  /// Whether this route can perform a transition to the given route.
  ///
  /// Subclasses can override this method to restrict the set of routes they
  /// need to coordinate transitions with.
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => true;

  /// Whether this route can perform a transition from the given route.
  ///
  /// Subclasses can override this method to restrict the set of routes they
  /// need to coordinate transitions with.
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) => true;

  @override
  void finished() {
    super.finished();
    _transitionCompleter?.complete(_result);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A short description of this route useful for debugging.
  String get debugLabel => '$runtimeType';

  @override
  String toString() => '$runtimeType(animation: $_controller)';
}

/// An entry in the history of a [LocalHistoryRoute].
class LocalHistoryEntry {
  /// Creates an entry in the history of a [LocalHistoryRoute].
  LocalHistoryEntry({ this.onRemove });

  /// Called when this entry is removed from the history of its associated [LocalHistoryRoute].
  final VoidCallback onRemove;

  LocalHistoryRoute<dynamic> _owner;

  /// Remove this entry from the history of its associated [LocalHistoryRoute].
  void remove() {
    _owner.removeLocalHistoryEntry(this);
    assert(_owner == null);
  }

  void _notifyRemoved() {
    if (onRemove != null)
      onRemove();
  }
}

/// A route that can handle back navigations internally by popping a list.
///
/// When a [Navigator] is instructed to pop, the current route is given an
/// opportunity to handle the pop internally. A LocalHistoryRoute handles the
/// pop internally if its list of local history entries is non-empty. Rather
/// than being removed as the current route, the most recent [LocalHistoryEntry]
/// is removed from the list and its [onRemove] is called.
abstract class LocalHistoryRoute<T> extends Route<T> {
  List<LocalHistoryEntry> _localHistory;

  /// Adds a local history entry to this route.
  ///
  /// When asked to pop, if this route has any local history entries, this route
  /// will handle the pop internally by removing the most recently added local
  /// history entry.
  ///
  /// The given local history entry must not already be part of another local
  /// history route.
  void addLocalHistoryEntry(LocalHistoryEntry entry) {
    assert(entry._owner == null);
    entry._owner = this;
    _localHistory ??= <LocalHistoryEntry>[];
    _localHistory.add(entry);
  }

  /// Remove a local history entry from this route.
  ///
  /// The entry's [onRemove] callback, if any, will be called synchronously.
  void removeLocalHistoryEntry(LocalHistoryEntry entry) {
    assert(entry != null);
    assert(entry._owner == this);
    assert(_localHistory.contains(entry));
    _localHistory.remove(entry);
    entry._owner = null;
    entry._notifyRemoved();
  }

  @override
  bool didPop(T result) {
    if (_localHistory != null && _localHistory.length > 0) {
      LocalHistoryEntry entry = _localHistory.removeLast();
      assert(entry._owner == this);
      entry._owner = null;
      entry._notifyRemoved();
      return false;
    }
    return super.didPop(result);
  }

  @override
  bool get willHandlePopInternally {
    return _localHistory != null && _localHistory.length > 0;
  }
}

class _ModalScopeStatus extends InheritedWidget {
  _ModalScopeStatus({
    Key key,
    this.isCurrent,
    this.route,
    Widget child
  }) : super(key: key, child: child) {
    assert(isCurrent != null);
    assert(route != null);
    assert(child != null);
  }

  final bool isCurrent;
  final Route<dynamic> route;

  @override
  bool updateShouldNotify(_ModalScopeStatus old) {
    return isCurrent != old.isCurrent ||
           route != old.route;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${isCurrent ? "active" : "inactive"}');
  }
}

class _ModalScope extends StatefulWidget {
  _ModalScope({
    Key key,
    this.route,
    this.page
  }) : super(key: key);

  final ModalRoute<dynamic> route;
  final Widget page;

  @override
  _ModalScopeState createState() => new _ModalScopeState();
}

class _ModalScopeState extends State<_ModalScope> {
  @override
  void initState() {
    super.initState();
    config.route.animation?.addStatusListener(_animationStatusChanged);
    config.route.forwardAnimation?.addStatusListener(_animationStatusChanged);
  }

  @override
  void didUpdateConfig(_ModalScope oldConfig) {
    assert(config.route == oldConfig.route);
  }

  @override
  void dispose() {
    config.route.animation?.removeStatusListener(_animationStatusChanged);
    config.route.forwardAnimation?.removeStatusListener(_animationStatusChanged);
    super.dispose();
  }

  void _animationStatusChanged(AnimationStatus status) {
    setState(() {
      // The animation's states are our build state, and they changed already.
    });
  }

  void _routeSetState(VoidCallback fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return new Focus(
      key: config.route.focusKey,
      child: new Offstage(
        offstage: config.route.offstage,
        child: new IgnorePointer(
          ignoring: config.route.animation?.status == AnimationStatus.reverse,
          child: config.route.buildTransitions(
            context,
            config.route.animation,
            config.route.forwardAnimation,
            new RepaintBoundary(
              child: new PageStorage(
                key: config.route._subtreeKey,
                bucket: config.route._storageBucket,
                child: new _ModalScopeStatus(
                  route: config.route,
                  isCurrent: config.route.isCurrent,
                  child: config.page
                )
              )
            )
          )
        )
      )
    );
  }
}

/// A route that blocks interaction with previous routes.
///
/// ModalRoutes cover the entire [Navigator]. They are not necessarily [opaque],
/// however; for example, a pop-up menu uses a ModalRoute but only shows the menu
/// in a small box overlapping the previous route.
abstract class ModalRoute<T> extends TransitionRoute<T> with LocalHistoryRoute<T> {
  /// Creates a route that blocks interaction with previous routes.
  ModalRoute({
    this.settings: const RouteSettings()
  }) : super.explicit(null);

  // The API for general users of this class

  /// The settings for this route.
  ///
  /// See [RouteSettings] for details.
  final RouteSettings settings;

  /// Returns the modal route most closely associated with the given context.
  ///
  /// Returns `null` if the given context is not associated with a modal route.
  static ModalRoute<dynamic> of(BuildContext context) {
    _ModalScopeStatus widget = context.inheritFromWidgetOfExactType(_ModalScopeStatus);
    return widget?.route;
  }

  /// Whenever you need to change internal state for a ModalRoute object, make
  /// the change in a function that you pass to setState(), as in:
  ///
  /// ```dart
  /// setState(() { myState = newValue });
  /// ```
  ///
  /// If you just change the state directly without calling setState(), then the
  /// route will not be scheduled for rebuilding, meaning that its rendering
  /// will not be updated.
  @protected
  void setState(VoidCallback fn) {
    if (_scopeKey.currentState != null) {
      _scopeKey.currentState._routeSetState(fn);
    } else {
      // The route isn't currently visible, so we don't have to call its setState
      // method, but we do still need to call the fn callback, otherwise the state
      // in the route won't be updated!
      fn();
    }
  }

  /// Returns a predicate that's true if the route has the specified name and if
  /// popping the route will not yield the same route, i.e. if the route's
  /// [willHandlePopInternally] property is false.
  ///
  /// This function is typically used with [Navigator.popUntil()].
  static RoutePredicate withName(String name) {
    return (Route<dynamic> route) {
      return !route.willHandlePopInternally
        && route is ModalRoute && route.settings.name == name;
    };
  }

  // The API for subclasses to override - used by _ModalScope

  /// Override this method to build the primary content of this route.
  ///
  /// * [context] The context in which the route is being built.
  /// * [animation] The animation for this route's transition. When entering,
  ///   the animation runs forward from 0.0 to 1.0. When exiting, this animation
  ///   runs backwards from 1.0 to 0.0.
  /// * [forwardAnimation] The animation for the route being pushed on top of
  ///   this route. This animation lets this route coordinate with the entrance
  ///   and exit transition of routes pushed on top of this route.
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation);

  /// Override this method to wrap the route in a number of transition widgets.
  ///
  /// For example, to create a fade entrance transition, wrap the given child
  /// widget in a [FadeTransition] using the given animation as the opacity.
  ///
  /// By default, the child is not wrapped in any transition widgets.
  ///
  /// * [context] The context in which the route is being built.
  /// * [animation] The animation for this route's transition. When entering,
  ///   the animation runs forward from 0.0 to 1.0. When exiting, this animation
  ///   runs backwards from 1.0 to 0.0.
  /// * [forwardAnimation] The animation for the route being pushed on top of
  ///   this route. This animation lets this route coordinate with the entrance
  ///   and exit transition of routes pushed on top of this route.
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation, Widget child) {
    return child;
  }

  @override
  GlobalKey get focusKey => new GlobalObjectKey(this);

  @override
  void install(OverlayEntry insertionPoint) {
    super.install(insertionPoint);
    _animationProxy = new ProxyAnimation(super.animation);
    _forwardAnimationProxy = new ProxyAnimation(super.forwardAnimation);
  }

  @override
  void didPush() {
    if (!settings.isInitialRoute) {
      BuildContext overlayContext = navigator.overlay?.context;
      assert(() {
        if (overlayContext == null) {
          throw new FlutterError(
            'Unable to find the BuildContext for the Navigator\'s overlay.\n'
            'Did you remember to pass the settings object to the route\'s '
            'constructor in your onGenerateRoute callback?'
          );
        }
        return true;
      });
      Focus.moveScopeTo(focusKey, context: overlayContext);
    }
    super.didPush();
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    Focus.moveScopeTo(focusKey, context: navigator.overlay.context);
    super.didPopNext(nextRoute);
  }

  // The API for subclasses to override - used by this class

  /// Whether you can dismiss this route by tapping the modal barrier.
  bool get barrierDismissable;

  /// The color to use for the modal barrier. If this is null, the barrier will
  /// be transparent.
  Color get barrierColor;

  /// Whether the route should remain in memory when it is inactive. If this is
  /// true, then the route is maintained, so that any futures it is holding from
  /// the next route will properly resolve when the next route pops. If this is
  /// not necessary, this can be set to false to allow the framework to entirely
  /// discard the route's widget hierarchy when it is not visible.
  bool get maintainState;


  // The API for _ModalScope and HeroController

  /// Whether this route is currently offstage.
  ///
  /// On the first frame of a route's entrance transition, the route is built
  /// [Offstage] using an animation progress of 1.0. The route is invisible and
  /// non-interactive, but each widget has its final size and position. This
  /// mechanism lets the [HeroController] determine the final local of any hero
  /// widgets being animated as part of the transition.
  bool get offstage => _offstage;
  bool _offstage = false;
  set offstage (bool value) {
    if (_offstage == value)
      return;
    setState(() {
      _offstage = value;
    });
    _animationProxy.parent = _offstage ? kAlwaysCompleteAnimation : super.animation;
    _forwardAnimationProxy.parent = _offstage ? kAlwaysDismissedAnimation : super.forwardAnimation;
  }

  /// The build context for the subtree containing the primary content of this route.
  BuildContext get subtreeContext => _subtreeKey.currentContext;

  @override
  Animation<double> get animation => _animationProxy;
  ProxyAnimation _animationProxy;

  @override
  Animation<double> get forwardAnimation => _forwardAnimationProxy;
  ProxyAnimation _forwardAnimationProxy;


  // Internals

  final GlobalKey<_ModalScopeState> _scopeKey = new GlobalKey<_ModalScopeState>();
  final GlobalKey _subtreeKey = new GlobalKey();
  final PageStorageBucket _storageBucket = new PageStorageBucket();

  // one of the builders
  Widget _buildModalBarrier(BuildContext context) {
    Widget barrier;
    if (barrierColor != null) {
      assert(barrierColor != _kTransparent);
      Animation<Color> color = new ColorTween(
        begin: _kTransparent,
        end: barrierColor
      ).animate(new CurvedAnimation(
        parent: animation,
        curve: Curves.ease
      ));
      barrier = new AnimatedModalBarrier(
        color: color,
        dismissable: barrierDismissable
      );
    } else {
      barrier = new ModalBarrier(dismissable: barrierDismissable);
    }
    assert(animation.status != AnimationStatus.dismissed);
    return new IgnorePointer(
      ignoring: animation.status == AnimationStatus.reverse,
      child: barrier
    );
  }

  // one of the builders
  Widget _buildModalScope(BuildContext context) {
    return new _ModalScope(
      key: _scopeKey,
      route: this,
      page: buildPage(context, animation, forwardAnimation)
      // _ModalScope calls buildTransitions(), defined above
    );
  }

  @override
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    yield new OverlayEntry(builder: _buildModalBarrier);
    yield new OverlayEntry(builder: _buildModalScope, maintainState: maintainState);
  }

  @override
  String toString() => '$runtimeType($settings, animation: $_animation)';
}

/// A modal route that overlays a widget over the current route.
abstract class PopupRoute<T> extends ModalRoute<T> {
  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  void didChangeNext(Route<dynamic> nextRoute) {
    assert(nextRoute is! PageRoute<dynamic>);
    super.didChangeNext(nextRoute);
  }
}
