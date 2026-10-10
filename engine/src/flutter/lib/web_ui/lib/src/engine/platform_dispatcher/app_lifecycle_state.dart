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
/// The aggregate [ui.AppLifecycleState] is [resumed] if any view is resumed,
/// [inactive] if any view is inactive, [hidden] when all views are hidden,
/// and [detached] when there are no views.
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
      ..add(_viewManager.onViewMoved.listen(_onViewMoved));
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

  void _onViewMoved(int viewId) {
    // The view's window/document changed. Detach from the old ones and re-attach
    // to the new ones.
    // Update aggregated state after move is done, otherwise apps get a detached
    // event and might start cleanups
    _detachView(viewId, updateAggregateState: false);
    final EngineFlutterView? view = _viewManager[viewId];
    if (view != null) {
      _attachView(view, updateAggregateState: false);
    }
    _updateAggregateState();
  }

  void _attachView(EngineFlutterView view, {bool updateAggregateState = true}) {
    assert(!_trackers.containsKey(view.viewId), 'View ${view.viewId} is already being tracked.');
    final tracker = _ViewLifecycleTracker(
      domDocument: view.viewDomDocument,
      domWindow: view.viewDomWindow,
      onStateChanged: _updateAggregateState,
    );
    _trackers[view.viewId] = tracker;
    if (updateAggregateState) {
      _updateAggregateState();
    }
  }

  void _detachView(int viewId, {bool updateAggregateState = true}) {
    _trackers.remove(viewId)?.dispose();
    if (updateAggregateState) {
      _updateAggregateState();
    }
  }

  void _updateAggregateState() {
    if (_trackers.isEmpty) {
      onAppLifecycleStateChange(ui.AppLifecycleState.detached);
      return;
    }

    // Set the global state to the highest single value
    final bool anyResumed = _trackers.values.any(
      (_ViewLifecycleTracker tracker) => tracker.state == ui.AppLifecycleState.resumed,
    );
    final bool anyInactive = _trackers.values.any(
      (_ViewLifecycleTracker tracker) => tracker.state == ui.AppLifecycleState.inactive,
    );
    if (anyResumed) {
      onAppLifecycleStateChange(ui.AppLifecycleState.resumed);
    } else if (anyInactive) {
      onAppLifecycleStateChange(ui.AppLifecycleState.inactive);
    } else {
      onAppLifecycleStateChange(ui.AppLifecycleState.hidden);
    }
  }
}

/// Tracks the lifecycle-relevant state of a single [EngineFlutterView].
class _ViewLifecycleTracker {
  _ViewLifecycleTracker({
    required this.domDocument,
    required this.domWindow,
    required this.onStateChanged,
  }) : state = domDocument.visibilityState == 'hidden'
           ? ui.AppLifecycleState.hidden
           : ui.AppLifecycleState.resumed {
    domDocument.addEventListener('visibilitychange', _visibilityChangeListener);
    domWindow.addEventListener('focus', _focusListener);
    domWindow.addEventListener('blur', _blurListener);
  }

  DomHTMLDocument domDocument;
  DomWindow domWindow;
  final ui.VoidCallback onStateChanged;
  ui.AppLifecycleState state;

  late final DomEventListener _visibilityChangeListener = createDomEventListener((DomEvent event) {
    if (domDocument.visibilityState == 'visible') {
      state = ui.AppLifecycleState.resumed;
    } else if (domDocument.visibilityState == 'hidden') {
      state = ui.AppLifecycleState.hidden;
    }
    onStateChanged();
  });
  late final DomEventListener _focusListener = createDomEventListener((DomEvent event) {
    state = ui.AppLifecycleState.resumed;
    onStateChanged();
  });
  late final DomEventListener _blurListener = createDomEventListener((DomEvent event) {
    state = ui.AppLifecycleState.inactive;
    onStateChanged();
  });

  void dispose() {
    domDocument.removeEventListener('visibilitychange', _visibilityChangeListener);
    domWindow.removeEventListener('focus', _focusListener);
    domWindow.removeEventListener('blur', _blurListener);
  }
}
