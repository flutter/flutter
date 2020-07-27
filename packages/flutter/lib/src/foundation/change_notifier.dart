// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'basic_types.dart';
import 'diagnostics.dart';

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
///    commonly used with [Animation] subclasses, hence its name, but is by no
///    means limited to animations, as it can be used with any [Listenable]. It
///    is a subclass of [AnimatedWidget], which can be used to create widgets
///    that are driven from a [Listenable].
///  * [ValueListenableBuilder], a widget that uses a builder callback to
///    rebuild whenever a [ValueListenable] object triggers its notifications,
///    providing the builder with the value of the object.
///  * [InheritedNotifier], an abstract superclass for widgets that use a
///    [Listenable]'s notifications to trigger rebuilds in descendant widgets
///    that declare a dependency on them, using the [InheritedWidget] mechanism.
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
  factory Listenable.merge(List<Listenable?> listenables) = _MergingListenable;

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
///
/// See also:
///
///  * [ValueListenableBuilder], a widget that uses a builder callback to
///    rebuild whenever a [ValueListenable] object triggers its notifications,
///    providing the builder with the value of the object.
abstract class ValueListenable<T> extends Listenable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ValueListenable();

  /// The current value of the object. When the value changes, the callbacks
  /// registered with [addListener] will be invoked.
  T get value;
}

class _ListenerEntry extends LinkedListEntry<_ListenerEntry> {
  _ListenerEntry(this.listener);
  final VoidCallback listener;
}

/// A class that can be extended or mixed in that provides a change notification
/// API using [VoidCallback] for notifications.
///
/// It is O(1) for adding listeners and O(N) removing listeners and dispatching
/// notifications (where N is the number of listeners).
///
/// See also:
///
///  * [ValueNotifier], which is a [ChangeNotifier] that wraps a single value.
class ChangeNotifier implements Listenable {
  LinkedList<_ListenerEntry>? _listeners = LinkedList<_ListenerEntry>();
  /// Keeps track of the first newly added listened inside notifyListeners
  /// to stop the dispatching and not immediately execute new listeners
  _ListenerEntry? _firstNewlyAddedEntry;

  /// During [notifyListeners], corresponds to the listeners that were already notified,
  /// from the last listener notified to the first one.
  ///
  /// This list is updated only when a listener removes itself, for performance reason.
  List<_ListenerEntry>? _visitedEntriesInReverseOrder;

  _ListenerEntry? _currentlyVisitedEntry;

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
    return _listeners!.isNotEmpty;
  }

  /// Register a closure to be called when the object changes.
  ///
  /// This method must not be called after [dispose] has been called.
  @override
  void addListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    final _ListenerEntry entry = _ListenerEntry(listener);
    if (_currentlyVisitedEntry != null) {
      _firstNewlyAddedEntry ??= entry;
    }
    _listeners!.add(entry);
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
    for (final _ListenerEntry entry in _listeners!) {
      if (entry.listener == listener) {
        if (entry == _firstNewlyAddedEntry) {
          // During notifyListeners, a listener was added and removed immediatly
          _firstNewlyAddedEntry = _firstNewlyAddedEntry!.next;
        }
        if (entry == _currentlyVisitedEntry) {
          // A listener is removing itself, so we create a back-up of the already
          // notified listeners, so that notifyListeners can resume the iteration.
          // We are storing all already visited listeners instead of only the latest
          // as notifyListeners can be called recursively while adding/removing listeners.
          _visitedEntriesInReverseOrder = _allEntriesBefore(entry).toList(growable: false);
        }
        entry.unlink();
        return;
      }
    }
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
  /// object may have changed. Listeners that are added during this iteration
  /// will not be visited. Listeners that are removed during this iteration will
  /// not be visited after they are removed.
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
  @visibleForTesting
  void notifyListeners() {
    assert(_debugAssertNotDisposed());
    // TODO notifyListeners inside notifyListeners

    if (_listeners != null && _listeners!.isNotEmpty) {
      _ListenerEntry? entry = _listeners!.first;
      while (entry != null && entry != _firstNewlyAddedEntry) {
        _currentlyVisitedEntry = entry;
        try {
          entry.listener();
        } catch (exception, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'foundation library',
            context: ErrorDescription('while dispatching notifications for $runtimeType'),
            informationCollector: () sync* {
              yield DiagnosticsProperty<ChangeNotifier>(
                'The $runtimeType sending notification was',
                this,
                style: DiagnosticsTreeStyle.errorProperty,
              );
            },
          ));
        }

        if (entry.list != null) {
          entry = entry.next;
          continue;
        }

        // At this stage, the listener removed itself and as a consequence
        // entry.next is no-longer available. We need to determine where to
        // restart the iteration.

        _ListenerEntry? lastValidEntry;
        for (final _ListenerEntry entry in _visitedEntriesInReverseOrder!) {
          if (entry.list != null) {
            lastValidEntry = entry;
          }
        }

        if (lastValidEntry != null) {
          entry = lastValidEntry.next;
        } else if (_listeners!.isNotEmpty) {
          // entry and all of the previous listeners were removed, so we can
          // safely restart the iteration from the start
          entry = _listeners!.first;
        }
      }
    }

    _firstNewlyAddedEntry = null;
    _currentlyVisitedEntry = null;
    _visitedEntriesInReverseOrder = null;
  }
}

Iterable<T> _allEntriesBefore<T extends LinkedListEntry<T>>(T target) sync* {
  for (T? entry = target.previous; entry != null; entry = entry.previous) {
    yield entry;
  }
}

class _MergingListenable extends Listenable {
  _MergingListenable(this._children);

  final List<Listenable?> _children;

  @override
  void addListener(VoidCallback listener) {
    for (final Listenable? child in _children) {
      child?.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final Listenable? child in _children) {
      child?.removeListener(listener);
    }
  }

  @override
  String toString() {
    return 'Listenable.merge([${_children.join(", ")}])';
  }
}

/// A [ChangeNotifier] that holds a single value.
///
/// When [value] is replaced with something that is not equal to the old
/// value as evaluated by the equality operator ==, this class notifies its
/// listeners.
class ValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  /// Creates a [ChangeNotifier] that wraps this value.
  ValueNotifier(this._value);

  /// The current value stored in this notifier.
  ///
  /// When the value is replaced with something that is not equal to the old
  /// value as evaluated by the equality operator ==, this class notifies its
  /// listeners.
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
