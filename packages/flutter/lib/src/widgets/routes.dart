// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'basic.dart';
import 'display_feature_sub_screen.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'modal_barrier.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'page_storage.dart';
import 'primary_scroll_controller.dart';
import 'restoration.dart';
import 'scroll_controller.dart';
import 'transitions.dart';

// Examples can assume:
// dynamic routeObserver;
// late NavigatorState navigator;
// late BuildContext context;
// Future<bool> askTheUserIfTheyAreSure() async { return true; }
// abstract class MyWidget extends StatefulWidget { const MyWidget({Key? key}) : super(key: key); }

/// A route that displays widgets in the [Navigator]'s [Overlay].
abstract class OverlayRoute<T> extends Route<T> {
  /// Creates a route that knows how to interact with an [Overlay].
  OverlayRoute({
    RouteSettings? settings,
  }) : super(settings: settings);

  /// Subclasses should override this getter to return the builders for the overlay.
  @factory
  Iterable<OverlayEntry> createOverlayEntries();

  @override
  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

  @override
  void install() {
    assert(_overlayEntries.isEmpty);
    _overlayEntries.addAll(createOverlayEntries());
    super.install();
  }

  /// Controls whether [didPop] calls [NavigatorState.finalizeRoute].
  ///
  /// If true, this route removes its overlay entries during [didPop].
  /// Subclasses can override this getter if they want to delay finalization
  /// (for example to animate the route's exit before removing it from the
  /// overlay).
  ///
  /// Subclasses that return false from [finishedWhenPopped] are responsible for
  /// calling [NavigatorState.finalizeRoute] themselves.
  @protected
  bool get finishedWhenPopped => true;

  @override
  bool didPop(T? result) {
    final bool returnValue = super.didPop(result);
    assert(returnValue);
    if (finishedWhenPopped)
      navigator!.finalizeRoute(this);
    return returnValue;
  }

  @override
  void dispose() {
    _overlayEntries.clear();
    super.dispose();
  }
}

/// A route with entrance and exit transitions.
abstract class TransitionRoute<T> extends OverlayRoute<T> {
  /// Creates a route that animates itself when it is pushed or popped.
  TransitionRoute({
    RouteSettings? settings,
  }) : super(settings: settings);

  /// This future completes only once the transition itself has finished, after
  /// the overlay entries have been removed from the navigator's overlay.
  ///
  /// This future completes once the animation has been dismissed. That will be
  /// after [popped], because [popped] typically completes before the animation
  /// even starts, as soon as the route is popped.
  Future<T?> get completed => _transitionCompleter.future;
  final Completer<T?> _transitionCompleter = Completer<T?>();

  /// {@template flutter.widgets.TransitionRoute.transitionDuration}
  /// The duration the transition going forwards.
  ///
  /// See also:
  ///
  /// * [reverseTransitionDuration], which controls the duration of the
  /// transition when it is in reverse.
  /// {@endtemplate}
  Duration get transitionDuration;

  /// {@template flutter.widgets.TransitionRoute.reverseTransitionDuration}
  /// The duration the transition going in reverse.
  ///
  /// By default, the reverse transition duration is set to the value of
  /// the forwards [transitionDuration].
  /// {@endtemplate}
  Duration get reverseTransitionDuration => transitionDuration;

  /// {@template flutter.widgets.TransitionRoute.opaque}
  /// Whether the route obscures previous routes when the transition is complete.
  ///
  /// When an opaque route's entrance transition is complete, the routes behind
  /// the opaque route will not be built to save resources.
  /// {@endtemplate}
  bool get opaque;

  // This ensures that if we got to the dismissed state while still current,
  // we will still be disposed when we are eventually popped.
  //
  // This situation arises when dealing with the Cupertino dismiss gesture.
  @override
  bool get finishedWhenPopped => _controller!.status == AnimationStatus.dismissed && !_popFinalized;

  bool _popFinalized = false;

  /// The animation that drives the route's transition and the previous route's
  /// forward transition.
  Animation<double>? get animation => _animation;
  Animation<double>? _animation;

  /// The animation controller that the route uses to drive the transitions.
  ///
  /// The animation itself is exposed by the [animation] property.
  @protected
  AnimationController? get controller => _controller;
  AnimationController? _controller;

  /// The animation for the route being pushed on top of this route. This
  /// animation lets this route coordinate with the entrance and exit transition
  /// of route pushed on top of this route.
  Animation<double>? get secondaryAnimation => _secondaryAnimation;
  final ProxyAnimation _secondaryAnimation = ProxyAnimation(kAlwaysDismissedAnimation);

  /// Whether to takeover the [controller] created by [createAnimationController].
  ///
  /// If true, this route will call [AnimationController.dispose] when the
  /// controller is no longer needed.
  /// If false, the controller should be disposed by whoever owned it.
  ///
  /// It defaults to `true`.
  bool willDisposeAnimationController = true;

  /// Called to create the animation controller that will drive the transitions to
  /// this route from the previous one, and back to the previous route from this
  /// one.
  ///
  /// The returned controller will be disposed by [AnimationController.dispose]
  /// if the [willDisposeAnimationController] is `true`.
  AnimationController createAnimationController() {
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    final Duration duration = transitionDuration;
    final Duration reverseDuration = reverseTransitionDuration;
    assert(duration != null && duration >= Duration.zero);
    return AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      vsync: navigator!,
    );
  }

  /// Called to create the animation that exposes the current progress of
  /// the transition controlled by the animation controller created by
  /// [createAnimationController()].
  Animation<double> createAnimation() {
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    assert(_controller != null);
    return _controller!.view;
  }

  T? _result;

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
        // We might still be an active route if a subclass is controlling the
        // transition and hits the dismissed status. For example, the iOS
        // back gesture drives this animation to the dismissed status before
        // removing the route and disposing it.
        if (!isActive) {
          navigator!.finalizeRoute(this);
          _popFinalized = true;
        }
        break;
    }
  }

  @override
  void install() {
    assert(!_transitionCompleter.isCompleted, 'Cannot install a $runtimeType after disposing it.');
    _controller = createAnimationController();
    assert(_controller != null, '$runtimeType.createAnimationController() returned null.');
    _animation = createAnimation()
      ..addStatusListener(_handleStatusChanged);
    assert(_animation != null, '$runtimeType.createAnimation() returned null.');
    super.install();
    if (_animation!.isCompleted && overlayEntries.isNotEmpty) {
      overlayEntries.first.opaque = opaque;
    }
  }

  @override
  TickerFuture didPush() {
    assert(_controller != null, '$runtimeType.didPush called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    super.didPush();
    return _controller!.forward();
  }

  @override
  void didAdd() {
    assert(_controller != null, '$runtimeType.didPush called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    super.didAdd();
    _controller!.value = _controller!.upperBound;
  }

  @override
  void didReplace(Route<dynamic>? oldRoute) {
    assert(_controller != null, '$runtimeType.didReplace called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    if (oldRoute is TransitionRoute)
      _controller!.value = oldRoute._controller!.value;
    super.didReplace(oldRoute);
  }

  @override
  bool didPop(T? result) {
    assert(_controller != null, '$runtimeType.didPop called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    _result = result;
    _controller!.reverse();
    return super.didPop(result);
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    assert(_controller != null, '$runtimeType.didPopNext called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    _updateSecondaryAnimation(nextRoute);
    super.didPopNext(nextRoute);
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    assert(_controller != null, '$runtimeType.didChangeNext called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    _updateSecondaryAnimation(nextRoute);
    super.didChangeNext(nextRoute);
  }

  // A callback method that disposes existing train hopping animation and
  // removes its listener.
  //
  // This property is non-null if there is a train hopping in progress, and the
  // caller must reset this property to null after it is called.
  VoidCallback? _trainHoppingListenerRemover;

  void _updateSecondaryAnimation(Route<dynamic>? nextRoute) {
    // There is an existing train hopping in progress. Unfortunately, we cannot
    // dispose current train hopping animation until we replace it with a new
    // animation.
    final VoidCallback? previousTrainHoppingListenerRemover = _trainHoppingListenerRemover;
    _trainHoppingListenerRemover = null;

    if (nextRoute is TransitionRoute<dynamic> && canTransitionTo(nextRoute) && nextRoute.canTransitionFrom(this)) {
      final Animation<double>? current = _secondaryAnimation.parent;
      if (current != null) {
        final Animation<double> currentTrain = (current is TrainHoppingAnimation ? current.currentTrain : current)!;
        final Animation<double> nextTrain = nextRoute._animation!;
        if (
          currentTrain.value == nextTrain.value ||
          nextTrain.status == AnimationStatus.completed ||
          nextTrain.status == AnimationStatus.dismissed
        ) {
          _setSecondaryAnimation(nextTrain, nextRoute.completed);
        } else {
          // Two trains animate at different values. We have to do train hopping.
          // There are three possibilities of train hopping:
          //  1. We hop on the nextTrain when two trains meet in the middle using
          //     TrainHoppingAnimation.
          //  2. There is no chance to hop on nextTrain because two trains never
          //     cross each other. We have to directly set the animation to
          //     nextTrain once the nextTrain stops animating.
          //  3. A new _updateSecondaryAnimation is called before train hopping
          //     finishes. We leave a listener remover for the next call to
          //     properly clean up the existing train hopping.
          TrainHoppingAnimation? newAnimation;
          void _jumpOnAnimationEnd(AnimationStatus status) {
            switch (status) {
              case AnimationStatus.completed:
              case AnimationStatus.dismissed:
                // The nextTrain has stopped animating without train hopping.
                // Directly sets the secondary animation and disposes the
                // TrainHoppingAnimation.
                _setSecondaryAnimation(nextTrain, nextRoute.completed);
                if (_trainHoppingListenerRemover != null) {
                  _trainHoppingListenerRemover!();
                  _trainHoppingListenerRemover = null;
                }
                break;
              case AnimationStatus.forward:
              case AnimationStatus.reverse:
                break;
            }
          }
          _trainHoppingListenerRemover = () {
            nextTrain.removeStatusListener(_jumpOnAnimationEnd);
            newAnimation?.dispose();
          };
          nextTrain.addStatusListener(_jumpOnAnimationEnd);
          newAnimation = TrainHoppingAnimation(
            currentTrain,
            nextTrain,
            onSwitchedTrain: () {
              assert(_secondaryAnimation.parent == newAnimation);
              assert(newAnimation!.currentTrain == nextRoute._animation);
              // We can hop on the nextTrain, so we don't need to listen to
              // whether the nextTrain has stopped.
              _setSecondaryAnimation(newAnimation!.currentTrain, nextRoute.completed);
              if (_trainHoppingListenerRemover != null) {
                _trainHoppingListenerRemover!();
                _trainHoppingListenerRemover = null;
              }
            },
          );
          _setSecondaryAnimation(newAnimation, nextRoute.completed);
        }
      } else {
        _setSecondaryAnimation(nextRoute._animation, nextRoute.completed);
      }
    } else {
      _setSecondaryAnimation(kAlwaysDismissedAnimation);
    }
    // Finally, we dispose any previous train hopping animation because it
    // has been successfully updated at this point.
    if (previousTrainHoppingListenerRemover != null) {
      previousTrainHoppingListenerRemover();
    }
  }

  void _setSecondaryAnimation(Animation<double>? animation, [Future<dynamic>? disposed]) {
    _secondaryAnimation.parent = animation;
    // Releases the reference to the next route's animation when that route
    // is disposed.
    disposed?.then((dynamic _) {
      if (_secondaryAnimation.parent == animation) {
        _secondaryAnimation.parent = kAlwaysDismissedAnimation;
        if (animation is TrainHoppingAnimation) {
          animation.dispose();
        }
      }
    });
  }

  /// Returns true if this route supports a transition animation that runs
  /// when [nextRoute] is pushed on top of it or when [nextRoute] is popped
  /// off of it.
  ///
  /// Subclasses can override this method to restrict the set of routes they
  /// need to coordinate transitions with.
  ///
  /// If true, and `nextRoute.canTransitionFrom()` is true, then the
  /// [ModalRoute.buildTransitions] `secondaryAnimation` will run from 0.0 - 1.0
  /// when [nextRoute] is pushed on top of this one.  Similarly, if
  /// the [nextRoute] is popped off of this route, the
  /// `secondaryAnimation` will run from 1.0 - 0.0.
  ///
  /// If false, this route's [ModalRoute.buildTransitions] `secondaryAnimation` parameter
  /// value will be [kAlwaysDismissedAnimation]. In other words, this route
  /// will not animate when [nextRoute] is pushed on top of it or when
  /// [nextRoute] is popped off of it.
  ///
  /// Returns true by default.
  ///
  /// See also:
  ///
  ///  * [canTransitionFrom], which must be true for [nextRoute] for the
  ///    [ModalRoute.buildTransitions] `secondaryAnimation` to run.
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => true;

  /// Returns true if [previousRoute] should animate when this route
  /// is pushed on top of it or when then this route is popped off of it.
  ///
  /// Subclasses can override this method to restrict the set of routes they
  /// need to coordinate transitions with.
  ///
  /// If true, and `previousRoute.canTransitionTo()` is true, then the
  /// previous route's [ModalRoute.buildTransitions] `secondaryAnimation` will
  /// run from 0.0 - 1.0 when this route is pushed on top of
  /// it. Similarly, if this route is popped off of [previousRoute]
  /// the previous route's `secondaryAnimation` will run from 1.0 - 0.0.
  ///
  /// If false, then the previous route's [ModalRoute.buildTransitions]
  /// `secondaryAnimation` value will be kAlwaysDismissedAnimation. In
  /// other words [previousRoute] will not animate when this route is
  /// pushed on top of it or when then this route is popped off of it.
  ///
  /// Returns true by default.
  ///
  /// See also:
  ///
  ///  * [canTransitionTo], which must be true for [previousRoute] for its
  ///    [ModalRoute.buildTransitions] `secondaryAnimation` to run.
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => true;

  @override
  void dispose() {
    assert(!_transitionCompleter.isCompleted, 'Cannot dispose a $runtimeType twice.');
    _animation?.removeStatusListener(_handleStatusChanged);
    if (willDisposeAnimationController) {
      _controller?.dispose();
    }
    _transitionCompleter.complete(_result);
    super.dispose();
  }

  /// A short description of this route useful for debugging.
  String get debugLabel => objectRuntimeType(this, 'TransitionRoute');

  @override
  String toString() => '${objectRuntimeType(this, 'TransitionRoute')}(animation: $_controller)';
}

/// An entry in the history of a [LocalHistoryRoute].
class LocalHistoryEntry {
  /// Creates an entry in the history of a [LocalHistoryRoute].
  LocalHistoryEntry({ this.onRemove });

  /// Called when this entry is removed from the history of its associated [LocalHistoryRoute].
  final VoidCallback? onRemove;

  LocalHistoryRoute<dynamic>? _owner;

  /// Remove this entry from the history of its associated [LocalHistoryRoute].
  void remove() {
    _owner?.removeLocalHistoryEntry(this);
    assert(_owner == null);
  }

  void _notifyRemoved() {
    onRemove?.call();
  }
}

/// A mixin used by routes to handle back navigations internally by popping a list.
///
/// When a [Navigator] is instructed to pop, the current route is given an
/// opportunity to handle the pop internally. A `LocalHistoryRoute` handles the
/// pop internally if its list of local history entries is non-empty. Rather
/// than being removed as the current route, the most recent [LocalHistoryEntry]
/// is removed from the list and its [LocalHistoryEntry.onRemove] is called.
mixin LocalHistoryRoute<T> on Route<T> {
  List<LocalHistoryEntry>? _localHistory;

  /// Adds a local history entry to this route.
  ///
  /// When asked to pop, if this route has any local history entries, this route
  /// will handle the pop internally by removing the most recently added local
  /// history entry.
  ///
  /// The given local history entry must not already be part of another local
  /// history route.
  ///
  /// {@tool snippet}
  ///
  /// The following example is an app with 2 pages: `HomePage` and `SecondPage`.
  /// The `HomePage` can navigate to the `SecondPage`.
  ///
  /// The `SecondPage` uses a [LocalHistoryEntry] to implement local navigation
  /// within that page. Pressing 'show rectangle' displays a red rectangle and
  /// adds a local history entry. At that point, pressing the '< back' button
  /// pops the latest route, which is the local history entry, and the red
  /// rectangle disappears. Pressing the '< back' button a second time
  /// once again pops the latest route, which is the `SecondPage`, itself.
  /// Therefore, the second press navigates back to the `HomePage`.
  ///
  /// ```dart
  /// class App extends StatelessWidget {
  ///   const App({Key? key}) : super(key: key);
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return MaterialApp(
  ///       initialRoute: '/',
  ///       routes: <String, WidgetBuilder>{
  ///         '/': (BuildContext context) => const HomePage(),
  ///         '/second_page': (BuildContext context) => const SecondPage(),
  ///       },
  ///     );
  ///   }
  /// }
  ///
  /// class HomePage extends StatefulWidget {
  ///   const HomePage({Key? key}) : super(key: key);
  ///
  ///   @override
  ///   State<HomePage> createState() => _HomePageState();
  /// }
  ///
  /// class _HomePageState extends State<HomePage> {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Scaffold(
  ///       body: Center(
  ///         child: Column(
  ///           mainAxisSize: MainAxisSize.min,
  ///           children: <Widget>[
  ///             const Text('HomePage'),
  ///             // Press this button to open the SecondPage.
  ///             ElevatedButton(
  ///               child: const Text('Second Page >'),
  ///               onPressed: () {
  ///                 Navigator.pushNamed(context, '/second_page');
  ///               },
  ///             ),
  ///           ],
  ///         ),
  ///       ),
  ///     );
  ///   }
  /// }
  ///
  /// class SecondPage extends StatefulWidget {
  ///   const SecondPage({Key? key}) : super(key: key);
  ///
  ///   @override
  ///   State<SecondPage> createState() => _SecondPageState();
  /// }
  ///
  /// class _SecondPageState extends State<SecondPage> {
  ///
  ///   bool _showRectangle = false;
  ///
  ///   Future<void> _navigateLocallyToShowRectangle() async {
  ///     // This local history entry essentially represents the display of the red
  ///     // rectangle. When this local history entry is removed, we hide the red
  ///     // rectangle.
  ///     setState(() => _showRectangle = true);
  ///     ModalRoute.of(context)?.addLocalHistoryEntry(
  ///         LocalHistoryEntry(
  ///             onRemove: () {
  ///               // Hide the red rectangle.
  ///               setState(() => _showRectangle = false);
  ///             }
  ///         )
  ///     );
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final Widget localNavContent = _showRectangle
  ///       ? Container(
  ///           width: 100.0,
  ///           height: 100.0,
  ///           color: Colors.red,
  ///         )
  ///       : ElevatedButton(
  ///           onPressed: _navigateLocallyToShowRectangle,
  ///           child: const Text('Show Rectangle'),
  ///         );
  ///
  ///     return Scaffold(
  ///       body: Center(
  ///         child: Column(
  ///           mainAxisAlignment: MainAxisAlignment.center,
  ///           children: <Widget>[
  ///             localNavContent,
  ///             ElevatedButton(
  ///               child: const Text('< Back'),
  ///               onPressed: () {
  ///                 // Pop a route. If this is pressed while the red rectangle is
  ///                 // visible then it will pop our local history entry, which
  ///                 // will hide the red rectangle. Otherwise, the SecondPage will
  ///                 // navigate back to the HomePage.
  ///                 Navigator.of(context).pop();
  ///               },
  ///             ),
  ///           ],
  ///         ),
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  void addLocalHistoryEntry(LocalHistoryEntry entry) {
    assert(entry._owner == null);
    entry._owner = this;
    _localHistory ??= <LocalHistoryEntry>[];
    final bool wasEmpty = _localHistory!.isEmpty;
    _localHistory!.add(entry);
    if (wasEmpty)
      changedInternalState();
  }

  /// Remove a local history entry from this route.
  ///
  /// The entry's [LocalHistoryEntry.onRemove] callback, if any, will be called
  /// synchronously.
  void removeLocalHistoryEntry(LocalHistoryEntry entry) {
    assert(entry != null);
    assert(entry._owner == this);
    assert(_localHistory!.contains(entry));
    _localHistory!.remove(entry);
    entry._owner = null;
    entry._notifyRemoved();
    if (_localHistory!.isEmpty) {
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        // The local history might be removed as a result of disposing inactive
        // elements during finalizeTree. The state is locked at this moment, and
        // we can only notify state has changed in the next frame.
        SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
          changedInternalState();
        });
      } else {
        changedInternalState();
      }
    }
  }

  @override
  Future<RoutePopDisposition> willPop() async {
    if (willHandlePopInternally)
      return RoutePopDisposition.pop;
    return super.willPop();
  }

  @override
  bool didPop(T? result) {
    if (_localHistory != null && _localHistory!.isNotEmpty) {
      final LocalHistoryEntry entry = _localHistory!.removeLast();
      assert(entry._owner == this);
      entry._owner = null;
      entry._notifyRemoved();
      if (_localHistory!.isEmpty)
        changedInternalState();
      return false;
    }
    return super.didPop(result);
  }

  @override
  bool get willHandlePopInternally {
    return _localHistory != null && _localHistory!.isNotEmpty;
  }
}

class _DismissModalAction extends DismissAction {
  _DismissModalAction(this.context);

  final BuildContext context;

  @override
  bool isEnabled(DismissIntent intent) {
    final ModalRoute<dynamic> route = ModalRoute.of<dynamic>(context)!;
    return route.barrierDismissible;
  }

  @override
  Object invoke(DismissIntent intent) {
    return Navigator.of(context).maybePop();
  }
}

class _ModalScopeStatus extends InheritedWidget {
  const _ModalScopeStatus({
    Key? key,
    required this.isCurrent,
    required this.canPop,
    required this.route,
    required Widget child,
  }) : assert(isCurrent != null),
       assert(canPop != null),
       assert(route != null),
       assert(child != null),
       super(key: key, child: child);

  final bool isCurrent;
  final bool canPop;
  final Route<dynamic> route;

  @override
  bool updateShouldNotify(_ModalScopeStatus old) {
    return isCurrent != old.isCurrent ||
           canPop != old.canPop ||
           route != old.route;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(FlagProperty('isCurrent', value: isCurrent, ifTrue: 'active', ifFalse: 'inactive'));
    description.add(FlagProperty('canPop', value: canPop, ifTrue: 'can pop'));
  }
}

class _ModalScope<T> extends StatefulWidget {
  const _ModalScope({
    Key? key,
    required this.route,
  }) : super(key: key);

  final ModalRoute<T> route;

  @override
  _ModalScopeState<T> createState() => _ModalScopeState<T>();
}

class _ModalScopeState<T> extends State<_ModalScope<T>> {
  // We cache the result of calling the route's buildPage, and clear the cache
  // whenever the dependencies change. This implements the contract described in
  // the documentation for buildPage, namely that it gets called once, unless
  // something like a ModalRoute.of() dependency triggers an update.
  Widget? _page;

  // This is the combination of the two animations for the route.
  late Listenable _listenable;

  /// The node this scope will use for its root [FocusScope] widget.
  final FocusScopeNode focusScopeNode = FocusScopeNode(debugLabel: '$_ModalScopeState Focus Scope');
  final ScrollController primaryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final List<Listenable> animations = <Listenable>[
      if (widget.route.animation != null) widget.route.animation!,
      if (widget.route.secondaryAnimation != null) widget.route.secondaryAnimation!,
    ];
    _listenable = Listenable.merge(animations);
    if (widget.route.isCurrent && _shouldRequestFocus) {
      widget.route.navigator!.focusScopeNode.setFirstFocus(focusScopeNode);
    }
  }

  @override
  void didUpdateWidget(_ModalScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.route == oldWidget.route);
    if (widget.route.isCurrent && _shouldRequestFocus) {
      widget.route.navigator!.focusScopeNode.setFirstFocus(focusScopeNode);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _page = null;
  }

  void _forceRebuildPage() {
    setState(() {
      _page = null;
    });
  }

  @override
  void dispose() {
    focusScopeNode.dispose();
    super.dispose();
  }

  bool get _shouldIgnoreFocusRequest {
    return widget.route.animation?.status == AnimationStatus.reverse ||
      (widget.route.navigator?.userGestureInProgress ?? false);
  }

  bool get _shouldRequestFocus {
    return widget.route.navigator!.widget.requestFocus;
  }

  // This should be called to wrap any changes to route.isCurrent, route.canPop,
  // and route.offstage.
  void _routeSetState(VoidCallback fn) {
    if (widget.route.isCurrent && !_shouldIgnoreFocusRequest && _shouldRequestFocus) {
      widget.route.navigator!.focusScopeNode.setFirstFocus(focusScopeNode);
    }
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.route.restorationScopeId,
      builder: (BuildContext context, Widget? child) {
        assert(child != null);
        return RestorationScope(
          restorationId: widget.route.restorationScopeId.value,
          child: child!,
        );
      },
      child: _ModalScopeStatus(
        route: widget.route,
        isCurrent: widget.route.isCurrent, // _routeSetState is called if this updates
        canPop: widget.route.canPop, // _routeSetState is called if this updates
        child: Offstage(
          offstage: widget.route.offstage, // _routeSetState is called if this updates
          child: PageStorage(
            bucket: widget.route._storageBucket, // immutable
            child: Builder(
              builder: (BuildContext context) {
                return Actions(
                  actions: <Type, Action<Intent>>{
                    DismissIntent: _DismissModalAction(context),
                  },
                  child: PrimaryScrollController(
                    controller: primaryScrollController,
                    child: FocusScope(
                      node: focusScopeNode, // immutable
                      child: FocusTrap(
                        focusScopeNode: focusScopeNode,
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _listenable, // immutable
                            builder: (BuildContext context, Widget? child) {
                              return widget.route.buildTransitions(
                                context,
                                widget.route.animation!,
                                widget.route.secondaryAnimation!,
                                // This additional AnimatedBuilder is include because if the
                                // value of the userGestureInProgressNotifier changes, it's
                                // only necessary to rebuild the IgnorePointer widget and set
                                // the focus node's ability to focus.
                                AnimatedBuilder(
                                  animation: widget.route.navigator?.userGestureInProgressNotifier ?? ValueNotifier<bool>(false),
                                  builder: (BuildContext context, Widget? child) {
                                    final bool ignoreEvents = _shouldIgnoreFocusRequest;
                                    focusScopeNode.canRequestFocus = !ignoreEvents;
                                    return IgnorePointer(
                                      ignoring: ignoreEvents,
                                      child: child,
                                    );
                                  },
                                  child: child,
                                ),
                              );
                            },
                            child: _page ??= RepaintBoundary(
                              key: widget.route._subtreeKey, // immutable
                              child: Builder(
                                builder: (BuildContext context) {
                                  return widget.route.buildPage(
                                    context,
                                    widget.route.animation!,
                                    widget.route.secondaryAnimation!,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A route that blocks interaction with previous routes.
///
/// [ModalRoute]s cover the entire [Navigator]. They are not necessarily
/// [opaque], however; for example, a pop-up menu uses a [ModalRoute] but only
/// shows the menu in a small box overlapping the previous route.
///
/// The `T` type argument is the return value of the route. If there is no
/// return value, consider using `void` as the return value.
abstract class ModalRoute<T> extends TransitionRoute<T> with LocalHistoryRoute<T> {
  /// Creates a route that blocks interaction with previous routes.
  ModalRoute({
    RouteSettings? settings,
    this.filter,
  }) : super(settings: settings);

  /// The filter to add to the barrier.
  ///
  /// If given, this filter will be applied to the modal barrier using
  /// [BackdropFilter]. This allows blur effects, for example.
  final ui.ImageFilter? filter;

  // The API for general users of this class

  /// Returns the modal route most closely associated with the given context.
  ///
  /// Returns null if the given context is not associated with a modal route.
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ModalRoute<int>? route = ModalRoute.of<int>(context);
  /// ```
  /// {@end-tool}
  ///
  /// The given [BuildContext] will be rebuilt if the state of the route changes
  /// while it is visible (specifically, if [isCurrent] or [canPop] change value).
  @optionalTypeArgs
  static ModalRoute<T>? of<T extends Object?>(BuildContext context) {
    final _ModalScopeStatus? widget = context.dependOnInheritedWidgetOfExactType<_ModalScopeStatus>();
    return widget?.route as ModalRoute<T>?;
  }

  /// Schedule a call to [buildTransitions].
  ///
  /// Whenever you need to change internal state for a [ModalRoute] object, make
  /// the change in a function that you pass to [setState], as in:
  ///
  /// ```dart
  /// setState(() { myState = newValue });
  /// ```
  ///
  /// If you just change the state directly without calling [setState], then the
  /// route will not be scheduled for rebuilding, meaning that its rendering
  /// will not be updated.
  @protected
  void setState(VoidCallback fn) {
    if (_scopeKey.currentState != null) {
      _scopeKey.currentState!._routeSetState(fn);
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
          && route is ModalRoute
          && route.settings.name == name;
    };
  }

  // The API for subclasses to override - used by _ModalScope

  /// Override this method to build the primary content of this route.
  ///
  /// The arguments have the following meanings:
  ///
  ///  * `context`: The context in which the route is being built.
  ///  * [animation]: The animation for this route's transition. When entering,
  ///    the animation runs forward from 0.0 to 1.0. When exiting, this animation
  ///    runs backwards from 1.0 to 0.0.
  ///  * [secondaryAnimation]: The animation for the route being pushed on top of
  ///    this route. This animation lets this route coordinate with the entrance
  ///    and exit transition of routes pushed on top of this route.
  ///
  /// This method is only called when the route is first built, and rarely
  /// thereafter. In particular, it is not automatically called again when the
  /// route's state changes unless it uses [ModalRoute.of]. For a builder that
  /// is called every time the route's state changes, consider
  /// [buildTransitions]. For widgets that change their behavior when the
  /// route's state changes, consider [ModalRoute.of] to obtain a reference to
  /// the route; this will cause the widget to be rebuilt each time the route
  /// changes state.
  ///
  /// In general, [buildPage] should be used to build the page contents, and
  /// [buildTransitions] for the widgets that change as the page is brought in
  /// and out of view. Avoid using [buildTransitions] for content that never
  /// changes; building such content once from [buildPage] is more efficient.
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation);

  /// Override this method to wrap the [child] with one or more transition
  /// widgets that define how the route arrives on and leaves the screen.
  ///
  /// By default, the child (which contains the widget returned by [buildPage])
  /// is not wrapped in any transition widgets.
  ///
  /// The [buildTransitions] method, in contrast to [buildPage], is called each
  /// time the [Route]'s state changes while it is visible (e.g. if the value of
  /// [canPop] changes on the active route).
  ///
  /// The [buildTransitions] method is typically used to define transitions
  /// that animate the new topmost route's comings and goings. When the
  /// [Navigator] pushes a route on the top of its stack, the new route's
  /// primary [animation] runs from 0.0 to 1.0. When the Navigator pops the
  /// topmost route, e.g. because the use pressed the back button, the
  /// primary animation runs from 1.0 to 0.0.
  ///
  /// {@tool snippet}
  /// The following example uses the primary animation to drive a
  /// [SlideTransition] that translates the top of the new route vertically
  /// from the bottom of the screen when it is pushed on the Navigator's
  /// stack. When the route is popped the SlideTransition translates the
  /// route from the top of the screen back to the bottom.
  ///
  /// We've used [PageRouteBuilder] to demonstrate the [buildTransitions] method
  /// here. The body of an override of the [buildTransitions] method would be
  /// defined in the same way.
  ///
  /// ```dart
  /// PageRouteBuilder(
  ///   pageBuilder: (BuildContext context,
  ///       Animation<double> animation,
  ///       Animation<double> secondaryAnimation,
  ///   ) {
  ///     return Scaffold(
  ///       appBar: AppBar(title: const Text('Hello')),
  ///       body: const Center(
  ///         child: Text('Hello World'),
  ///       ),
  ///     );
  ///   },
  ///   transitionsBuilder: (
  ///       BuildContext context,
  ///       Animation<double> animation,
  ///       Animation<double> secondaryAnimation,
  ///       Widget child,
  ///    ) {
  ///     return SlideTransition(
  ///       position: Tween<Offset>(
  ///         begin: const Offset(0.0, 1.0),
  ///         end: Offset.zero,
  ///       ).animate(animation),
  ///       child: child, // child is the value returned by pageBuilder
  ///     );
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// When the [Navigator] pushes a route on the top of its stack, the
  /// [secondaryAnimation] can be used to define how the route that was on
  /// the top of the stack leaves the screen. Similarly when the topmost route
  /// is popped, the secondaryAnimation can be used to define how the route
  /// below it reappears on the screen. When the Navigator pushes a new route
  /// on the top of its stack, the old topmost route's secondaryAnimation
  /// runs from 0.0 to 1.0. When the Navigator pops the topmost route, the
  /// secondaryAnimation for the route below it runs from 1.0 to 0.0.
  ///
  /// {@tool snippet}
  /// The example below adds a transition that's driven by the
  /// [secondaryAnimation]. When this route disappears because a new route has
  /// been pushed on top of it, it translates in the opposite direction of
  /// the new route. Likewise when the route is exposed because the topmost
  /// route has been popped off.
  ///
  /// ```dart
  /// PageRouteBuilder(
  ///   pageBuilder: (BuildContext context,
  ///       Animation<double> animation,
  ///       Animation<double> secondaryAnimation,
  ///   ) {
  ///     return Scaffold(
  ///       appBar: AppBar(title: const Text('Hello')),
  ///       body: const Center(
  ///         child: Text('Hello World'),
  ///       ),
  ///     );
  ///   },
  ///   transitionsBuilder: (
  ///       BuildContext context,
  ///       Animation<double> animation,
  ///       Animation<double> secondaryAnimation,
  ///       Widget child,
  ///   ) {
  ///     return SlideTransition(
  ///       position: Tween<Offset>(
  ///         begin: const Offset(0.0, 1.0),
  ///         end: Offset.zero,
  ///       ).animate(animation),
  ///       child: SlideTransition(
  ///         position: Tween<Offset>(
  ///           begin: Offset.zero,
  ///           end: const Offset(0.0, 1.0),
  ///         ).animate(secondaryAnimation),
  ///         child: child,
  ///       ),
  ///      );
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// In practice the `secondaryAnimation` is used pretty rarely.
  ///
  /// The arguments to this method are as follows:
  ///
  ///  * `context`: The context in which the route is being built.
  ///  * [animation]: When the [Navigator] pushes a route on the top of its stack,
  ///    the new route's primary [animation] runs from 0.0 to 1.0. When the [Navigator]
  ///    pops the topmost route this animation runs from 1.0 to 0.0.
  ///  * [secondaryAnimation]: When the Navigator pushes a new route
  ///    on the top of its stack, the old topmost route's [secondaryAnimation]
  ///    runs from 0.0 to 1.0. When the [Navigator] pops the topmost route, the
  ///    [secondaryAnimation] for the route below it runs from 1.0 to 0.0.
  ///  * `child`, the page contents, as returned by [buildPage].
  ///
  /// See also:
  ///
  ///  * [buildPage], which is used to describe the actual contents of the page,
  ///    and whose result is passed to the `child` argument of this method.
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  @override
  void install() {
    super.install();
    _animationProxy = ProxyAnimation(super.animation);
    _secondaryAnimationProxy = ProxyAnimation(super.secondaryAnimation);
  }

  @override
  TickerFuture didPush() {
    if (_scopeKey.currentState != null && navigator!.widget.requestFocus) {
      navigator!.focusScopeNode.setFirstFocus(_scopeKey.currentState!.focusScopeNode);
    }
    return super.didPush();
  }

  @override
  void didAdd() {
    if (_scopeKey.currentState != null && navigator!.widget.requestFocus) {
      navigator!.focusScopeNode.setFirstFocus(_scopeKey.currentState!.focusScopeNode);
    }
    super.didAdd();
  }

  // The API for subclasses to override - used by this class

  /// {@template flutter.widgets.ModalRoute.barrierDismissible}
  /// Whether you can dismiss this route by tapping the modal barrier.
  ///
  /// The modal barrier is the scrim that is rendered behind each route, which
  /// generally prevents the user from interacting with the route below the
  /// current route, and normally partially obscures such routes.
  ///
  /// For example, when a dialog is on the screen, the page below the dialog is
  /// usually darkened by the modal barrier.
  ///
  /// If [barrierDismissible] is true, then tapping this barrier will cause the
  /// current route to be popped (see [Navigator.pop]) with null as the value.
  ///
  /// If [barrierDismissible] is false, then tapping the barrier has no effect.
  ///
  /// If this getter would ever start returning a different value,
  /// either [changedInternalState] or [changedExternalState] should
  /// be invoked so that the change can take effect.
  ///
  /// It is safe to use `navigator.context` to look up inherited
  /// widgets here, because the [Navigator] calls
  /// [changedExternalState] whenever its dependencies change, and
  /// [changedExternalState] causes the modal barrier to rebuild.
  ///
  /// See also:
  ///
  ///  * [barrierColor], which controls the color of the scrim for this route.
  ///  * [ModalBarrier], the widget that implements this feature.
  /// {@endtemplate}
  bool get barrierDismissible;

  /// Whether the semantics of the modal barrier are included in the
  /// semantics tree.
  ///
  /// The modal barrier is the scrim that is rendered behind each route, which
  /// generally prevents the user from interacting with the route below the
  /// current route, and normally partially obscures such routes.
  ///
  /// If [semanticsDismissible] is true, then modal barrier semantics are
  /// included in the semantics tree.
  ///
  /// If [semanticsDismissible] is false, then modal barrier semantics are
  /// excluded from the semantics tree and tapping on the modal barrier
  /// has no effect.
  ///
  /// If this getter would ever start returning a different value,
  /// either [changedInternalState] or [changedExternalState] should
  /// be invoked so that the change can take effect.
  ///
  /// It is safe to use `navigator.context` to look up inherited
  /// widgets here, because the [Navigator] calls
  /// [changedExternalState] whenever its dependencies change, and
  /// [changedExternalState] causes the modal barrier to rebuild.
  bool get semanticsDismissible => true;

  /// {@template flutter.widgets.ModalRoute.barrierColor}
  /// The color to use for the modal barrier. If this is null, the barrier will
  /// be transparent.
  ///
  /// The modal barrier is the scrim that is rendered behind each route, which
  /// generally prevents the user from interacting with the route below the
  /// current route, and normally partially obscures such routes.
  ///
  /// For example, when a dialog is on the screen, the page below the dialog is
  /// usually darkened by the modal barrier.
  ///
  /// The color is ignored, and the barrier made invisible, when
  /// [ModalRoute.offstage] is true.
  ///
  /// While the route is animating into position, the color is animated from
  /// transparent to the specified color.
  /// {@endtemplate}
  ///
  /// If this getter would ever start returning a different color, one
  /// of the [changedInternalState] or [changedExternalState] methods
  /// should be invoked so that the change can take effect.
  ///
  /// It is safe to use `navigator.context` to look up inherited
  /// widgets here, because the [Navigator] calls
  /// [changedExternalState] whenever its dependencies change, and
  /// [changedExternalState] causes the modal barrier to rebuild.
  ///
  /// {@tool snippet}
  ///
  /// For example, to make the barrier color use the theme's
  /// background color, one could say:
  ///
  /// ```dart
  /// Color get barrierColor => Theme.of(navigator.context).backgroundColor;
  /// ```
  ///
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [barrierDismissible], which controls the behavior of the barrier when
  ///    tapped.
  ///  * [ModalBarrier], the widget that implements this feature.
  Color? get barrierColor;

  /// {@template flutter.widgets.ModalRoute.barrierLabel}
  /// The semantic label used for a dismissible barrier.
  ///
  /// If the barrier is dismissible, this label will be read out if
  /// accessibility tools (like VoiceOver on iOS) focus on the barrier.
  ///
  /// The modal barrier is the scrim that is rendered behind each route, which
  /// generally prevents the user from interacting with the route below the
  /// current route, and normally partially obscures such routes.
  ///
  /// For example, when a dialog is on the screen, the page below the dialog is
  /// usually darkened by the modal barrier.
  /// {@endtemplate}
  ///
  /// If this getter would ever start returning a different label,
  /// either [changedInternalState] or [changedExternalState] should
  /// be invoked so that the change can take effect.
  ///
  /// It is safe to use `navigator.context` to look up inherited
  /// widgets here, because the [Navigator] calls
  /// [changedExternalState] whenever its dependencies change, and
  /// [changedExternalState] causes the modal barrier to rebuild.
  ///
  /// See also:
  ///
  ///  * [barrierDismissible], which controls the behavior of the barrier when
  ///    tapped.
  ///  * [ModalBarrier], the widget that implements this feature.
  String? get barrierLabel;

  /// The curve that is used for animating the modal barrier in and out.
  ///
  /// The modal barrier is the scrim that is rendered behind each route, which
  /// generally prevents the user from interacting with the route below the
  /// current route, and normally partially obscures such routes.
  ///
  /// For example, when a dialog is on the screen, the page below the dialog is
  /// usually darkened by the modal barrier.
  ///
  /// While the route is animating into position, the color is animated from
  /// transparent to the specified [barrierColor].
  ///
  /// If this getter would ever start returning a different curve,
  /// either [changedInternalState] or [changedExternalState] should
  /// be invoked so that the change can take effect.
  ///
  /// It is safe to use `navigator.context` to look up inherited
  /// widgets here, because the [Navigator] calls
  /// [changedExternalState] whenever its dependencies change, and
  /// [changedExternalState] causes the modal barrier to rebuild.
  ///
  /// It defaults to [Curves.ease].
  ///
  /// See also:
  ///
  ///  * [barrierColor], which determines the color that the modal transitions
  ///    to.
  ///  * [Curves] for a collection of common curves.
  ///  * [AnimatedModalBarrier], the widget that implements this feature.
  Curve get barrierCurve => Curves.ease;

  /// {@template flutter.widgets.ModalRoute.maintainState}
  /// Whether the route should remain in memory when it is inactive.
  ///
  /// If this is true, then the route is maintained, so that any futures it is
  /// holding from the next route will properly resolve when the next route
  /// pops. If this is not necessary, this can be set to false to allow the
  /// framework to entirely discard the route's widget hierarchy when it is not
  /// visible.
  /// {@endtemplate}
  ///
  /// If this getter would ever start returning a different value, the
  /// [changedInternalState] should be invoked so that the change can take
  /// effect.
  bool get maintainState;


  // The API for _ModalScope and HeroController

  /// Whether this route is currently offstage.
  ///
  /// On the first frame of a route's entrance transition, the route is built
  /// [Offstage] using an animation progress of 1.0. The route is invisible and
  /// non-interactive, but each widget has its final size and position. This
  /// mechanism lets the [HeroController] determine the final local of any hero
  /// widgets being animated as part of the transition.
  ///
  /// The modal barrier, if any, is not rendered if [offstage] is true (see
  /// [barrierColor]).
  ///
  /// Whenever this changes value, [changedInternalState] is called.
  bool get offstage => _offstage;
  bool _offstage = false;
  set offstage(bool value) {
    if (_offstage == value)
      return;
    setState(() {
      _offstage = value;
    });
    _animationProxy!.parent = _offstage ? kAlwaysCompleteAnimation : super.animation;
    _secondaryAnimationProxy!.parent = _offstage ? kAlwaysDismissedAnimation : super.secondaryAnimation;
    changedInternalState();
  }

  /// The build context for the subtree containing the primary content of this route.
  BuildContext? get subtreeContext => _subtreeKey.currentContext;

  @override
  Animation<double>? get animation => _animationProxy;
  ProxyAnimation? _animationProxy;

  @override
  Animation<double>? get secondaryAnimation => _secondaryAnimationProxy;
  ProxyAnimation? _secondaryAnimationProxy;

  final List<WillPopCallback> _willPopCallbacks = <WillPopCallback>[];

  /// Returns [RoutePopDisposition.doNotPop] if any of callbacks added with
  /// [addScopedWillPopCallback] returns either false or null. If they all
  /// return true, the base [Route.willPop]'s result will be returned. The
  /// callbacks will be called in the order they were added, and will only be
  /// called if all previous callbacks returned true.
  ///
  /// Typically this method is not overridden because applications usually
  /// don't create modal routes directly, they use higher level primitives
  /// like [showDialog]. The scoped [WillPopCallback] list makes it possible
  /// for ModalRoute descendants to collectively define the value of `willPop`.
  ///
  /// See also:
  ///
  ///  * [Form], which provides an `onWillPop` callback that uses this mechanism.
  ///  * [addScopedWillPopCallback], which adds a callback to the list this
  ///    method checks.
  ///  * [removeScopedWillPopCallback], which removes a callback from the list
  ///    this method checks.
  @override
  Future<RoutePopDisposition> willPop() async {
    final _ModalScopeState<T>? scope = _scopeKey.currentState;
    assert(scope != null);
    for (final WillPopCallback callback in List<WillPopCallback>.of(_willPopCallbacks)) {
      if (await callback() != true)
        return RoutePopDisposition.doNotPop;
    }
    return super.willPop();
  }

  /// Enables this route to veto attempts by the user to dismiss it.
  ///
  /// {@tool snippet}
  /// This callback is typically added using a [WillPopScope] widget. That
  /// widget finds the enclosing [ModalRoute] and uses this function to register
  /// this callback:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return WillPopScope(
  ///     onWillPop: () async {
  ///       // ask the user if they are sure
  ///       return true;
  ///     },
  ///     child: Container(),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// This callback runs asynchronously and it's possible that it will be called
  /// after its route has been disposed. The callback should check [State.mounted]
  /// before doing anything.
  ///
  /// A typical application of this callback would be to warn the user about
  /// unsaved [Form] data if the user attempts to back out of the form. In that
  /// case, use the [Form.onWillPop] property to register the callback.
  ///
  /// {@tool snippet}
  /// To register a callback manually, look up the enclosing [ModalRoute] in a
  /// [State.didChangeDependencies] callback:
  ///
  /// ```dart
  /// abstract class _MyWidgetState extends State<MyWidget> {
  ///   ModalRoute<dynamic>? _route;
  ///
  ///   // ...
  ///
  ///   @override
  ///   void didChangeDependencies() {
  ///    super.didChangeDependencies();
  ///    _route?.removeScopedWillPopCallback(askTheUserIfTheyAreSure);
  ///    _route = ModalRoute.of(context);
  ///    _route?.addScopedWillPopCallback(askTheUserIfTheyAreSure);
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  /// If you register a callback manually, be sure to remove the callback with
  /// [removeScopedWillPopCallback] by the time the widget has been disposed. A
  /// stateful widget can do this in its dispose method (continuing the previous
  /// example):
  ///
  /// ```dart
  /// abstract class _MyWidgetState2 extends State<MyWidget> {
  ///   ModalRoute<dynamic>? _route;
  ///
  ///   // ...
  ///
  ///   @override
  ///   void dispose() {
  ///     _route?.removeScopedWillPopCallback(askTheUserIfTheyAreSure);
  ///     _route = null;
  ///     super.dispose();
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [WillPopScope], which manages the registration and unregistration
  ///    process automatically.
  ///  * [Form], which provides an `onWillPop` callback that uses this mechanism.
  ///  * [willPop], which runs the callbacks added with this method.
  ///  * [removeScopedWillPopCallback], which removes a callback from the list
  ///    that [willPop] checks.
  void addScopedWillPopCallback(WillPopCallback callback) {
    assert(_scopeKey.currentState != null, 'Tried to add a willPop callback to a route that is not currently in the tree.');
    _willPopCallbacks.add(callback);
  }

  /// Remove one of the callbacks run by [willPop].
  ///
  /// See also:
  ///
  ///  * [Form], which provides an `onWillPop` callback that uses this mechanism.
  ///  * [addScopedWillPopCallback], which adds callback to the list
  ///    checked by [willPop].
  void removeScopedWillPopCallback(WillPopCallback callback) {
    assert(_scopeKey.currentState != null, 'Tried to remove a willPop callback from a route that is not currently in the tree.');
    _willPopCallbacks.remove(callback);
  }

  /// True if one or more [WillPopCallback] callbacks exist.
  ///
  /// This method is used to disable the horizontal swipe pop gesture supported
  /// by [MaterialPageRoute] for [TargetPlatform.iOS] and
  /// [TargetPlatform.macOS]. If a pop might be vetoed, then the back gesture is
  /// disabled.
  ///
  /// The [buildTransitions] method will not be called again if this changes,
  /// since it can change during the build as descendants of the route add or
  /// remove callbacks.
  ///
  /// See also:
  ///
  ///  * [addScopedWillPopCallback], which adds a callback.
  ///  * [removeScopedWillPopCallback], which removes a callback.
  ///  * [willHandlePopInternally], which reports on another reason why
  ///    a pop might be vetoed.
  @protected
  bool get hasScopedWillPopCallback {
    return _willPopCallbacks.isNotEmpty;
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    changedInternalState();
  }

  @override
  void changedInternalState() {
    super.changedInternalState();
    setState(() { /* internal state already changed */ });
    _modalBarrier.markNeedsBuild();
    _modalScope.maintainState = maintainState;
  }

  @override
  void changedExternalState() {
    super.changedExternalState();
    _modalBarrier.markNeedsBuild();
    if (_scopeKey.currentState != null)
      _scopeKey.currentState!._forceRebuildPage();
  }

  /// Whether this route can be popped.
  ///
  /// A route can be popped if there is at least one active route below it, or
  /// if [willHandlePopInternally] returns true.
  ///
  /// When this changes, if the route is visible, the route will
  /// rebuild, and any widgets that used [ModalRoute.of] will be
  /// notified.
  bool get canPop => hasActiveRouteBelow || willHandlePopInternally;

  // Internals

  final GlobalKey<_ModalScopeState<T>> _scopeKey = GlobalKey<_ModalScopeState<T>>();
  final GlobalKey _subtreeKey = GlobalKey();
  final PageStorageBucket _storageBucket = PageStorageBucket();

  // one of the builders
  late OverlayEntry _modalBarrier;
  Widget _buildModalBarrier(BuildContext context) {
    Widget barrier;
    if (barrierColor != null && barrierColor!.alpha != 0 && !offstage) { // changedInternalState is called if barrierColor or offstage updates
      assert(barrierColor != barrierColor!.withOpacity(0.0));
      final Animation<Color?> color = animation!.drive(
        ColorTween(
          begin: barrierColor!.withOpacity(0.0),
          end: barrierColor, // changedInternalState is called if barrierColor updates
        ).chain(CurveTween(curve: barrierCurve)), // changedInternalState is called if barrierCurve updates
      );
      barrier = AnimatedModalBarrier(
        color: color,
        dismissible: barrierDismissible, // changedInternalState is called if barrierDismissible updates
        semanticsLabel: barrierLabel, // changedInternalState is called if barrierLabel updates
        barrierSemanticsDismissible: semanticsDismissible,
      );
    } else {
      barrier = ModalBarrier(
        dismissible: barrierDismissible, // changedInternalState is called if barrierDismissible updates
        semanticsLabel: barrierLabel, // changedInternalState is called if barrierLabel updates
        barrierSemanticsDismissible: semanticsDismissible,
      );
    }
    if (filter != null) {
      barrier = BackdropFilter(
        filter: filter!,
        child: barrier,
      );
    }
    barrier = IgnorePointer(
      ignoring: animation!.status == AnimationStatus.reverse || // changedInternalState is called when animation.status updates
                animation!.status == AnimationStatus.dismissed, // dismissed is possible when doing a manual pop gesture
      child: barrier,
    );
    if (semanticsDismissible && barrierDismissible) {
      // To be sorted after the _modalScope.
      barrier = Semantics(
        sortKey: const OrdinalSortKey(1.0),
        child: barrier,
      );
    }
    return barrier;
  }

  // We cache the part of the modal scope that doesn't change from frame to
  // frame so that we minimize the amount of building that happens.
  Widget? _modalScopeCache;

  // one of the builders
  Widget _buildModalScope(BuildContext context) {
    // To be sorted before the _modalBarrier.
    return _modalScopeCache ??= Semantics(
      sortKey: const OrdinalSortKey(0.0),
      child: _ModalScope<T>(
        key: _scopeKey,
        route: this,
        // _ModalScope calls buildTransitions() and buildChild(), defined above
      ),
    );
  }

  late OverlayEntry _modalScope;

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[
      _modalBarrier = OverlayEntry(builder: _buildModalBarrier),
      _modalScope = OverlayEntry(builder: _buildModalScope, maintainState: maintainState),
    ];
  }

  @override
  String toString() => '${objectRuntimeType(this, 'ModalRoute')}($settings, animation: $_animation)';
}

/// A modal route that overlays a widget over the current route.
abstract class PopupRoute<T> extends ModalRoute<T> {
  /// Initializes the [PopupRoute].
  PopupRoute({
    RouteSettings? settings,
    ui.ImageFilter? filter,
  }) : super(
         filter: filter,
         settings: settings,
       );

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;
}

/// A [Navigator] observer that notifies [RouteAware]s of changes to the
/// state of their [Route].
///
/// [RouteObserver] informs subscribers whenever a route of type `R` is pushed
/// on top of their own route of type `R` or popped from it. This is for example
/// useful to keep track of page transitions, e.g. a `RouteObserver<PageRoute>`
/// will inform subscribed [RouteAware]s whenever the user navigates away from
/// the current page route to another page route.
///
/// To be informed about route changes of any type, consider instantiating a
/// `RouteObserver<Route>`.
///
/// ## Type arguments
///
/// When using more aggressive
/// [lints](http://dart-lang.github.io/linter/lints/), in particular lints such
/// as `always_specify_types`, the Dart analyzer will require that certain types
/// be given with their type arguments. Since the [Route] class and its
/// subclasses have a type argument, this includes the arguments passed to this
/// class. Consider using `dynamic` to specify the entire class of routes rather
/// than only specific subtypes. For example, to watch for all [ModalRoute]
/// variants, the `RouteObserver<ModalRoute<dynamic>>` type may be used.
///
/// {@tool snippet}
///
/// To make a [StatefulWidget] aware of its current [Route] state, implement
/// [RouteAware] in its [State] and subscribe it to a [RouteObserver]:
///
/// ```dart
/// // Register the RouteObserver as a navigation observer.
/// final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
/// void main() {
///   runApp(MaterialApp(
///     home: Container(),
///     navigatorObservers: <RouteObserver<ModalRoute<void>>>[ routeObserver ],
///   ));
/// }
///
/// class RouteAwareWidget extends StatefulWidget {
///   const RouteAwareWidget({Key? key}) : super(key: key);
///
///   @override
///   State<RouteAwareWidget> createState() => RouteAwareWidgetState();
/// }
///
/// // Implement RouteAware in a widget's state and subscribe it to the RouteObserver.
/// class RouteAwareWidgetState extends State<RouteAwareWidget> with RouteAware {
///
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     routeObserver.subscribe(this, ModalRoute.of(context)!);
///   }
///
///   @override
///   void dispose() {
///     routeObserver.unsubscribe(this);
///     super.dispose();
///   }
///
///   @override
///   void didPush() {
///     // Route was pushed onto navigator and is now topmost route.
///   }
///
///   @override
///   void didPopNext() {
///     // Covering route was popped off the navigator.
///   }
///
///   @override
///   Widget build(BuildContext context) => Container();
///
/// }
/// ```
/// {@end-tool}
class RouteObserver<R extends Route<dynamic>> extends NavigatorObserver {
  final Map<R, Set<RouteAware>> _listeners = <R, Set<RouteAware>>{};

  /// Whether this observer is managing changes for the specified route.
  ///
  /// If asserts are disabled, this method will throw an exception.
  @visibleForTesting
  bool debugObservingRoute(R route) {
    late bool contained;
    assert(() {
      contained = _listeners.containsKey(route);
      return true;
    }());
    return contained;
  }

  /// Subscribe [routeAware] to be informed about changes to [route].
  ///
  /// Going forward, [routeAware] will be informed about qualifying changes
  /// to [route], e.g. when [route] is covered by another route or when [route]
  /// is popped off the [Navigator] stack.
  void subscribe(RouteAware routeAware, R route) {
    assert(routeAware != null);
    assert(route != null);
    final Set<RouteAware> subscribers = _listeners.putIfAbsent(route, () => <RouteAware>{});
    if (subscribers.add(routeAware)) {
      routeAware.didPush();
    }
  }

  /// Unsubscribe [routeAware].
  ///
  /// [routeAware] is no longer informed about changes to its route. If the given argument was
  /// subscribed to multiple types, this will unregister it (once) from each type.
  void unsubscribe(RouteAware routeAware) {
    assert(routeAware != null);
    final List<R> routes = _listeners.keys.toList();
    for (final R route in routes) {
      final Set<RouteAware>? subscribers = _listeners[route];
      if (subscribers != null) {
        subscribers.remove(routeAware);
        if (subscribers.isEmpty) {
          _listeners.remove(route);
        }
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is R && previousRoute is R) {
      final List<RouteAware>? previousSubscribers = _listeners[previousRoute]?.toList();

      if (previousSubscribers != null) {
        for (final RouteAware routeAware in previousSubscribers) {
          routeAware.didPopNext();
        }
      }

      final List<RouteAware>? subscribers = _listeners[route]?.toList();

      if (subscribers != null) {
        for (final RouteAware routeAware in subscribers) {
          routeAware.didPop();
        }
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is R && previousRoute is R) {
      final Set<RouteAware>? previousSubscribers = _listeners[previousRoute];

      if (previousSubscribers != null) {
        for (final RouteAware routeAware in previousSubscribers) {
          routeAware.didPushNext();
        }
      }
    }
  }
}

/// An interface for objects that are aware of their current [Route].
///
/// This is used with [RouteObserver] to make a widget aware of changes to the
/// [Navigator]'s session history.
abstract class RouteAware {
  /// Called when the top route has been popped off, and the current route
  /// shows up.
  void didPopNext() { }

  /// Called when the current route has been pushed.
  void didPush() { }

  /// Called when the current route has been popped off.
  void didPop() { }

  /// Called when a new route has been pushed, and the current route is no
  /// longer visible.
  void didPushNext() { }
}

/// A general dialog route which allows for customization of the dialog popup.
///
/// It is used internally by [showGeneralDialog] or can be directly pushed
/// onto the [Navigator] stack to enable state restoration. See
/// [showGeneralDialog] for a state restoration app example.
///
/// This function takes a `pageBuilder`, which typically builds a dialog.
/// Content below the dialog is dimmed with a [ModalBarrier]. The widget
/// returned by the `builder` does not share a context with the location that
/// `showDialog` is originally called from. Use a [StatefulBuilder] or a
/// custom [StatefulWidget] if the dialog needs to update dynamically.
///
/// The `barrierDismissible` argument is used to indicate whether tapping on the
/// barrier will dismiss the dialog. It is `true` by default and cannot be `null`.
///
/// The `barrierColor` argument is used to specify the color of the modal
/// barrier that darkens everything below the dialog. If `null`, the default
/// color `Colors.black54` is used.
///
/// The `settings` argument define the settings for this route. See
/// [RouteSettings] for details.
///
/// {@template flutter.widgets.RawDialogRoute}
/// A [DisplayFeature] can split the screen into sub-screens. The closest one to
/// [anchorPoint] is used to render the content.
///
/// If no [anchorPoint] is provided, then [Directionality] is used:
///
///   * for [TextDirection.ltr], [anchorPoint] is `Offset.zero`, which will
///     cause the content to appear in the top-left sub-screen.
///   * for [TextDirection.rtl], [anchorPoint] is `Offset(double.maxFinite, 0)`,
///     which will cause the content to appear in the top-right sub-screen.
///
/// If no [anchorPoint] is provided, and there is no [Directionality] ancestor
/// widget in the tree, then the widget asserts during build in debug mode.
/// {@endtemplate}
///
/// See also:
///
///  * [DisplayFeatureSubScreen], which documents the specifics of how
///    [DisplayFeature]s can split the screen into sub-screens.
///  * [showGeneralDialog], which is a way to display a RawDialogRoute.
///  * [showDialog], which is a way to display a DialogRoute.
///  * [showCupertinoDialog], which displays an iOS-style dialog.
class RawDialogRoute<T> extends PopupRoute<T> {
  /// A general dialog route which allows for customization of the dialog popup.
  RawDialogRoute({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = true,
    Color? barrierColor = const Color(0x80000000),
    String? barrierLabel,
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    RouteSettings? settings,
    this.anchorPoint,
  }) : assert(barrierDismissible != null),
       _pageBuilder = pageBuilder,
       _barrierDismissible = barrierDismissible,
       _barrierLabel = barrierLabel,
       _barrierColor = barrierColor,
       _transitionDuration = transitionDuration,
       _transitionBuilder = transitionBuilder,
       super(settings: settings);

  final RoutePageBuilder _pageBuilder;

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  String? get barrierLabel => _barrierLabel;
  final String? _barrierLabel;

  @override
  Color? get barrierColor => _barrierColor;
  final Color? _barrierColor;

  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;

  final RouteTransitionsBuilder? _transitionBuilder;

  /// {@macro flutter.widgets.DisplayFeatureSubScreen.anchorPoint}
  final Offset? anchorPoint;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: DisplayFeatureSubScreen(
        anchorPoint: anchorPoint,
        child: _pageBuilder(context, animation, secondaryAnimation),
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (_transitionBuilder == null) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.linear,
        ),
        child: child,
      );
    } // Some default transition
    return _transitionBuilder!(context, animation, secondaryAnimation, child);
  }
}

/// Displays a dialog above the current contents of the app.
///
/// This function allows for customization of aspects of the dialog popup.
///
/// This function takes a `pageBuilder` which is used to build the primary
/// content of the route (typically a dialog widget). Content below the dialog
/// is dimmed with a [ModalBarrier]. The widget returned by the `pageBuilder`
/// does not share a context with the location that `showGeneralDialog` is
/// originally called from. Use a [StatefulBuilder] or a custom
/// [StatefulWidget] if the dialog needs to update dynamically. The
/// `pageBuilder` argument can not be null.
///
/// The `context` argument is used to look up the [Navigator] for the
/// dialog. It is only used when the method is called. Its corresponding widget
/// can be safely removed from the tree before the dialog is closed.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// dialog to the [Navigator] furthest from or nearest to the given `context`.
/// By default, `useRootNavigator` is `true` and the dialog route created by
/// this method is pushed to the root navigator.
///
/// If the application has multiple [Navigator] objects, it may be necessary to
/// call `Navigator.of(context, rootNavigator: true).pop(result)` to close the
/// dialog rather than just `Navigator.pop(context, result)`.
///
/// The `barrierDismissible` argument is used to determine whether this route
/// can be dismissed by tapping the modal barrier. This argument defaults
/// to false. If `barrierDismissible` is true, a non-null `barrierLabel` must be
/// provided.
///
/// The `barrierLabel` argument is the semantic label used for a dismissible
/// barrier. This argument defaults to `null`.
///
/// The `barrierColor` argument is the color used for the modal barrier. This
/// argument defaults to `Color(0x80000000)`.
///
/// The `transitionDuration` argument is used to determine how long it takes
/// for the route to arrive on or leave off the screen. This argument defaults
/// to 200 milliseconds.
///
/// The `transitionBuilder` argument is used to define how the route arrives on
/// and leaves off the screen. By default, the transition is a linear fade of
/// the page's contents.
///
/// The `routeSettings` will be used in the construction of the dialog's route.
/// See [RouteSettings] for more details.
///
/// {@macro flutter.widgets.RawDialogRoute}
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the dialog was closed.
///
/// ### State Restoration in Dialogs
///
/// Using this method will not enable state restoration for the dialog. In order
/// to enable state restoration for a dialog, use [Navigator.restorablePush]
/// or [Navigator.restorablePushNamed] with [RawDialogRoute].
///
/// For more information about state restoration, see [RestorationManager].
///
/// {@tool sample}
/// This sample demonstrates how to create a restorable dialog. This is
/// accomplished by enabling state restoration by specifying
/// [WidgetsApp.restorationScopeId] and using [Navigator.restorablePush] to
/// push [RawDialogRoute] when the button is tapped.
///
/// {@macro flutter.widgets.RestorationManager}
///
/// ** See code in examples/api/lib/widgets/routes/show_general_dialog.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [DisplayFeatureSubScreen], which documents the specifics of how
///    [DisplayFeature]s can split the screen into sub-screens.
///  * [showDialog], which displays a Material-style dialog.
///  * [showCupertinoDialog], which displays an iOS-style dialog.
Future<T?> showGeneralDialog<T extends Object?>({
  required BuildContext context,
  required RoutePageBuilder pageBuilder,
  bool barrierDismissible = false,
  String? barrierLabel,
  Color barrierColor = const Color(0x80000000),
  Duration transitionDuration = const Duration(milliseconds: 200),
  RouteTransitionsBuilder? transitionBuilder,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  assert(pageBuilder != null);
  assert(useRootNavigator != null);
  assert(!barrierDismissible || barrierLabel != null);
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(RawDialogRoute<T>(
    pageBuilder: pageBuilder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    transitionBuilder: transitionBuilder,
    settings: routeSettings,
    anchorPoint: anchorPoint,
  ));
}

/// Signature for the function that builds a route's primary contents.
/// Used in [PageRouteBuilder] and [showGeneralDialog].
///
/// See [ModalRoute.buildPage] for complete definition of the parameters.
typedef RoutePageBuilder = Widget Function(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation);

/// Signature for the function that builds a route's transitions.
/// Used in [PageRouteBuilder] and [showGeneralDialog].
///
/// See [ModalRoute.buildTransitions] for complete definition of the parameters.
typedef RouteTransitionsBuilder = Widget Function(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child);

/// The [FocusTrap] widget removes focus when a mouse primary pointer makes contact with another
/// region of the screen.
///
/// When a primary pointer makes contact with the screen, this widget determines if that pointer
/// contacted an existing focused widget. If not, this asks the [FocusScopeNode] to reset the
/// focus state. This allows [TextField]s and other focusable widgets to give up their focus
/// state, without creating a gesture detector that competes with others on screen.
///
/// In cases where focus is conceptually larger than the focused render object, a [FocusTrapArea]
/// can be used to expand the focus area to include all render objects below that. This is used by
/// the [TextField] widgets to prevent a loss of focus when interacting with decorations on the
/// text area.
///
/// See also:
///
///  * [FocusTrapArea], the widget that allows expanding the conceptual focus area.
class FocusTrap extends SingleChildRenderObjectWidget {

  /// Create a new [FocusTrap] widget scoped to the provided [focusScopeNode].
  const FocusTrap({
    required this.focusScopeNode,
    required Widget child,
    Key? key,
  }) : super(child: child, key: key);

  /// The [focusScopeNode] that this focus trap widget operates on.
  final FocusScopeNode focusScopeNode;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFocusTrap(focusScopeNode);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    if (renderObject is _RenderFocusTrap)
      renderObject.focusScopeNode = focusScopeNode;
  }
}

/// Declares a widget subtree which is part of the provided [focusNode]'s focus area
/// without attaching focus to that region.
///
/// This is used by text field widgets which decorate a smaller editable text area.
/// This area is conceptually part of the editable text, but not attached to the
/// focus context. The [FocusTrapArea] is used to inform the framework of this
/// relationship, so that primary pointer contact inside of this region but above
/// the editable text focus will not trigger loss of focus.
///
/// See also:
///
///  * [FocusTrap], the widget which removes focus based on primary pointer interactions.
class FocusTrapArea extends SingleChildRenderObjectWidget {

  /// Create a new [FocusTrapArea] that expands the area of the provided [focusNode].
  const FocusTrapArea({required this.focusNode, Key? key, Widget? child}) : super(key: key, child: child);

  /// The [FocusNode] that the focus trap area will expand to.
  final FocusNode focusNode;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFocusTrapArea(focusNode);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    if (renderObject is _RenderFocusTrapArea)
      renderObject.focusNode = focusNode;
  }
}

class _RenderFocusTrapArea extends RenderProxyBox {
  _RenderFocusTrapArea(this.focusNode);

  FocusNode focusNode;
}

class _RenderFocusTrap extends RenderProxyBoxWithHitTestBehavior {
  _RenderFocusTrap(this._focusScopeNode);

  Rect? currentFocusRect;
  Expando<BoxHitTestResult> cachedResults = Expando<BoxHitTestResult>();

  FocusScopeNode _focusScopeNode;
  FocusScopeNode get focusScopeNode => _focusScopeNode;
  set focusScopeNode(FocusScopeNode value) {
    if (focusScopeNode == value)
      return;
    _focusScopeNode = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, { required Offset position }) {
    bool hitTarget = false;
    if (size.contains(position)) {
      hitTarget = hitTestChildren(result, position: position) || hitTestSelf(position);
      if (hitTarget) {
        final BoxHitTestEntry entry = BoxHitTestEntry(this, position);
        cachedResults[entry] = result;
        result.add(entry);
      }
    }
    return hitTarget;
  }

  /// The focus dropping behavior is only present on desktop platforms
  /// and mobile browsers.
  bool get _shouldIgnoreEvents {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return !kIsWeb;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is! PointerDownEvent
      || event.buttons != kPrimaryButton
      || event.kind != PointerDeviceKind.mouse
      || _shouldIgnoreEvents
      || _focusScopeNode.focusedChild == null) {
      return;
    }
    final BoxHitTestResult? result = cachedResults[entry];
    final FocusNode? focusNode = _focusScopeNode.focusedChild;
    if (focusNode == null || result == null)
      return;

    final RenderObject? renderObject = focusNode.context?.findRenderObject();
    if (renderObject == null)
      return;

    bool hitCurrentFocus = false;
    for (final HitTestEntry entry in result.path) {
      final HitTestTarget target = entry.target;
      if (target == renderObject) {
        hitCurrentFocus = true;
        break;
      }
      if (target is _RenderFocusTrapArea && target.focusNode == focusNode) {
        hitCurrentFocus = true;
        break;
      }
    }
    if (!hitCurrentFocus)
      focusNode.unfocus();
  }
}
