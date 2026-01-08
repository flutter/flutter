// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:meta/meta.dart';

import '../../engine.dart';

/// The type of a function that handles whether a media query matches or not.
typedef MediaQueryMatchHandler = void Function(bool matches);

/// Manages all the [_MediaQueryListeners]s attached to media query tests.
///
/// This is used by the [EnginePlatformDispatcher] to detect some properties
/// from the browser (light/dark mode or reduced motion)
class MediaQueryManager {
  /// Detects dark mode.
  static const DARK_MODE = '(prefers-color-scheme: dark)';

  /// Detects forced colors (high contrast).
  static const FORCED_COLORS = '(forced-colors: active)';

  /// Detects reduced motion.
  static const REDUCED_MOTION = '(prefers-reduced-motion: reduce)';

  final Map<String, _MediaQueryListeners> _listeners = {};

  /// Used in tests to inject mock objects that can dispatch arbitrary
  /// [DomMediaQueryListEvent]s.
  ///
  /// When this is not set, [domWindow.matchMedia] is used by default.
  ///
  /// This is used to ensure the connection of the [MediaQueryManager] with
  /// incoming events from the browser.
  @visibleForTesting
  MediaQueryBuilder? debugOverrideMediaQueryBuilder;

  /// Used in tests to trigger [event] on all the registered listeners of
  /// [mediaQueryString].
  ///
  /// This is used to test the connection between the [EnginePlatformDispatcher]
  /// and the [MediaQueryManager], without the browser having to dispatch real
  /// events.
  @visibleForTesting
  void debugTriggerListener(String mediaQueryString, {required DomMediaQueryListEvent event}) {
    final _MediaQueryListeners? listeners = _listeners[mediaQueryString];
    assert(listeners != null, 'Cannot find listeners for $mediaQueryString');
    listeners!.trigger(event);
  }

  // Creates a [DomMediaQueryList] object from a [mediaQueryString].
  //
  // This uses [debugOverrideMediaQueryBuilder] when set for tests.
  // In production, this uses [domWindow.matchMedia].
  DomEventTarget _createMediaQuery(String mediaQueryString) {
    if (debugOverrideMediaQueryBuilder != null) {
      return debugOverrideMediaQueryBuilder!(mediaQueryString);
    }
    return domWindow.matchMedia(mediaQueryString);
  }

  /// Adds a listener for [mediaQueryString], and triggers [onMatch] as needed.
  ///
  /// This function calls [onMatch] synchronously with the initial value of the
  /// match, and then, through an event listener, every time the value changes.
  void addListener(String mediaQueryString, {required MediaQueryMatchHandler onMatch}) {
    // Wrap `onMatch` in a [DomEventListener]
    final DomEventListener mediaQueryListener = (DomEvent event) {
      final mqEvent = event as DomMediaQueryListEvent;
      onMatch(mqEvent.matches ?? false);
    }.toJS;

    // Attach the listener
    final _MediaQueryListeners listeners = _listeners.putIfAbsent(mediaQueryString, () {
      // Create a proper media query object
      final DomEventTarget mediaQuery = _createMediaQuery(mediaQueryString);
      return _MediaQueryListeners(mediaQuery);
    })..addListener(mediaQueryListener);

    // Call onMatch with the immediate value of the media query
    onMatch(listeners.matches);
  }

  /// Detaches all registered listeners.
  void detachAll() {
    final Iterable<String> mediaQueryStrings = _listeners.keys.toList();
    mediaQueryStrings.forEach(_removeListeners);
  }

  /// Detaches all listeners for [mediaQueryString].
  void _removeListeners(String mediaQueryString) {
    final _MediaQueryListeners? listeners = _listeners.remove(mediaQueryString);
    listeners?.detachAll();
  }
}

/// Groups the listeners for a media query
class _MediaQueryListeners {
  _MediaQueryListeners(this._mediaQuery);

  final DomEventTarget _mediaQuery;
  final List<DomEventListener> _listeners = [];

  // Returns whether or not the listened [DomMediaQueryList] matches now.
  bool get matches {
    // On tests we inject something that is a raw DomEventTarget so we can
    // dispatch events from it directly, so we check for that case now.
    if (!_mediaQuery.isA<DomMediaQueryList>()) {
      return false;
    }
    return (_mediaQuery as DomMediaQueryList).matches;
  }

  void addListener(DomEventListener listener) {
    _mediaQuery.addEventListener('change', listener);
    _listeners.add(listener);
  }

  void detachAll() {
    _listeners.forEach(_removeListener);
    _listeners.clear();
  }

  void _removeListener(DomEventListener listener) {
    _mediaQuery.removeEventListener('change', listener);
  }

  /// Triggers [event] on all registered listeners.
  @visibleForTesting
  void trigger(DomMediaQueryListEvent event) {
    for (final JSFunction listener in _listeners) {
      // This is directly calling the registered JSFunction with [event].
      listener.callAsFunction(null, event);
    }
  }
}

/// A function to create a fake MediaQuery event from a String.
@visibleForTesting
typedef MediaQueryBuilder = DomEventTarget Function(String mediaQuery);
