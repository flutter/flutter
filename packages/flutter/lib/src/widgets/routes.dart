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

const _kTransparent = const Color(0x00000000);

/// A route that displays widgets in the [Navigator]'s [Overlay].
abstract class OverlayRoute<T> extends Route<T> {
  /// Subclasses should override this getter to return the builders for the overlay.
  List<WidgetBuilder> get builders;

  /// The entries this route has placed in the overlay.
  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

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

  void dispose() {
    finished();
  }
}

abstract class TransitionRoute<T> extends OverlayRoute<T> {
  TransitionRoute({
    Completer<T> popCompleter,
    Completer<T> transitionCompleter
  }) : _popCompleter = popCompleter,
       _transitionCompleter = transitionCompleter;

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

  Duration get transitionDuration;
  bool get opaque;

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

  void handleStatusChanged(AnimationStatus status) {
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

  Animation<double> get forwardAnimation => _forwardAnimation;
  final ProxyAnimation _forwardAnimation = new ProxyAnimation(kAlwaysDismissedAnimation);

  void install(OverlayEntry insertionPoint) {
    _controller = createAnimationController();
    assert(_controller != null);
    _animation = createAnimation();
    assert(_animation != null);
    super.install(insertionPoint);
  }

  void didPush() {
    _animation.addStatusListener(handleStatusChanged);
    _controller.forward();
    super.didPush();
  }

  void didReplace(Route oldRoute) {
    if (oldRoute is TransitionRoute)
      _controller.value = oldRoute._controller.value;
    _animation.addStatusListener(handleStatusChanged);
    super.didReplace(oldRoute);
  }

  bool didPop(T result) {
    _result = result;
    _controller.reverse();
    _popCompleter?.complete(_result);
    return true;
  }

  void didPopNext(Route nextRoute) {
    _updateForwardAnimation(nextRoute);
    super.didPopNext(nextRoute);
  }

  void didChangeNext(Route nextRoute) {
    _updateForwardAnimation(nextRoute);
    super.didChangeNext(nextRoute);
  }

  void _updateForwardAnimation(Route nextRoute) {
    if (nextRoute is TransitionRoute && canTransitionTo(nextRoute) && nextRoute.canTransitionFrom(this)) {
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

  bool canTransitionTo(TransitionRoute nextRoute) => true;
  bool canTransitionFrom(TransitionRoute nextRoute) => true;

  void finished() {
    super.finished();
    _transitionCompleter?.complete(_result);
  }

  void dispose() {
    _controller.stop();
    super.dispose();
  }

  String get debugLabel => '$runtimeType';
  String toString() => '$runtimeType(animation: $_controller)';
}

class LocalHistoryEntry {
  LocalHistoryEntry({ this.onRemove });
  final VoidCallback onRemove;
  LocalHistoryRoute _owner;
  void remove() {
    _owner.removeLocalHistoryEntry(this);
    assert(_owner == null);
  }
  void _notifyRemoved() {
    if (onRemove != null)
      onRemove();
  }
}

abstract class LocalHistoryRoute<T> extends Route<T> {
  List<LocalHistoryEntry> _localHistory;
  void addLocalHistoryEntry(LocalHistoryEntry entry) {
    assert(entry._owner == null);
    entry._owner = this;
    _localHistory ??= <LocalHistoryEntry>[];
    _localHistory.add(entry);
  }
  void removeLocalHistoryEntry(LocalHistoryEntry entry) {
    assert(entry != null);
    assert(entry._owner == this);
    assert(_localHistory.contains(entry));
    _localHistory.remove(entry);
    entry._owner = null;
    entry._notifyRemoved();
  }
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
  final Route route;

  bool updateShouldNotify(_ModalScopeStatus old) {
    return isCurrent != old.isCurrent ||
           route != old.route;
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${isCurrent ? "active" : "inactive"}');
  }
}

class _ModalScope extends StatefulComponent {
  _ModalScope({
    Key key,
    this.route
  }) : super(key: key);

  final ModalRoute route;

  _ModalScopeState createState() => new _ModalScopeState();
}

class _ModalScopeState extends State<_ModalScope> {
  void initState() {
    super.initState();
    config.route.animation?.addStatusListener(_animationStatusChanged);
    config.route.forwardAnimation?.addStatusListener(_animationStatusChanged);
  }

  void didUpdateConfig(_ModalScope oldConfig) {
    assert(config.route == oldConfig.route);
  }

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
    ModalPosition position = config.route.getPosition(context);
    if (position == null)
      return contents;
    return new Positioned(
      top: position.top,
      right: position.right,
      bottom: position.bottom,
      left: position.left,
      child: contents
    );
  }
}

class ModalPosition {
  const ModalPosition({ this.top, this.right, this.bottom, this.left });
  final double top;
  final double right;
  final double bottom;
  final double left;
}

abstract class ModalRoute<T> extends TransitionRoute<T> with LocalHistoryRoute<T> {
  ModalRoute({
    Completer<T> completer,
    this.settings: const RouteSettings()
  }) : super.explicit(completer, null);

  // The API for general users of this class

  final RouteSettings settings;

  /// Returns the modal route most closely associated with the given context.
  ///
  /// Returns null if the given context is not associated with a modal route.
  static ModalRoute of(BuildContext context) {
    _ModalScopeStatus widget = context.inheritFromWidgetOfExactType(_ModalScopeStatus);
    return widget?.route;
  }


  // The API for subclasses to override - used by _ModalScope

  ModalPosition getPosition(BuildContext context) => null;
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation);
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation, Widget child) {
    return child;
  }

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

  bool get offstage => _offstage;
  bool _offstage = false;
  void set offstage (bool value) {
    if (_offstage == value)
      return;
    _offstage = value;
    _scopeKey.currentState?.setState(() {
      // _offstage is the value we're setting, but since there might not be a
      // state, we set it outside of this callback (which will only be called if
      // there's a state currently built).
      // _scopeKey is the key for the _ModalScope built in _buildModalScope().
      // When we mark that state dirty, it'll rebuild itself, and use our
      // offstage (via their config.route.offstage) when building.
    });
  }

  BuildContext get subtreeContext => _subtreeKey.currentContext;


  // Internals

  final GlobalKey<_ModalScopeState> _scopeKey = new GlobalKey<_ModalScopeState>();
  final GlobalKey _subtreeKey = new GlobalKey();
  final PageStorageBucket _storageBucket = new PageStorageBucket();

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

  Widget _buildModalScope(BuildContext context) {
    return new _ModalScope(
      key: _scopeKey,
      route: this
      // calls buildTransitions() and buildPage(), defined above
    );
  }

  List<WidgetBuilder> get builders => <WidgetBuilder>[
    _buildModalBarrier,
    _buildModalScope
  ];

  String toString() => '$runtimeType($settings, animation: $_animation)';
}

/// A modal route that overlays a widget over the current route.
abstract class PopupRoute<T> extends ModalRoute<T> {
  PopupRoute({ Completer<T> completer }) : super(completer: completer);
  bool get opaque => false;
  void didChangeNext(Route nextRoute) {
    assert(nextRoute is! PageRoute);
    super.didChangeNext(nextRoute);
  }
}
