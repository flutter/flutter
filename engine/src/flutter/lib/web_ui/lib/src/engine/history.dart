// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

const MethodCall _popRouteMethodCall = MethodCall('popRoute');

Map<String, bool> _originState = <String, bool>{'origin': true};
Map<String, bool> _flutterState = <String, bool>{'flutter': true};

/// The origin entry is the history entry that the Flutter app landed on. It's
/// created by the browser when the user navigates to the url of the app.
bool _isOriginEntry(dynamic state) {
  return state is Map && state['origin'] == true;
}

/// The flutter entry is a history entry that we maintain on top of the origin
/// entry. It allows us to catch popstate events when the user hits the back
/// button.
bool _isFlutterEntry(dynamic state) {
  return state is Map && state['flutter'] == true;
}

/// The [BrowserHistory] class is responsible for integrating Flutter Web apps
/// with the browser history so that the back button works as expected.
///
/// It does that by always keeping a single entry (conventionally called the
/// "flutter" entry) at the top of the browser history. That way, the browser's
/// back button always triggers a `popstate` event and never closes the app (we
/// close the app programmatically by calling [SystemNavigator.pop] when there
/// are no more app routes to be popped).
///
/// There should only be one global instance of this class.
class BrowserHistory {
  LocationStrategy _locationStrategy;
  ui.VoidCallback _unsubscribe;

  /// Changing the location strategy will unsubscribe from the old strategy's
  /// event listeners, and subscribe to the new one.
  ///
  /// If the given [strategy] is the same as the existing one, nothing will
  /// happen.
  ///
  /// If the given strategy is null, it will render this [BrowserHistory]
  /// instance inactive.
  set locationStrategy(LocationStrategy strategy) {
    if (strategy != _locationStrategy) {
      _tearoffStrategy(_locationStrategy);
      _locationStrategy = strategy;
      _setupStrategy(_locationStrategy);
    }
  }

  /// The path of the current location of the user's browser.
  String get currentPath => _locationStrategy?.path ?? '/';

  /// Update the url with the given [routeName].
  void setRouteName(String routeName) {
    if (_locationStrategy != null) {
      _setupFlutterEntry(_locationStrategy, replace: true, path: routeName);
    }
  }

  /// This method does the same thing as the browser back button.
  Future<void> back() {
    if (_locationStrategy != null) {
      return _locationStrategy.back();
    }
    return Future<void>.value();
  }

  /// This method exits the app and goes to whatever website was active before.
  Future<void> exit() {
    if (_locationStrategy != null) {
      _tearoffStrategy(_locationStrategy);
      // After tearing off the location strategy, we should be on the "origin"
      // entry. So we need to go back one more time to exit the app.
      final Future<void> backFuture = _locationStrategy.back();
      _locationStrategy = null;
      return backFuture;
    }
    return Future<void>.value();
  }

  String _userProvidedRouteName;
  void _popStateListener(covariant html.PopStateEvent event) {
    if (_isOriginEntry(event.state)) {
      // If we find ourselves in the origin entry, it means that the user
      // clicked the back button.

      // 1. Re-push the flutter entry to keep it always at the top of history.
      _setupFlutterEntry(_locationStrategy);

      // 2. Send a 'popRoute' platform message so the app can handle it accordingly.
      if (window._onPlatformMessage != null) {
        window.invokeOnPlatformMessage(
          'flutter/navigation',
          const JSONMethodCodec().encodeMethodCall(_popRouteMethodCall),
          (_) {},
        );
      }
    } else if (_isFlutterEntry(event.state)) {
      // We get into this scenario when the user changes the url manually. It
      // causes a new entry to be pushed on top of our "flutter" one. When this
      // happens it first goes to the "else" section below where we capture the
      // path into `_userProvidedRouteName` then trigger a history back which
      // brings us here.
      assert(_userProvidedRouteName != null);

      final String newRouteName = _userProvidedRouteName;
      _userProvidedRouteName = null;

      // Send a 'pushRoute' platform message so the app handles it accordingly.
      if (window._onPlatformMessage != null) {
        window.invokeOnPlatformMessage(
          'flutter/navigation',
          const JSONMethodCodec().encodeMethodCall(
            MethodCall('pushRoute', newRouteName),
          ),
          (_) {},
        );
      }
    } else {
      // The user has pushed a new entry on top of our flutter entry. This could
      // happen when the user modifies the hash part of the url directly, for
      // example.

      // 1. We first capture the user's desired path.
      _userProvidedRouteName = currentPath;

      // 2. Then we remove the new entry.
      // This will take us back to our "flutter" entry and it causes a new
      // popstate event that will be handled in the "else if" section above.
      _locationStrategy.back();
    }
  }

  /// This method should be called when the Origin Entry is active. It just
  /// replaces the state of the entry so that we can recognize it later using
  /// [_isOriginEntry] inside [_popStateListener].
  void _setupOriginEntry(LocationStrategy strategy) {
    assert(strategy != null);
    strategy.replaceState(_originState, 'origin', '');
  }

  /// This method is used manipulate the Flutter Entry which is always the
  /// active entry while the Flutter app is running.
  void _setupFlutterEntry(
    LocationStrategy strategy, {
    bool replace = false,
    String path,
  }) {
    assert(strategy != null);
    path ??= currentPath;
    if (replace) {
      strategy.replaceState(_flutterState, 'flutter', path);
    } else {
      strategy.pushState(_flutterState, 'flutter', path);
    }
  }

  void _setupStrategy(LocationStrategy strategy) {
    if (strategy == null) {
      return;
    }

    final String path = currentPath;
    if (_isFlutterEntry(html.window.history.state)) {
      // This could happen if the user, for example, refreshes the page. They
      // will land directly on the "flutter" entry, so there's no need to setup
      // the "origin" and "flutter" entries, we can safely assume they are
      // already setup.
    } else {
      _setupOriginEntry(strategy);
      _setupFlutterEntry(strategy, replace: false, path: path);
    }
    _unsubscribe = strategy.onPopState(_popStateListener);
  }

  void _tearoffStrategy(LocationStrategy strategy) {
    if (strategy == null) {
      return;
    }

    assert(_unsubscribe != null);
    _unsubscribe();
    _unsubscribe = null;

    // Remove the "flutter" entry and go back to the "origin" entry so that the
    // next location strategy can start from the right spot.
    strategy.back();
  }
}
