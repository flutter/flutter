// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'basic_types.dart';

/// An object that maintains a list of listeners.
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
  /// The list may contain `null`s; they are ignored.
  factory Listenable.merge(List<Listenable> listenables) = _MergingListenable;

  /// Register a closure to be called when the object notifies its listeners.
  void addListener(VoidCallback listener);

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies.
  void removeListener(VoidCallback listener);
}

/// A class that can be extended or mixed in that provides a change notification
/// API using [VoidCallback] for notifications.
///
/// [ChangeNotifier] is optimised for small numbers (one or two) of listeners.
/// It is O(N) for adding and removing listeners and O(N²) for dispatching
/// notifications (where N is the number of listeners).
class ChangeNotifier extends Listenable {
  List<VoidCallback> _listeners;

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_listeners == const <VoidCallback>[]) {
        throw new FlutterError(
          'A $runtimeType was used after being disposed.\n'
          'Once you have called dispose() on a $runtimeType, it can no longer be used.'
        );
      }
      return true;
    });
    return true;
  }

  /// Register a closure to be called when the object changes.
  ///
  /// This method must not be called after [dispose] has been called.
  @override
  void addListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed);
    _listeners ??= <VoidCallback>[];
    _listeners.add(listener);
  }

  /// Remove a previously registered closure from the list of closures that are
  /// notified when the object changes.
  ///
  /// If the given listener is not registered, the call is ignored.
  ///
  /// This method must not be called after [dispose] has been called.
  @override
  void removeListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed);
    _listeners?.remove(listener);
  }

  /// Discards any resources used by the object. After this is called, the
  /// object is not in a usable state and should be discarded (calls to
  /// [addListener] and [removeListener] will throw after the object is
  /// disposed).
  ///
  /// This method should only be called by the object's owner.
  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed);
    _listeners = const <VoidCallback>[];
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
  @protected
  void notifyListeners() {
    assert(_debugAssertNotDisposed);
    if (_listeners != null) {
      List<VoidCallback> localListeners = new List<VoidCallback>.from(_listeners);
      for (VoidCallback listener in localListeners) {
        try {
          if (_listeners.contains(listener))
            listener();
        } catch (exception, stack) {
          FlutterError.reportError(new FlutterErrorDetails(
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
}
