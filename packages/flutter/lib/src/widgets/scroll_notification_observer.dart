// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';
import 'scroll_position.dart';

/// A [ScrollNotification] listener for [ScrollNotificationObserver].
///
/// [ScrollNotificationObserver] is similar to
/// [NotificationListener]. It supports a listener list instead of
/// just a single listener and its listeners run unconditionally, they
/// do not require a gating boolean return value.
typedef ScrollNotificationCallback = void Function(ScrollNotification notification);

class _ScrollNotificationObserverScope extends InheritedWidget {
  const _ScrollNotificationObserverScope({
    Key? key,
    required Widget child,
    required ScrollNotificationObserverState scrollNotificationObserverState,
  }) : _scrollNotificationObserverState = scrollNotificationObserverState,
      super(key: key, child: child);

  final ScrollNotificationObserverState  _scrollNotificationObserverState;

  @override
  bool updateShouldNotify(_ScrollNotificationObserverScope old) => _scrollNotificationObserverState != old._scrollNotificationObserverState;
}

class _ListenerEntry extends LinkedListEntry<_ListenerEntry> {
  _ListenerEntry(this.listener);
  final ScrollNotificationCallback listener;
}

/// Notifies its listeners when a descendant scrolls.
///
/// To add a listener to a [ScrollNotificationObserver] ancestor:
/// ```dart
/// void listener(ScrollNotification notification) {
///   // Do something, maybe setState()
/// }
/// ScrollNotificationObserver.of(context).addListener(listener)
/// ```
///
/// To remove the listener from a [ScrollNotificationObserver] ancestor:
/// ```dart
/// ScrollNotificationObserver.of(context).removeListener(listener);
/// ```
///
/// Stateful widgets that share an ancestor [ScrollNotificationObserver] typically
/// add a listener in [State.didChangeDependencies] (removing the old one
/// if necessary) and remove the listener in their [State.dispose] method.
///
/// This widget is similar to [NotificationListener]. It supports
/// a listener list instead of just a single listener and its listeners
/// run unconditionally, they do not require a gating boolean return value.
class ScrollNotificationObserver extends StatefulWidget {
  /// Create a [ScrollNotificationObserver].
  ///
  /// The [child] parameter must not be null.
  const ScrollNotificationObserver({
    Key? key,
    required this.child,
  }) : assert(child != null), super(key: key);

  /// The subtree below this widget.
  final Widget child;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [ScrollNotificationObserver] widget, then null is returned.
  static ScrollNotificationObserverState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ScrollNotificationObserverScope>()?._scrollNotificationObserverState;
  }

  @override
  ScrollNotificationObserverState createState() => ScrollNotificationObserverState();
}

/// The listener list state for a [ScrollNotificationObserver] returned by
/// [ScrollNotificationObserver.of].
///
/// [ScrollNotificationObserver] is similar to
/// [NotificationListener]. It supports a listener list instead of
/// just a single listener and its listeners run unconditionally, they
/// do not require a gating boolean return value.
class ScrollNotificationObserverState extends State<ScrollNotificationObserver> {
  LinkedList<_ListenerEntry>? _listeners = LinkedList<_ListenerEntry>();

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_listeners == null) {
        throw FlutterError(
          'A $runtimeType was used after being disposed.\n'
          'Once you have called dispose() on a $runtimeType, it can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  /// Add a [ScrollNotificationCallback] that will be called each time
  /// a descendant scrolls.
  void addListener(ScrollNotificationCallback listener) {
    assert(_debugAssertNotDisposed());
    _listeners!.add(_ListenerEntry(listener));
  }

  /// Remove the specified [ScrollNotificationCallback].
  void removeListener(ScrollNotificationCallback listener) {
    assert(_debugAssertNotDisposed());
    for (final _ListenerEntry entry in _listeners!) {
      if (entry.listener == listener) {
        entry.unlink();
        return;
      }
    }
  }

  void _notifyListeners(ScrollNotification notification) {
    assert(_debugAssertNotDisposed());
    if (_listeners!.isEmpty)
      return;

    final List<_ListenerEntry> localListeners = List<_ListenerEntry>.of(_listeners!);
    for (final _ListenerEntry entry in localListeners) {
      try {
        if (entry.list != null)
          entry.listener(notification);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widget library',
          context: ErrorDescription('while dispatching notifications for $runtimeType'),
          informationCollector: () => <DiagnosticsNode>[
            DiagnosticsProperty<ScrollNotificationObserverState>(
              'The $runtimeType sending notification was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            ),
          ],
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        _notifyListeners(notification);
        return false;
      },
      child: _ScrollNotificationObserverScope(
        scrollNotificationObserverState: this,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    assert(_debugAssertNotDisposed());
    _listeners = null;
    super.dispose();
  }
}

/// A [ScrollMetricsNotification] listener for [ScrollMetricsNotificationObserver].
///
/// [ScrollMetricsNotificationObserver] is similar to
/// [NotificationListener]. It supports a listener list instead of
/// just a single listener and its listeners run unconditionally, they
/// do not require a gating boolean return value.
typedef ScrollMetricsNotificationCallback = void Function(ScrollMetricsNotification notification);

class _ScrollMetricsNotificationObserverScope extends InheritedWidget {
  const _ScrollMetricsNotificationObserverScope({
    Key? key,
    required Widget child,
    required ScrollMetricsNotificationObserverState scrollMetricsNotificationObserverState,
  }) : _scrollMetricsNotificationObserverState = scrollMetricsNotificationObserverState,
        super(key: key, child: child);

  final ScrollMetricsNotificationObserverState  _scrollMetricsNotificationObserverState;

  @override
  bool updateShouldNotify(_ScrollMetricsNotificationObserverScope old) {
    return _scrollMetricsNotificationObserverState != old._scrollMetricsNotificationObserverState;
  }
}

class _MetricsListenerEntry extends LinkedListEntry<_MetricsListenerEntry> {
  _MetricsListenerEntry(this.listener);
  final ScrollMetricsNotificationCallback listener;
}

/// Notifies its listeners when a descendant ScrollMetrics are
/// initialized or updated.
///
/// To add a listener to a [ScrollMetricsNotificationObserver] ancestor:
/// ```dart
/// void listener(ScrollMetricsNotification notification) {
///   // Do something, maybe setState()
/// }
/// ScrollMetricsNotificationObserver.of(context).addListener(listener)
/// ```
///
/// To remove the listener from a [ScrollMetricsNotificationObserver] ancestor:
/// ```dart
/// ScrollMetricsNotificationObserver.of(context).removeListener(listener);
/// ```
///
/// Stateful widgets that share an ancestor [ScrollMetricsNotificationObserver]
/// typically add a listener in [State.didChangeDependencies] (removing the old
/// one if necessary) and remove the listener in their [State.dispose] method.
///
/// This widget is similar to [NotificationListener]. It supports
/// a listener list instead of just a single listener and its listeners
/// run unconditionally, they do not require a gating boolean return value.
class ScrollMetricsNotificationObserver extends StatefulWidget {
  /// Create a [ScrollMetricsNotificationObserver].
  ///
  /// The [child] parameter must not be null.
  const ScrollMetricsNotificationObserver({
    Key? key,
    required this.child,
  }) : assert(child != null), super(key: key);

  /// The subtree below this widget.
  final Widget child;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [ScrollMetricsNotificationObserver] widget, then
  /// null is returned.
  static ScrollMetricsNotificationObserverState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ScrollMetricsNotificationObserverScope>()?._scrollMetricsNotificationObserverState;
  }

  @override
  ScrollMetricsNotificationObserverState createState() => ScrollMetricsNotificationObserverState();
}

/// The listener list state for a [ScrollMetricsNotificationObserver] returned
/// by [ScrollMetricsNotificationObserver.of].
///
/// [ScrollMetricsNotificationObserver] is similar to
/// [NotificationListener]. It supports a listener list instead of
/// just a single listener and its listeners run unconditionally, they
/// do not require a gating boolean return value.
class ScrollMetricsNotificationObserverState extends State<ScrollMetricsNotificationObserver> {
  LinkedList<_MetricsListenerEntry>? _listeners = LinkedList<_MetricsListenerEntry>();

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_listeners == null) {
        throw FlutterError(
          'A $runtimeType was used after being disposed.\n'
              'Once you have called dispose() on a $runtimeType, it can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  /// Add a [ScrollMetricsNotificationCallback] that will be called each time
  /// a descendant scrolls.
  void addListener(ScrollMetricsNotificationCallback listener) {
    assert(_debugAssertNotDisposed());
    _listeners!.add(_MetricsListenerEntry(listener));
  }

  /// Remove the specified [ScrollMetricsNotificationCallback].
  void removeListener(ScrollMetricsNotificationCallback listener) {
    assert(_debugAssertNotDisposed());
    for (final _MetricsListenerEntry entry in _listeners!) {
      if (entry.listener == listener) {
        entry.unlink();
        return;
      }
    }
  }

  void _notifyListeners(ScrollMetricsNotification notification) {
    assert(_debugAssertNotDisposed());
    if (_listeners!.isEmpty)
      return;

    final List<_MetricsListenerEntry> localListeners = List<_MetricsListenerEntry>.of(_listeners!);
    for (final _MetricsListenerEntry entry in localListeners) {
      try {
        if (entry.list != null)
          entry.listener(notification);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widget library',
          context: ErrorDescription('while dispatching notifications for $runtimeType'),
          informationCollector: () => <DiagnosticsNode>[
            DiagnosticsProperty<ScrollMetricsNotificationObserverState>(
              'The $runtimeType sending notification was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            ),
          ],
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (ScrollMetricsNotification notification) {
        _notifyListeners(notification);
        return false;
      },
      child: _ScrollMetricsNotificationObserverScope(
        scrollMetricsNotificationObserverState: this,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    assert(_debugAssertNotDisposed());
    _listeners = null;
    super.dispose();
  }
}
