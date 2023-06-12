// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../stream_channel.dart';

/// A controller for exposing a new [StreamChannel].
///
/// This exposes two connected [StreamChannel]s, [local] and [foreign]. The
/// user's code should use [local] to emit and receive events. Then [foreign]
/// can be returned for others to use. For example, here's a simplified version
/// of the implementation of [new IsolateChannel]:
///
/// ```dart
/// StreamChannel isolateChannel(ReceivePort receivePort, SendPort sendPort) {
///   var controller = new StreamChannelController(allowForeignErrors: false);
///
///   // Pipe all events from the receive port into the local sink...
///   receivePort.pipe(controller.local.sink);
///
///   // ...and all events from the local stream into the send port.
///   controller.local.stream.listen(sendPort.send, onDone: receivePort.close);
///
///   // Then return the foreign controller for your users to use.
///   return controller.foreign;
/// }
/// ```
class StreamChannelController<T> {
  /// The local channel.
  ///
  /// This channel should be used directly by the creator of this
  /// [StreamChannelController] to send and receive events.
  StreamChannel<T> get local => _local;
  late final StreamChannel<T> _local;

  /// The foreign channel.
  ///
  /// This channel should be returned to external users so they can communicate
  /// with [local].
  StreamChannel<T> get foreign => _foreign;
  late final StreamChannel<T> _foreign;

  /// Creates a [StreamChannelController].
  ///
  /// If [sync] is true, events added to either channel's sink are synchronously
  /// dispatched to the other channel's stream. This should only be done if the
  /// source of those events is already asynchronous.
  ///
  /// If [allowForeignErrors] is `false`, errors are not allowed to be passed to
  /// the foreign channel's sink. If any are, the connection will close and the
  /// error will be forwarded to the foreign channel's [StreamSink.done] future.
  /// This guarantees that the local stream will never emit errors.
  StreamChannelController({bool allowForeignErrors = true, bool sync = false}) {
    var localToForeignController = StreamController<T>(sync: sync);
    var foreignToLocalController = StreamController<T>(sync: sync);
    _local = StreamChannel<T>.withGuarantees(
        foreignToLocalController.stream, localToForeignController.sink);
    _foreign = StreamChannel<T>.withGuarantees(
        localToForeignController.stream, foreignToLocalController.sink,
        allowSinkErrors: allowForeignErrors);
  }
}
