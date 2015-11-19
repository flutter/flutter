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

class StateRoute extends Route {
  StateRoute({ this.onPop });

  final VoidCallback onPop;

  List<OverlayEntry> get overlayEntries => const <OverlayEntry>[];

  void didPop(dynamic result) {
    if (onPop != null)
      onPop();
  }

  bool willPushNext(Route nextRoute) => true;
  bool didPopNext(Route nextRoute) => true;
}

abstract class OverlayRoute extends Route {
  List<WidgetBuilder> get builders => const <WidgetBuilder>[];

  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

  void didPush(OverlayState overlay, OverlayEntry insertionPoint) {
    for (WidgetBuilder builder in builders) {
      _overlayEntries.add(new OverlayEntry(builder: builder));
      overlay?.insert(_overlayEntries.last, above: insertionPoint);
      insertionPoint = _overlayEntries.last;
    }
  }

  void didPop(dynamic result) {
    for (OverlayEntry entry in _overlayEntries)
      entry.remove();
    _overlayEntries.clear();
  }
}

// TODO(abarth): Should we add a type for the result?
abstract class TransitionRoute extends OverlayRoute {
  TransitionRoute({ this.completer });

  final Completer completer;

  Duration get transitionDuration;
  bool get opaque;

  PerformanceView get performance => _performance?.view;
  Performance _performance;

  Performance createPerformance() {
    Duration duration = transitionDuration;
    assert(duration != null && duration >= Duration.ZERO);
    return new Performance(duration: duration, debugLabel: debugLabel);
  }

  dynamic _result;

  void _handleStatusChanged(PerformanceStatus status) {
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
        super.didPop(_result); // clear the overlays
        completer?.complete(_result);
        break;
    }
  }

  void didPush(OverlayState overlay, OverlayEntry insertionPoint) {
    _performance = createPerformance()
      ..addStatusListener(_handleStatusChanged)
      ..forward();
    super.didPush(overlay, insertionPoint);
  }

  void didPop(dynamic result) {
    _result = result;
    _performance.reverse();
  }

  String get debugLabel => '$runtimeType';
  String toString() => '$runtimeType(performance: $_performance)';
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
          child: route.buildTransition(context, performance, contents)
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

abstract class ModalRoute extends TransitionRoute {
  ModalRoute({
    Completer completer,
    this.settings: const NamedRouteSettings()
  }) : super(completer: completer);

  // The API for general users of this class

  final NamedRouteSettings settings;

  static ModalRoute of(BuildContext context) {
    _ModalScopeStatus widget = context.inheritFromWidgetOfType(_ModalScopeStatus);
    return widget?.route;
  }

  bool get isCurrent => _isCurrent;
  bool _isCurrent = false;


  // The API for subclasses to override - used by _ModalScope

  ModalPosition get position => null;
  Widget buildPage(BuildContext context);
  Widget buildTransition(BuildContext context, PerformanceView performance, Widget child) {
    return child;
  }

  // The API for subclasses to override - used by this class

  Color get barrierColor => kTransparent;


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

  void didPush(OverlayState overlay, OverlayEntry insertionPoint) {
    assert(!_isCurrent);
    _isCurrent = true;
    super.didPush(overlay, insertionPoint);
  }

  void didPop(dynamic result) {
    assert(_isCurrent);
    _isCurrent = false;
    super.didPop(result);
  }

  bool willPushNext(Route nextRoute) {
    if (nextRoute is ModalRoute) {
      assert(_isCurrent);
      _isCurrent = false;
    }
    return false;
  }

  bool didPopNext(Route nextRoute) {
    if (nextRoute is ModalRoute) {
      assert(!_isCurrent);
      _isCurrent = true;
    }
    return false;
  }

  final GlobalKey<StatusTransitionState> _scopeKey = new GlobalKey<StatusTransitionState>();
  final GlobalKey _subtreeKey = new GlobalKey();
  final PageStorageBucket _storageBucket = new PageStorageBucket();

  Widget _buildModalBarrier(BuildContext context) {
    return new AnimatedModalBarrier(
      color: new AnimatedColorValue(kTransparent, end: barrierColor, curve: Curves.ease),
      performance: performance,
      dismissable: false
    );
  }

  Widget _buildModalScope(BuildContext context) {
    return new _ModalScope(
      key: _scopeKey,
      subtreeKey: _subtreeKey,
      storageBucket: _storageBucket,
      performance: performance,
      current: isCurrent,
      route: this
    );
  }

  List<WidgetBuilder> get builders => <WidgetBuilder>[
    _buildModalBarrier,
    _buildModalScope
  ];

}
