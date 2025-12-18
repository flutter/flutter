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
  final Map<String, _MediaQueryListeners> _listeners = {};

  /// Used in tests to inject mock objects that can dispatch arbitrary
  /// [DomMediaQueryListEvent]s.
  ///
  /// When this is not set, [domWindow.matchMedia] is used by default.
  @visibleForTesting
  MediaQueryBuilder? debugOverrideMediaQueryBuilder;

  // Returns the current value of an object that may be a [DomMediaQueryList]
  // (but maybe not, if it was mocked)
  bool _getMatchesValue(DomEventTarget maybeMediaQueryList) {
    if (!maybeMediaQueryList.isA<DomMediaQueryList>()) {
      return false;
    }
    return (maybeMediaQueryList as DomMediaQueryList).matches;
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
    // Create a proper media query object
    final DomEventTarget mediaQuery = _createMediaQuery(mediaQueryString);

    // Wrap `onMatch` in a [DomEventListener]
    final DomEventListener mediaQueryListener = (DomEvent event) {
      final mqEvent = event as DomMediaQueryListEvent;
      onMatch(mqEvent.matches ?? false);
    }.toJS;

    // Attach the listener
    _listeners
        .putIfAbsent(mediaQueryString, () => _MediaQueryListeners(mediaQuery))
        .addListener(mediaQueryListener);

    // Call onMatch with the initial value
    onMatch(_getMatchesValue(mediaQuery));
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
  _MediaQueryListeners(DomEventTarget mediaQuery) : _mediaQuery = mediaQuery;

  final DomEventTarget _mediaQuery;
  final List<DomEventListener> _listeners = [];

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
}

/// A function to create a fake MediaQuery event from a String.
@visibleForTesting
typedef MediaQueryBuilder = DomEventTarget Function(String mediaQuery);
