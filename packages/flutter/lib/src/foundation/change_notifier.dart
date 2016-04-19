// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'basic_types.dart';

/// Abstract class that can be extended or mixed in that provides
/// a change notification API using [VoidCallback] for notifications.
abstract class ChangeNotifier {
  List<VoidCallback> _listeners;

  /// Register a closure to be called when the object changes.
  void addListener(VoidCallback listener) {
    _listeners ??= <VoidCallback>[];
    _listeners.add(listener);
  }

  /// Remove a previously registered closure from the list of closures that are
  /// notified when the object changes.
  void removeListener(VoidCallback listener) {
    _listeners?.remove(listener);
  }

  /// Discards any resources used by the object. After this is called, the object
  /// is not in a usable state and should be discarded.
  ///
  /// This method should only be called by the object's owner.
  @mustCallSuper
  void dispose() {
    _listeners = null;
  }

  /// Call all the registered listeners.
  ///
  /// Call this method whenever the object changes, to notify any clients the
  /// object may have.
  ///
  /// Exceptions thrown by listeners will be caught and reported using
  /// [FlutterError.reportError].
  @protected
  void notifyListeners() {
    if (_listeners != null) {
      List<VoidCallback> listeners = new List<VoidCallback>.from(_listeners);
      for (VoidCallback listener in listeners) {
        try {
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
