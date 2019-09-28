// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'async_guard.dart';
import 'context.dart';
import 'io.dart';

typedef SignalHandler = FutureOr<void> Function(ProcessSignal signal);

Signals get signals => Signals.instance;

/// A class that manages signal handlers
///
/// Signal handlers are run in the order that they were added.
abstract class Signals {
  factory Signals() => _DefaultSignals._();

  static Signals get instance => context.get<Signals>();

  /// Adds a signal handler to run on receipt of signal.
  ///
  /// The handler will run after all handlers that were previously added for the
  /// signal. The function returns an abstract token that should be provided to
  /// removeHandler to remove the handler.
  Object addHandler(ProcessSignal signal, SignalHandler handler);

  /// Removes a signal handler.
  ///
  /// Removes the signal handler for the signal identified by the abstract
  /// token parameter. Returns true if the handler was removed and false
  /// otherwise.
  Future<bool> removeHandler(ProcessSignal signal, Object token);

  /// If a [SignalHandler] throws an error, either synchronously or
  /// asynchronously, it will be added to this stream instead of propagated.
  Stream<Object> get errors;
}

class _DefaultSignals implements Signals {
  _DefaultSignals._();

  // A table mapping (signal, token) -> signal handler.
  final Map<ProcessSignal, Map<Object, SignalHandler>> _handlersTable =
      <ProcessSignal, Map<Object, SignalHandler>>{};

  // A table mapping (signal) -> signal handler list. The list is in the order
  // that the signal handlers should be run.
  final Map<ProcessSignal, List<SignalHandler>> _handlersList =
      <ProcessSignal, List<SignalHandler>>{};

  // A table mapping (signal) -> low-level signal event stream.
  final Map<ProcessSignal, StreamSubscription<ProcessSignal>> _streamSubscriptions =
    <ProcessSignal, StreamSubscription<ProcessSignal>>{};

  // The stream controller for errors coming from signal handlers.
  final StreamController<Object> _errorStreamController = StreamController<Object>.broadcast();

  @override
  Stream<Object> get errors => _errorStreamController.stream;

  @override
  Object addHandler(ProcessSignal signal, SignalHandler handler) {
    final Object token = Object();
    _handlersTable.putIfAbsent(signal, () => <Object, SignalHandler>{});
    _handlersTable[signal][token] = handler;

    _handlersList.putIfAbsent(signal, () => <SignalHandler>[]);
    _handlersList[signal].add(handler);

    // If we added the first one, then call signal.watch(), listen, and cache
    // the stream controller.
    if (_handlersList[signal].length == 1) {
      _streamSubscriptions[signal] = signal.watch().listen(_handleSignal);
    }
    return token;
  }

  @override
  Future<bool> removeHandler(ProcessSignal signal, Object token) async {
    // We don't know about this signal.
    if (!_handlersTable.containsKey(signal)) {
      return false;
    }
    // We don't know about this token.
    if (!_handlersTable[signal].containsKey(token)) {
      return false;
    }
    final SignalHandler handler = _handlersTable[signal][token];
    final bool removed = _handlersList[signal].remove(handler);
    if (!removed) {
      return false;
    }

    // If _handlersList[signal] is empty, then lookup the cached stream
    // controller and unsubscribe from the stream.
    if (_handlersList.isEmpty) {
      await _streamSubscriptions[signal].cancel();
    }
    return true;
  }

  Future<void> _handleSignal(ProcessSignal s) async {
    for (SignalHandler handler in _handlersList[s]) {
      try {
        await asyncGuard<void>(() => handler(s));
      } catch (e) {
        if (_errorStreamController.hasListener) {
          _errorStreamController.add(e);
        }
      }
    }
    // If this was a signal that should cause the process to go down, then
    // call exit();
    if (_shouldExitFor(s)) {
      exit(0);
    }
  }

  // The list of signals that should cause the process to exit.
  static const List<ProcessSignal> _exitingSignals = <ProcessSignal>[
    ProcessSignal.SIGTERM,
    ProcessSignal.SIGINT,
    ProcessSignal.SIGKILL,
  ];

  bool _shouldExitFor(ProcessSignal signal) => _exitingSignals.contains(signal);
}
