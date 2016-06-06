// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
  List<WidgetBuilder> get builders;

  /// The entries this route has placed in the overlay.
  @override
  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

  @override
  void install(OverlayEntry insertionPoint) {
    assert(_overlayEntries.isEmpty);
    for (WidgetBuilder builder in builders)
      _overlayEntries.add(new OverlayEntry(builder: builder));
    navigator.overlay?.insertAll(_overlayEntries, above: insertionPoint);
  }

  /// A request was made to pop this route. If the route can handle it
  /// internally (e.g. because it has its own stack of internal state) then
  /// return false, otherwise return true. Returning false will prevent the
  /// default behavior of NavigatorState.pop().
  ///
  /// If this is called, the Navigator will not call dispose(). It is the
  /// responsibility of the Route to later call dispose().
  ///
  /// Subclasses shouldn't call this if they want to delay the finished() call.
  @override
  bool didPop(T result) {
    finished();
    return true;
  }

  /// Clears out the overlay entries.
  ///
  /// This method is intended to be used by subclasses who don't call
  /// super.didPop() because they want to have control over the timing of the
  /// overlay removal.
  ///
  /// Do not call this method outside of this context.
  void finished() {
    for (OverlayEntry entry in _overlayEntries)
      entry.remove();
    _overlayEntries.clear();
  }

  @override
  void dispose() {
    finished();
  }
}

/// A route with entrance and exit transitions.
abstract class TransitionRoute<T> extends OverlayRoute<T> {
  /// Creates a route with entrance and exit transitions.
  TransitionRoute({
    Completer<T> popCompleter,
    Completer<T> transitionCompleter
  }) : _popCompleter = popCompleter,
       _transitionCompleter = transitionCompleter;

  /// The same as the default constructor but callable with mixins.
  TransitionRoute.explicit(
    Completer<T> popCompleter,
    Completer<T> transitionCompleter
  ) : this(popCompleter: popCompleter, transitionCompleter: transitionCompleter);

  /// This future completes once the animation has been dismissed. For
  /// ModalRoutes, this will be after the completer that's passed in, since that
  /// one completes before the animation even starts, as soon as the route is
  /// popped.
  Future<T> get popped => _popCompleter?.future;
  final Completer<T> _popCompleter;

  /// This future completes only once the transition itself has finished, after
  /// the overlay entries have been removed from the navigator's overlay.
  Future<T> get completed => _transitionCompleter?.future;
  final Completer<T> _transitionCompleter;

  /// The duration the transition lasts.
  Duration get transitionDuration;

  /// Whether the route obscures previous routes when the transition is complete.
  ///
  /// When an opaque route's entrance transition is complete, the routes behind
  /// the opaque route will not be built to save resources.
  bool get opaque;

  /// The animation that drives the route's transition and the previous route's
  /// forward transition.
  Animation<double> get animation => _animation;
  Animation<double> _animation;
  AnimationController _controller;

  /// Called to create the animation controller that will drive the transitions to
  /// this route from the previous one, and back to the previous route from this
  /// one.
  AnimationController createAnimationController() {
    Duration duration = transitionDuration;
    assert(duration != null && duration >= Duration.ZERO);
    return new AnimationController(duration: duration, debugLabel: debugLabel);
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
    _popCompleter?.complete(_result);
    return true;
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
            nextRoute.animation,
            onSwitchedTrain: () {
              assert(_forwardAnimation.parent == newAnimation);
              assert(newAnimation.currentTrain == nextRoute.animation);
              _forwardAnimation.parent = newAnimation.currentTrain;
              newAnimation.dispose();
            }
          );
          _forwardAnimation.parent = newAnimation;
          current.dispose();
        } else {
          _forwardAnimation.parent = new TrainHoppingAnimation(current, nextRoute.animation);
        }
      } else {
        _forwardAnimation.parent = nextRoute.animation;
      }
    } else {
      _forwardAnimation.parent = kAlwaysDismissedAnimation;
    }
  }

  /// Whether this route can perform a transition to the given route.
  ///
  /// Subclasses can override this function to restrict the set of routes they
  /// need to coordinate transitions with.
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => true;

  /// Whether this route can perform a transition from the given route.
  ///
  /// Subclasses can override this function to restrict the set of routes they
  /// need to coordinate transitions with.
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) => true;

  @override
  void finished() {
    super.finished();
    _transitionCompleter?.complete(_result);
  }

  @override
  void dispose() {
    _controller.stop();
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
    this.route
  }) : super(key: key);

  final ModalRoute<dynamic> route;

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

  void _didChangeRouteOffStage() {
    setState(() {
      // We use the route's offstage bool in our build function, which means our
      // state has changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget contents = new PageStorage(
      key: config.route._subtreeKey,
      bucket: config.route._storageBucket,
      child: new _ModalScopeStatus(
        route: config.route,
        isCurrent: config.route.isCurrent,
        child: config.route.buildPage(context, config.route.animation, config.route.forwardAnimation)
      )
    );
    if (config.route.offstage) {
      contents = new OffStage(child: contents);
    } else {
      contents = new IgnorePointer(
        ignoring: config.route.animation?.status == AnimationStatus.reverse,
        child: config.route.buildTransitions(
          context,
          config.route.animation,
          config.route.forwardAnimation,
          contents
        )
      );
    }
    contents = new Focus(
      key: new GlobalObjectKey(config.route),
      child: new RepaintBoundary(child: contents)
    );
    return contents;
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
    Completer<T> completer,
    this.settings: const RouteSettings()
  }) : super.explicit(completer, null);

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


  // The API for subclasses to override - used by _ModalScope

  /// Override this function to build the primary content of this route.
  ///
  /// * [context] The context in which the route is being built.
  /// * [animation] The animation for this route's transition. When entering,
  ///   the animation runs forward from 0.0 to 1.0. When exiting, this animation
  ///   runs backwards from 1.0 to 0.0.
  /// * [forwardAnimation] The animation for the route being pushed on top of
  ///   this route. This animation lets this route coordinate with the entrance
  ///   and exit transition of routes pushed on top of this route.
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation);

  /// Override this function to wrap the route in a number of transition widgets.
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
  void didPush() {
    Focus.moveScopeTo(new GlobalObjectKey(this), context: navigator.context);
    super.didPush();
  }

  // The API for subclasses to override - used by this class

  /// Whether you can dismiss this route by tapping the modal barrier.
  bool get barrierDismissable;

  /// The color to use for the modal barrier. If this is null, the barrier will
  /// be transparent.
  Color get barrierColor;


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
    _offstage = value;
    _scopeKey.currentState?._didChangeRouteOffStage();
  }

  /// The build context for the subtree containing the primary content of this route.
  BuildContext get subtreeContext => _subtreeKey.currentContext;


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
      route: this
      // calls buildTransitions() and buildPage(), defined above
    );
  }

  @override
  List<WidgetBuilder> get builders => <WidgetBuilder>[
    _buildModalBarrier,
    _buildModalScope
  ];

  @override
  String toString() => '$runtimeType($settings, animation: $_animation)';
}

/// A modal route that overlays a widget over the current route.
abstract class PopupRoute<T> extends ModalRoute<T> {
  /// Creates a modal route that overlays a widget over the current route.
  PopupRoute({ Completer<T> completer }) : super(completer: completer);

  @override
  bool get opaque => false;

  @override
  void didChangeNext(Route<dynamic> nextRoute) {
    assert(nextRoute is! PageRoute<dynamic>);
    super.didChangeNext(nextRoute);
  }
}
