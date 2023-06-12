// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

/// A shared singleton instance of `dart:io`'s [stdin] stream.
///
/// _Unlike_ the normal [stdin] stream, [sharedStdIn] may switch subscribers
/// as long as the previous subscriber cancels before the new subscriber starts
/// listening.
///
/// [SharedStdIn.terminate] *must* be invoked in order to close the underlying
/// connection to [stdin], allowing your program to close automatically without
/// hanging.
final SharedStdIn sharedStdIn = SharedStdIn(stdin);

/// A singleton wrapper around `stdin` that allows new subscribers.
///
/// This class is visible in order to be used as a test harness for mock
/// implementations of `stdin`. In normal programs, [sharedStdIn] should be
/// used directly.
@visibleForTesting
class SharedStdIn extends Stream<List<int>> {
  StreamController<List<int>>? _current;
  StreamSubscription<List<int>>? _sub;

  SharedStdIn([Stream<List<int>>? stream]) {
    _sub = (stream ??= stdin).listen(_onInput);
  }

  /// Returns a future that completes with the next line.
  ///
  /// This is similar to the standard [Stdin.readLineSync], but asynchronous.
  Future<String> nextLine({Encoding encoding = systemEncoding}) =>
      lines(encoding: encoding).first;

  /// Returns the stream transformed as UTF8 strings separated by line breaks.
  ///
  /// This is similar to synchronous code using [Stdin.readLineSync]:
  /// ```dart
  /// while (true) {
  ///   var line = stdin.readLineSync();
  ///   // ...
  /// }
  /// ```
  ///
  /// ... but asynchronous.
  Stream<String> lines({Encoding encoding = systemEncoding}) =>
      transform(utf8.decoder).transform(const LineSplitter());

  void _onInput(List<int> event) => _getCurrent().add(event);

  StreamController<List<int>> _getCurrent() =>
      _current ??= StreamController<List<int>>(
          onCancel: () {
            _current = null;
          },
          sync: true);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (_sub == null) {
      throw StateError('Stdin has already been terminated.');
    }
    // ignore: close_sinks
    final controller = _getCurrent();
    if (controller.hasListener) {
      throw StateError(''
          'Subscriber already listening. The existing subscriber must cancel '
          'before another may be added.');
    }
    return controller.stream.listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }

  /// Terminates the connection to `stdin`, closing all subscription.
  Future<void> terminate() async {
    if (_sub == null) {
      throw StateError('Stdin has already been terminated.');
    }
    await _sub?.cancel();
    await _current?.close();
    _sub = null;
  }
}
