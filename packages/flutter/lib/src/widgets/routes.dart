// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'navigator.dart';
import 'overlay.dart';

class StateRoute extends Route {
  StateRoute({ this.onPop });

  final VoidCallback onPop;

  List<OverlayEntry> get overlayEntries => const <OverlayEntry>[];

  void didPush(OverlayState overlay, OverlayEntry insertionPoint) { }
  void didPop(dynamic result) {
    if (onPop != null)
      onPop();
  }
}

class OverlayRoute extends Route {
  List<WidgetBuilder> get builders => const <WidgetBuilder>[];

  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = new List<OverlayEntry>();

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
