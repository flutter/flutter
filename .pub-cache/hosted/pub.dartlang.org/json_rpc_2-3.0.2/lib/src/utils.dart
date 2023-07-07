// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_channel/stream_channel.dart';

import '../error_code.dart' as error_code;
import 'exception.dart';

typedef ZeroArgumentFunction = Function();

/// A regular expression to match the exception prefix that some exceptions'
/// [Object.toString] values contain.
final _exceptionPrefix = RegExp(r'^([A-Z][a-zA-Z]*)?(Exception|Error): ');

/// Get a string description of an exception.
///
/// Many exceptions include the exception class name at the beginning of their
/// [toString], so we remove that if it exists.
String getErrorMessage(error) =>
    error.toString().replaceFirst(_exceptionPrefix, '');

/// Like `try`/`finally`, run [body] and ensure that [whenComplete] runs
/// afterwards, regardless of whether [body] succeeded.
///
/// This is synchronicity-agnostic relative to [body]. If [body] returns a
/// [Future], this wil run asynchronously; otherwise it will run synchronously.
void tryFinally(Function() body, Function() whenComplete) {
  dynamic result;
  try {
    result = body();
  } catch (_) {
    whenComplete();
    rethrow;
  }

  if (result is! Future) {
    whenComplete();
  } else {
    result.whenComplete(whenComplete);
  }
}

/// A transformer that silently drops [FormatException]s.
final ignoreFormatExceptions = StreamTransformer<Object?, Object?>.fromHandlers(
    handleError: (error, stackTrace, sink) {
  if (error is FormatException) return;
  sink.addError(error, stackTrace);
});

/// A transformer that sends error responses on [FormatException]s.
final StreamChannelTransformer<Object?, Object?> respondToFormatExceptions =
    _RespondToFormatExceptionsTransformer();

class _RespondToFormatExceptionsTransformer
    implements StreamChannelTransformer<Object?, Object?> {
  @override
  StreamChannel<Object?> bind(StreamChannel<Object?> channel) {
    return channel.changeStream((stream) {
      return stream.handleError((dynamic error) {
        final formatException = error as FormatException;
        var exception = RpcException(
            error_code.PARSE_ERROR, 'Invalid JSON: ${formatException.message}');
        channel.sink.add(exception.serialize(formatException.source));
      }, test: (error) => error is FormatException);
    });
  }
}
