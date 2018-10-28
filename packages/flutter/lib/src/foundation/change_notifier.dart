// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'basic_types.dart';
import 'diagnostics.dart';
import 'observer_list.dart';

/// An object that maintains a list of listeners.
///
/// The listeners are typically used to notify clients that the object has been
/// updated.
///
/// There are two variants of this interface:
///
///  * [ValueListenable], an interface that augments the [Listenable] interface
///    with the concept of a _current value_.
///
///  * [Animation], an interface that augments the [ValueListenable] interface
///    to add the concept of direction (forward or reverse).
///
/// Many classes in the Flutter API use or implement these interfaces. The
/// following subclasses are especially relevant:
///
///  * [ChangeNotifier], which can be subclassed or mixed in to create objects
///    that implement the [Listenable] interface.
///
///  * [ValueNotifier], which implements the [ValueListenable] interface with
///    a mutable value that triggers the notifications when modified.
///
/// The terms "notify clients", "send notifications", "trigger notifications",
/// and "fire notifications" are used interchangeably.
///
/// See also:
///
///  * [AnimatedBuilder], a widget that uses a builder callback to rebuild
///    whenever a given [Listenable] triggers its notifications. This widget is
///    commonly used with [Animation] subclasses, wherein its name. It is a
///    subclass of [AnimatedWidget], which can be used to create widgets that
///    are driven from a [Listenable].
///
///  * [ValueListenableBuilder], a widget that uses a builder callback to
///    rebuild whenever a [ValueListenable] object triggers its notifications,
///    providing the builder with the value of the object.
///
///  * [InheritedNotifier], an abstract superclass for widgets that use a
///    [Listenable]'s notifications to trigger rebuilds in descendant widgets
///    that declare a dependency on them, using the [InheritedWidget] mechanism.
///
///  * [new Listenable.merge], which creates a [Listenable] that triggers
///    notifications whenever any of a list of other [Listenable]s trigger their
///    notifications.
abstract class Listenable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Listenable();

  /// Return a [Listenable] that triggers when any of the given [Listenable]s
  /// themselves trigger.
  ///
  /// The list must not be changed after this method has been called. Doing so
  /// will lead to memory leaks or exceptions.
  ///
  /// The list may contain nulls; they are ignored.
  factory Listenable.merge(List<Listenable> listenables) = _MergingListenable;

  /// Register a closure to be called when the object notifies its listeners.
  void addListener(VoidCallback listener);

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies.
  void removeListener(VoidCallback listener);
}

/// An interface for subclasses of [Listenable] that expose a [value].
///
/// This interface is implemented by [ValueNotifier<T>] and [Animation<T>], and
/// allows other APIs to accept either of those implementations interchangeably.
abstract class ValueListenable<T> extends Listenable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ValueListenable();

  /// The current value of the object. When the value changes, the callbacks
  /// registered with [addListener] will be invoked.
  T get value;
}

/// A class that can be extended or mixed in that provides a change notification
/// API using [VoidCallback] for notifications.
///
/// [ChangeNotifier] is optimized for small numbers (one or two) of listeners.
/// It is O(N) for adding and removing listeners and O(N²) for dispatching
/// notifications (where N is the number of listeners).
///
/// See also:
///
///  * [ValueNotifier], which is a [ChangeNotifier] that wraps a single value.
class ChangeNotifier extends Listenable {
  ObserverList<VoidCallback> _listeners = ObserverList<VoidCallback>();

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_listeners == null) {
        throw FlutterError(
          'A $runtimeType was used after being disposed.\n'
          'Once you have called dispose() on a $runtimeType, it can no longer be used.'
        );
      }
      return true;
    }());
    return true;
  }

  /// Whether any listeners are currently registered.
  ///
  /// Clients should not depend on this value for their behavior, because having
  /// one listener's logic change when another listener happens to start or stop
  /// listening will lead to extremely hard-to-track bugs. Subclasses might use
  /// this information to determine whether to do any work when there are no
  /// listeners, however; for example, resuming a [Stream] when a listener is
  /// added and pausing it when a listener is removed.
  ///
  /// Typically this is used by overriding [addListener], checking if
  /// [hasListeners] is false before calling `super.addListener()`, and if so,
  /// starting whatever work is needed to determine when to call
  /// [notifyListeners]; and similarly, by overriding [removeListener], checking
  /// if [hasListeners] is false after calling `super.removeListener()`, and if
  /// so, stopping that same work.
  @protected
  bool get hasListeners {
    assert(_debugAssertNotDisposed());
    return _listeners.isNotEmpty;
  }

  /// Register a closure to be called when the object changes.
  ///
  /// This method must not be called after [dispose] has been called.
  @override
  void addListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    _listeners.add(listener);
  }

  /// Remove a previously registered closure from the list of closures that are
  /// notified when the object changes.
  ///
  /// If the given listener is not registered, the call is ignored.
  ///
  /// This method must not be called after [dispose] has been called.
  ///
  /// If a listener had been added twice, and is removed once during an
  /// iteration (i.e. in response to a notification), it will still be called
  /// again. If, on the other hand, it is removed as many times as it was
  /// registered, then it will no longer be called. This odd behavior is the
  /// result of the [ChangeNotifier] not being able to determine which listener
  /// is being removed, since they are identical, and therefore conservatively
  /// still calling all the listeners when it knows that any are still
  /// registered.
  ///
  /// This surprising behavior can be unexpectedly observed when registering a
  /// listener on two separate objects which are both forwarding all
  /// registrations to a common upstream object.
  @override
  void removeListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    _listeners.remove(listener);
  }

  /// Discards any resources used by the object. After this is called, the
  /// object is not in a usable state and should be discarded (calls to
  /// [addListener] and [removeListener] will throw after the object is
  /// disposed).
  ///
  /// This method should only be called by the object's owner.
  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _listeners = null;
  }

  /// Call all the registered listeners.
  ///
  /// Call this method whenever the object changes, to notify any clients the
  /// object may have. Listeners that are added during this iteration will not
  /// be visited. Listeners that are removed during this iteration will not be
  /// visited after they are removed.
  ///
  /// Exceptions thrown by listeners will be caught and reported using
  /// [FlutterError.reportError].
  ///
  /// This method must not be called after [dispose] has been called.
  ///
  /// Surprising behavior can result when reentrantly removing a listener (i.e.
  /// in response to a notification) that has been registered multiple times.
  /// See the discussion at [removeListener].
  @protected
  void notifyListeners() {
    assert(_debugAssertNotDisposed());
    if (_listeners != null) {
      final List<VoidCallback> localListeners = List<VoidCallback>.from(_listeners);
      for (VoidCallback listener in localListeners) {
        try {
          if (_listeners.contains(listener))
            listener();
        } catch (exception, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'foundation library',
            context: 'while dispatching notifications for $runtimeType',
            informationCollector: (StringBuffer information) {
              information.writeln('The $runtimeType sending notification was:');
              information.write('  $this');
            }
          ));
        }
      }
    }
  }
}

class _MergingListenable extends ChangeNotifier {
  _MergingListenable(this._children) {
    for (Listenable child in _children)
      child?.addListener(notifyListeners);
  }

  final List<Listenable> _children;

  @override
  void dispose() {
    for (Listenable child in _children)
      child?.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  String toString() {
    return 'Listenable.merge([${_children.join(", ")}])';
  }
}

/// A [ChangeNotifier] that holds a single value.
///
/// When [value] is replaced, this class notifies its listeners.
class ValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  /// Creates a [ChangeNotifier] that wraps this value.
  ValueNotifier(this._value);

  /// The current value stored in this notifier.
  ///
  /// When the value is replaced, this class notifies its listeners.
  @override
  T get value => _value;
  T _value;
  set value(T newValue) {
    if (_value == newValue)
      return;
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

/// Converts a [ValueListenable] to a [Stream].
///
/// The current value of the [ValueListenable] is emitted to the [Stream] each
/// time the [ValueListenable] triggers a notification. (It is possible that the
/// same value will be emitted multiple times in a row, since nothing in the
/// [ValueListenable] contract prevents notifications from being sent without
/// the value changing; the precise semantics are defined by the object.)
///
/// This stream can be paused and resumed. This has no effect on the underlying
/// [ValueListenable], but does stop the stream from listening to it and
/// reporting updates while it is paused.
///
/// This can be used with [Animation] subclasses (since they implement
/// [ValueListenable] as well).
///
/// ## Using [ValueListenable] or [Stream] objects with widgets
///
/// Using a [ValueListenableBuilder] widget (or an [AnimationBuilder]) with a
/// [ValueListenable] directly is more efficient than using a [StreamBuilder],
/// because streams do not report their values synchronously, unlike
/// [ValueListenable]s.
Stream<T> valueListenableToStreamAdapter<T>(ValueListenable<T> listenable) {
  StreamController<T> controller;
  void listener() {
    controller.add(listenable.value);
  }
  void start() {
    listenable.addListener(listener);
  }
  void end() {
    listenable.removeListener(listener);
  }
  controller = StreamController<T>(
    onListen: start,
    onPause: end,
    onResume: start,
    onCancel: end,
  );
  return controller.stream;
}

/// Converts a [Listenable] to a [Future].
///
/// The `predicate` callback is invoked each time the given [Listenable] sends
/// notifications, until the callback returns true, at which point the future
/// completes.
///
/// If the predicate throws an exception, the future is completed as an error
/// using that exception.
///
/// The `predicate` callback must not cause the listener to send notifications
/// reentrantly; if it does, the future will complete with an error.
Future<void> listenableToFutureAdapter(Listenable listenable, ValueGetter<bool> predicate) {
  assert(predicate != null);
  final Completer<void> completer = Completer<void>();
  bool handling = false;
  void listener() {
    if (handling && !completer.isCompleted) {
      listenable.removeListener(listener);
      completer.completeError(
        StateError(
          'listenableToFutureAdapter does not support reentrant notifications triggered by the predicate\n'
          'The predicate passed to listenableToFutureAdapter caused the listenable ($listenable) to send '
          'a notification while listenableToFutureAdapter was already processing a notification.'
        )
      );
    }
    try {
      handling = true;
      if (predicate() && !completer.isCompleted) {
        completer.complete();
        listenable.removeListener(listener);
      }
    } catch (error, stack) {
      if (!completer.isCompleted) {
        completer.completeError(error, stack);
        listenable.removeListener(listener);
      } else {
        rethrow;
      }
    } finally {
      handling = false;
    }
  }
  listenable.addListener(listener);
  return completer.future;
}

typedef ValuePredicateCallback<T> = bool Function(T value);

/// Converts a [ValueListenable<T>] to a [Future<T>].
///
/// The `predicate` callback is invoked each time the given [ValueListenable]
/// sends notifications, until the callback returns true, at which point the
/// future completes with the current value of the [ValueListenable].
///
/// If the predicate throws an exception, the future is completed as an error
/// using that exception.
///
/// The `predicate` callback must not cause the listener to send notifications
/// reentrantly; if it does, the future will complete with an error.
Future<T> valueListenableToFutureAdapter<T>(ValueListenable<T> listenable, ValuePredicateCallback<T> predicate) {
  assert(predicate != null);
  final Completer<T> completer = Completer<T>();
  bool handling = false;
  void listener() {
    if (handling && !completer.isCompleted) {
      listenable.removeListener(listener);
      completer.completeError(
        StateError(
          'valueListenableToFutureAdapter does not support reentrant notifications triggered by the predicate\n'
          'The predicate passed to valueListenableToFutureAdapter caused the listenable ($listenable) to send '
          'a notification while valueListenableToFutureAdapter was already processing a notification.'
        )
      );
    }
    try {
      handling = true;
      final T value = listenable.value;
      if (predicate(value) && !completer.isCompleted) {
        completer.complete(value);
        listenable.removeListener(listener);
      }
    } catch (error, stack) {
      if (!completer.isCompleted) {
        completer.completeError(error, stack);
        listenable.removeListener(listener);
      } else {
        rethrow;
      }
    } finally {
      handling = false;
    }
  }
  listenable.addListener(listener);
  return completer.future;
}
