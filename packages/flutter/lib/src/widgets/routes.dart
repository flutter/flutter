// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'focus.dart';
import 'framework.dart';
import 'modal_barrier.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'page_storage.dart';
import 'status_transitions.dart';

const _kTransparent = const Color(0x00000000);

abstract class OverlayRoute<T> extends Route<T> {
  List<WidgetBuilder> get builders;

  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

  void install(OverlayEntry insertionPoint) {
    assert(_overlayEntries.isEmpty);
    for (WidgetBuilder builder in builders)
      _overlayEntries.add(new OverlayEntry(builder: builder));
    navigator.overlay?.insertAll(_overlayEntries, above: insertionPoint);
  }

  // Subclasses shouldn't call this if they want to delay the finished() call.
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

  PerformanceView get performance => _performance?.view;
  Performance _performance;

  Performance createPerformance() {
    Duration duration = transitionDuration;
    assert(duration != null && duration >= Duration.ZERO);
    return new Performance(duration: duration, debugLabel: debugLabel);
  }

  T _result;

  void handleStatusChanged(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.completed:
        if (overlayEntries.isNotEmpty)
          overlayEntries.first.opaque = opaque;
        break;
      case PerformanceStatus.forward:
      case PerformanceStatus.reverse:
        if (overlayEntries.isNotEmpty)
          overlayEntries.first.opaque = false;
        break;
      case PerformanceStatus.dismissed:
        assert(!overlayEntries.first.opaque);
        finished(); // clear the overlays
        assert(overlayEntries.isEmpty);
        break;
    }
  }

  void install(OverlayEntry insertionPoint) {
    _performance = createPerformance();
    super.install(insertionPoint);
  }

  void didPush() {
    _performance.addStatusListener(handleStatusChanged);
    _performance.forward();
    super.didPush();
  }

  void didReplace(Route oldRoute) {
    if (oldRoute is TransitionRoute)
      _performance.progress = oldRoute._performance.progress;
    _performance.addStatusListener(handleStatusChanged);
    super.didReplace(oldRoute);
  }

  bool didPop(T result) {
    _result = result;
    _performance.reverse();
    _popCompleter?.complete(_result);
    return true;
  }

  void finished() {
    super.finished();
    _transitionCompleter?.complete(_result);
  }

  void dispose() {
    _performance.stop();
    super.dispose();
  }


  final ProxyPerformance forwardPerformance = new ProxyPerformance();

  void didPushNext(Route nextRoute) {
    if (nextRoute is TransitionRoute) {
      PerformanceView current = forwardPerformance.masterPerformance;
      if (current != null) {
        if (current is TrainHoppingPerformance) {
          TrainHoppingPerformance newPerformance;
          newPerformance = new TrainHoppingPerformance(
            current.currentTrain,
            nextRoute.performance,
            onSwitchedTrain: () {
              assert(forwardPerformance.masterPerformance == newPerformance);
              assert(newPerformance.currentTrain == nextRoute.performance);
              forwardPerformance.masterPerformance = newPerformance.currentTrain;
              newPerformance.dispose();
            }
          );
          forwardPerformance.masterPerformance = newPerformance;
          current.dispose();
        } else {
          forwardPerformance.masterPerformance = new TrainHoppingPerformance(current, nextRoute.performance);
        }
      } else {
        forwardPerformance.masterPerformance = nextRoute.performance;
      }
    }
    super.didPushNext(nextRoute);
  }

  Widget wrapTransition(BuildContext context, Widget child) {
    return buildForwardTransition(
      context,
      forwardPerformance,
      buildTransition(
        context,
        performance,
        child
      )
    );
  }

  Widget buildTransition(BuildContext context, PerformanceView performance, Widget child) => child;
  Widget buildForwardTransition(BuildContext context, PerformanceView performance, Widget child) => child;

  String get debugLabel => '$runtimeType';
  String toString() => '$runtimeType(performance: $_performance)';
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
}

class _ModalScopeStatus extends InheritedWidget {
  _ModalScopeStatus({
    Key key,
    this.current,
    this.route,
    Widget child
  }) : super(key: key, child: child) {
    assert(current != null);
    assert(route != null);
    assert(child != null);
  }

  final bool current;
  final Route route;

  bool updateShouldNotify(_ModalScopeStatus old) {
    return current != old.current ||
           route != old.route;
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${current ? "active" : "inactive"}');
  }
}

class _ModalScope extends StatusTransitionComponent {
  _ModalScope({
    Key key,
    this.subtreeKey,
    this.storageBucket,
    PerformanceView performance,
    this.current,
    this.route
  }) : super(key: key, performance: performance);

  final GlobalKey subtreeKey;
  final PageStorageBucket storageBucket;
  final bool current;
  final ModalRoute route;

  Widget build(BuildContext context) {
    Widget contents = new PageStorage(
      key: subtreeKey,
      bucket: storageBucket,
      child: new _ModalScopeStatus(
        current: current,
        route: route,
        child: route.buildPage(context)
      )
    );
    if (route.offstage) {
      contents = new OffStage(child: contents);
    } else {
      contents = new Focus(
        key: new GlobalObjectKey(route),
        child: new IgnorePointer(
          ignoring: performance.status == PerformanceStatus.reverse,
          child: route.wrapTransition(context, contents)
        )
      );
    }
    contents = new RepaintBoundary(child: contents);
    ModalPosition position = route.position;
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
    this.settings: const NamedRouteSettings()
  }) : super.explicit(completer, null);

  // The API for general users of this class

  final NamedRouteSettings settings;

  static ModalRoute of(BuildContext context) {
    _ModalScopeStatus widget = context.inheritFromWidgetOfType(_ModalScopeStatus);
    return widget?.route;
  }


  // The API for subclasses to override - used by _ModalScope

  ModalPosition get position => null;
  Widget buildPage(BuildContext context);
  Widget buildTransition(BuildContext context, PerformanceView performance, Widget child) {
    return child;
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

  final GlobalKey<StatusTransitionState> _scopeKey = new GlobalKey<StatusTransitionState>();
  final GlobalKey _subtreeKey = new GlobalKey();
  final PageStorageBucket _storageBucket = new PageStorageBucket();

  Widget _buildModalBarrier(BuildContext context) {
    if (barrierColor != null) {
      assert(barrierColor != _kTransparent);
      return new AnimatedModalBarrier(
        color: new AnimatedColorValue(_kTransparent, end: barrierColor, curve: Curves.ease),
        performance: performance,
        dismissable: barrierDismissable
      );
    } else {
      return new ModalBarrier(dismissable: barrierDismissable);
    }
  }

  Widget _buildModalScope(BuildContext context) {
    return new _ModalScope(
      key: _scopeKey,
      subtreeKey: _subtreeKey,
      storageBucket: _storageBucket,
      performance: performance,
      current: isCurrent,
      route: this
      // calls buildTransition()/buildForwardTransition() and buildPage(), defined above
    );
  }

  List<WidgetBuilder> get builders => <WidgetBuilder>[
    _buildModalBarrier,
    _buildModalScope
  ];

  String toString() => '$runtimeType($settings, performance: $_performance)';
}

/// A modal route that overlays a widget over the current route.
abstract class PopupRoute<T> extends ModalRoute<T> {
  PopupRoute({ Completer<T> completer }) : super(completer: completer);
  bool get opaque => false;
  void didPushNext(Route nextRoute) {
    assert(nextRoute is! PageRoute);
    super.didPushNext(nextRoute);
  }
}

/// A modal route that replaces the entire screen.
abstract class PageRoute<T> extends ModalRoute<T> {
  PageRoute({
    Completer<T> completer,
    NamedRouteSettings settings: const NamedRouteSettings()
  }) : super(completer: completer, settings: settings);
  bool get opaque => true;
}
