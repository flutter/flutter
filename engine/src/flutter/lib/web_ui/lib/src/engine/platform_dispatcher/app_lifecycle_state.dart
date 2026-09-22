// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../../engine.dart';

/// Signature of functions added as a listener to [ui.AppLifecycleState] changes
typedef AppLifecycleStateListener = void Function(ui.AppLifecycleState state);

/// Determines the [ui.AppLifecycleState].
abstract class AppLifecycleState {
  static AppLifecycleState create(FlutterViewManager viewManager) {
    return _BrowserAppLifecycleState(viewManager);
  }

  ui.AppLifecycleState get appLifecycleState => _appLifecycleState;
  ui.AppLifecycleState _appLifecycleState = ui.AppLifecycleState.resumed;

  final List<AppLifecycleStateListener> _listeners = <AppLifecycleStateListener>[];

  void addListener(AppLifecycleStateListener listener) {
    if (_listeners.isEmpty) {
      activate();
    }
    _listeners.add(listener);
    listener(_appLifecycleState);
  }

  void removeListener(AppLifecycleStateListener listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      deactivate();
    }
  }

  @protected
  void activate();

  @protected
  void deactivate();

  @visibleForTesting
  void onAppLifecycleStateChange(ui.AppLifecycleState newState) {
    if (newState != _appLifecycleState) {
      _appLifecycleState = newState;
      for (final AppLifecycleStateListener listener in _listeners) {
        listener(newState);
      }
    }
  }
}

/// Manages [ui.AppLifecycleState] within a web context by monitoring the
/// visibility of each view's owning document.
///
/// The aggregate [ui.AppLifecycleState] is [resumed] if any view is visible,
/// [hidden] when all views are hidden, and [detached] when there are no views.
/// This allows a view moved to a Document Picture-in-Picture window to keep
/// the app resumed even when the original browser tab is hidden.
class _BrowserAppLifecycleState extends AppLifecycleState {
  _BrowserAppLifecycleState(this._viewManager);

  final FlutterViewManager _viewManager;
  final List<StreamSubscription<void>> _subscriptions = <StreamSubscription<void>>[];
  final Map<int, _ViewLifecycleTracker> _trackers = <int, _ViewLifecycleTracker>{};

  @override
  void activate() {
    // Attach to all views that already exist.
    _viewManager.views.forEach(_attachView);
    _subscriptions
      ..add(_viewManager.onViewCreated.listen(_onViewCreated))
      ..add(_viewManager.onViewDisposed.listen(_onViewDisposed))
      ..add(_viewManager.onViewAdopted.listen(_onViewAdopted));
  }

  @override
  void deactivate() {
    for (final _ViewLifecycleTracker tracker in _trackers.values) {
      tracker.dispose();
    }
    _trackers.clear();
    for (final StreamSubscription<void> subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _onViewCreated(int viewId) {
    final EngineFlutterView? view = _viewManager[viewId];
    if (view != null) {
      _attachView(view);
    }
  }

  void _onViewDisposed(int viewId) {
    _detachView(viewId);
  }

  void _onViewAdopted(int viewId) {
    // The view's window/document changed. Detach from the old ones and re-attach
    // to the new ones.
    _detachView(viewId);
    final EngineFlutterView? view = _viewManager[viewId];
    if (view != null) {
      _attachView(view);
    }
  }

  void _attachView(EngineFlutterView view) {
    assert(!_trackers.containsKey(view.viewId), 'View ${view.viewId} is already being tracked.');
    final tracker = _ViewLifecycleTracker(view: view, onStateChanged: _updateAggregateState);
    _trackers[view.viewId] = tracker;
    _updateAggregateState();
  }

  void _detachView(int viewId) {
    _trackers.remove(viewId)?.dispose();
    _updateAggregateState();
  }

  void _updateAggregateState() {
    if (_trackers.isEmpty) {
      onAppLifecycleStateChange(ui.AppLifecycleState.detached);
      return;
    }

    // If any view is visible (regardless of whether it has focus), the app is
    // considered resumed. This is what allows Document Picture-in-Picture to
    // keep the app running while the original tab is hidden.
    final bool anyVisible = _trackers.values.any(
      (_ViewLifecycleTracker tracker) => tracker.isVisible,
    );
    if (anyVisible) {
      onAppLifecycleStateChange(ui.AppLifecycleState.resumed);
    } else {
      onAppLifecycleStateChange(ui.AppLifecycleState.hidden);
    }
  }
}

/// Tracks the lifecycle-relevant state of a single [EngineFlutterView].
class _ViewLifecycleTracker {
  _ViewLifecycleTracker({required this.view, required this.onStateChanged}) {
    view.viewDomDocument.addEventListener('visibilitychange', _visibilityChangeListener);
  }

  final EngineFlutterView view;
  final ui.VoidCallback onStateChanged;

  /// Whether the view's document is currently visible.
  bool get isVisible => view.viewDomDocument.visibilityState == 'visible';

  late final DomEventListener _visibilityChangeListener = createDomEventListener((DomEvent event) {
    onStateChanged();
  });

  void dispose() {
    view.viewDomDocument.removeEventListener('visibilitychange', _visibilityChangeListener);
  }
}
