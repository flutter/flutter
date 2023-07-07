// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';
// ignore: deprecated_member_use
import 'package:test_api/backend.dart' show RemoteException;
import 'package:test_api/src/utils.dart'; // ignore: implementation_imports

/// A sink transformer that wraps data and error events so that errors can be
/// decoded after being JSON-serialized.
final _transformer = StreamSinkTransformer<dynamic, dynamic>.fromHandlers(
    handleData: (data, sink) {
  ensureJsonEncodable(data);
  sink.add({'type': 'data', 'data': data});
}, handleError: (error, stackTrace, sink) {
  sink.add(
      {'type': 'error', 'error': RemoteException.serialize(error, stackTrace)});
});

/// Runs the body of a hybrid isolate and communicates its messages, errors, and
/// prints to the main isolate.
///
/// The [getMain] function returns the `hybridMain()` method. It's wrapped in a
/// closure so that, if the method undefined, we can catch the error and notify
/// the caller of it.
///
/// The [data] argument contains two values: a [SendPort] that communicates with
/// the main isolate, and a message to pass to `hybridMain()`.
void listen(Function Function() getMain, List data) {
  var channel = IsolateChannel.connectSend(data.first as SendPort);
  var message = data.last;

  Chain.capture(() {
    runZoned(() {
      dynamic /*Function*/ main;
      try {
        main = getMain();
      } on NoSuchMethodError catch (_) {
        _sendError(channel, 'No top-level hybridMain() function defined.');
        return;
      } catch (error, stackTrace) {
        _sendError(channel, error, stackTrace);
        return;
      }

      if (main is! Function) {
        _sendError(channel, 'Top-level hybridMain is not a function.');
        return;
      } else if (main is! Function(StreamChannel) &&
          main is! Function(StreamChannel, Never)) {
        if (main is Function(StreamChannel<Never>) ||
            main is Function(StreamChannel<Never>, Never)) {
          _sendError(
              channel,
              'The first parameter to the top-level hybridMain() must be a '
              'StreamChannel<dynamic> or StreamChannel<Object?>. More specific '
              'types such as StreamChannel<Object> are not supported.');
        } else {
          _sendError(channel,
              'Top-level hybridMain() function must take one or two arguments.');
        }
        return;
      }

      // Wrap [channel] before passing it to user code so that we can wrap
      // errors and distinguish user data events from control events sent by the
      // listener.
      var transformedChannel = channel.transformSink(_transformer);
      if (main is Function(StreamChannel)) {
        main(transformedChannel);
      } else {
        main(transformedChannel, message);
      }
    }, zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
      channel.sink.add({'type': 'print', 'line': line});
    }));
  }, onError: (error, stackTrace) async {
    _sendError(channel, error, stackTrace);
    await channel.sink.close();
    Isolate.current.kill();
  });
}

/// Sends a message over [channel] indicating an error from user code.
void _sendError(StreamChannel channel, error, [StackTrace? stackTrace]) {
  channel.sink.add({
    'type': 'error',
    'error': RemoteException.serialize(error, stackTrace ?? Chain.current())
  });
}
