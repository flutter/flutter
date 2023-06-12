// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper functions for working with errors.
///
/// The [MultiError] class combines multiple errors into one object,
/// and the [MultiError.wait] function works like [Future.wait] except
/// that it returns all the errors.
library isolate.errors;

import 'dart:async';

class MultiError extends Error {
  // Limits the number of lines included from each error's error message.
  // A best-effort attempt is made at keeping below this number of lines
  // in the output.
  // If there are too many errors, they will all get at least one line.
  static const int _maxLines = 55;

  // Minimum number of lines in the toString for each error.
  static const int _minLinesPerError = 1;

  /// The actual errors.
  final List errors;

  /// Create a `MultiError` based on a list of errors.
  ///
  /// The errors represent errors of a number of individual operations.
  ///
  /// The list may contain `null` values, if the index of the error in the
  /// list is useful.
  MultiError(this.errors);

  /// Waits for all [futures] to complete, like [Future.wait].
  ///
  /// Where `Future.wait` only reports one error, even if multiple
  /// futures complete with errors, this function will complete
  /// with a [MultiError] if more than one future completes with an error.
  ///
  /// The order of values is not preserved (if that is needed, use
  /// [wait]).
  static Future<List<Object?>> waitUnordered<T>(Iterable<Future<T>> futures,
      {void Function(T successResult)? cleanUp}) {
    var completer = Completer<List<Object?>>();
    var count = 0;
    var errors = 0;
    var values = 0;
    // Initialized to `new List(count)` when count is known.
    // Filled up with values on the left, errors on the right.
    // Order is not preserved.
    List<Object?> results = const <Never>[];

    void checkDone() {
      if (errors + values < count) return;
      if (errors == 0) {
        completer.complete(results);
        return;
      }
      var errorList = results.sublist(results.length - errors);
      completer.completeError(MultiError(errorList));
    }

    void handleValue(T v) {
      // If this fails because [results] is null, there is a future
      // which breaks the Future API by completing immediately when
      // calling Future.then, probably by misusing a synchronous completer.
      results[values++] = v;
      if (errors > 0 && cleanUp != null) {
        Future.sync(() => cleanUp(v));
      }
      checkDone();
    }

    void handleError(Object e, StackTrace s) {
      if (errors == 0 && cleanUp != null) {
        for (var i = 0; i < values; i++) {
          var value = results[i];
          if (value != null) Future.sync(() => cleanUp(value as T));
        }
      }
      results[results.length - ++errors] = e;
      checkDone();
    }

    for (var future in futures) {
      count++;
      future.then<void>(handleValue, onError: handleError);
    }
    if (count == 0) return Future.value(List.filled(0, null));
    results = List.filled(count, null);
    completer = Completer();
    return completer.future;
  }

  /// Waits for all [futures] to complete, like [Future.wait].
  ///
  /// Where `Future.wait` only reports one error, even if multiple
  /// futures complete with errors, this function will complete
  /// with a [MultiError] if more than one future completes with an error.
  ///
  /// The order of values is preserved, and if any error occurs, the
  /// [MultiError.errors] list will have errors in the corresponding slots,
  /// and `null` for non-errors.
  Future<List<Object?>> wait<T>(Iterable<Future<T>> futures,
      {void Function(T successResult)? cleanUp}) {
    var completer = Completer<List<Object?>>();
    var count = 0;
    var hasError = false;
    var completed = 0;
    // Initialized to `new List(count)` when count is known.
    // Filled with values until the first error, then cleared
    // and filled with errors.
    List<Object?> results = const <Never>[];

    void checkDone() {
      completed++;
      if (completed < count) return;
      if (!hasError) {
        completer.complete(results);
        return;
      }
      completer.completeError(MultiError(results));
    }

    for (var future in futures) {
      var i = count;
      count++;
      future.then<void>((v) {
        if (!hasError) {
          results[i] = v;
        } else if (cleanUp != null) {
          Future.sync(() => cleanUp(v));
        }
        checkDone();
      }, onError: (e, s) {
        if (!hasError) {
          if (cleanUp != null) {
            for (var i = 0; i < results.length; i++) {
              var result = results[i];
              if (result != null) Future.sync(() => cleanUp(result as T));
            }
          }
          results = List<Object?>.filled(count, null);
          hasError = true;
        }
        results[i] = e;
        checkDone();
      });
    }
    if (count == 0) return Future.value(List.filled(0, null));
    results = List<T?>.filled(count, null);
    completer = Completer();
    return completer.future;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write('Multiple Errors:\n');
    var linesPerError = _maxLines ~/ errors.length;
    if (linesPerError < _minLinesPerError) {
      linesPerError = _minLinesPerError;
    }

    for (var index = 0; index < errors.length; index++) {
      var error = errors[index];
      if (error == null) continue;
      var errorString = error.toString();
      var end = 0;
      for (var i = 0; i < linesPerError; i++) {
        end = errorString.indexOf('\n', end) + 1;
        if (end == 0) {
          end = errorString.length;
          break;
        }
      }
      buffer.write('#$index: ');
      buffer.write(errorString.substring(0, end));
      if (end < errorString.length) {
        buffer.write('...\n');
      }
    }
    return buffer.toString();
  }
}
