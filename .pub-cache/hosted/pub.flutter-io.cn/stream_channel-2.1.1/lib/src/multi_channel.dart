// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

import '../stream_channel.dart';

/// A class that multiplexes multiple virtual channels across a single
/// underlying transport layer.
///
/// This should be connected to another [MultiChannel] on the other end of the
/// underlying channel. It starts with a single default virtual channel,
/// accessible via [stream] and [sink]. Additional virtual channels can be
/// created with [virtualChannel].
///
/// When a virtual channel is created by one endpoint, the other must connect to
/// it before messages may be sent through it. The first endpoint passes its
/// [VirtualChannel.id] to the second, which then creates a channel from that id
/// also using [virtualChannel]. For example:
///
/// ```dart
/// // First endpoint
/// var virtual = multiChannel.virtualChannel();
/// multiChannel.sink.add({
///   "channel": virtual.id
/// });
///
/// // Second endpoint
/// multiChannel.stream.listen((message) {
///   var virtual = multiChannel.virtualChannel(message["channel"]);
///   // ...
/// });
/// ```
///
/// Sending errors across a [MultiChannel] is not supported. Any errors from the
/// underlying stream will be reported only via the default
/// [MultiChannel.stream].
///
/// Each virtual channel may be closed individually. When all of them are
/// closed, the underlying [StreamSink] is closed automatically.
abstract class MultiChannel<T> implements StreamChannel<T> {
  /// The default input stream.
  ///
  /// This connects to the remote [sink].
  @override
  Stream<T> get stream;

  /// The default output stream.
  ///
  /// This connects to the remote [stream]. If this is closed, the remote
  /// [stream] will close, but other virtual channels will remain open and new
  /// virtual channels may be opened.
  @override
  StreamSink<T> get sink;

  /// Creates a new [MultiChannel] that sends and receives messages over
  /// [inner].
  ///
  /// The inner channel must take JSON-like objects.
  factory MultiChannel(StreamChannel<dynamic> inner) => _MultiChannel<T>(inner);

  /// Creates a new virtual channel.
  ///
  /// If [id] is not passed, this creates a virtual channel from scratch. Before
  /// it's used, its [VirtualChannel.id] must be sent to the remote endpoint
  /// where [virtualChannel] should be called with that id.
  ///
  /// If [id] is passed, this creates a virtual channel corresponding to the
  /// channel with that id on the remote channel.
  ///
  /// Throws an [ArgumentError] if a virtual channel already exists for [id].
  /// Throws a [StateError] if the underlying channel is closed.
  VirtualChannel<T> virtualChannel([int? id]);
}

/// The implementation of [MultiChannel].
///
/// This is private so that [VirtualChannel] can inherit from [MultiChannel]
/// without having to implement all the private members.
class _MultiChannel<T> extends StreamChannelMixin<T>
    implements MultiChannel<T> {
  /// The inner channel over which all communication is conducted.
  ///
  /// This will be `null` if the underlying communication channel is closed.
  StreamChannel<dynamic>? _inner;

  /// The subscription to [_inner].stream.
  StreamSubscription<dynamic>? _innerStreamSubscription;

  @override
  Stream<T> get stream => _mainController.foreign.stream;
  @override
  StreamSink<T> get sink => _mainController.foreign.sink;

  /// The controller for this channel.
  final _mainController = StreamChannelController<T>(sync: true);

  /// A map from input IDs to [StreamChannelController]s that should be used to
  /// communicate over those channels.
  final _controllers = <int, StreamChannelController<T>>{};

  /// Input IDs of controllers in [_controllers] that we've received messages
  /// for but that have not yet had a local [virtualChannel] created.
  final _pendingIds = <int>{};

  /// Input IDs of virtual channels that used to exist but have since been
  /// closed.
  final _closedIds = <int>{};

  /// The next id to use for a local virtual channel.
  ///
  /// Ids are used to identify virtual channels. Each message is tagged with an
  /// id; the receiving [MultiChannel] uses this id to look up which
  /// [VirtualChannel] the message should be dispatched to.
  ///
  /// The id scheme for virtual channels is somewhat complicated. This is
  /// necessary to ensure that there are no conflicts even when both endpoints
  /// have virtual channels with the same id; since both endpoints can send and
  /// receive messages across each virtual channel, a naïve scheme would make it
  /// impossible to tell whether a message was from a channel that originated in
  /// the remote endpoint or a reply on a channel that originated in the local
  /// endpoint.
  ///
  /// The trick is that each endpoint only uses odd ids for its own channels.
  /// When sending a message over a channel that was created by the remote
  /// endpoint, the channel's id plus one is used. This way each [MultiChannel]
  /// knows that if an incoming message has an odd id, it's coming from a
  /// channel that was originally created remotely, but if it has an even id,
  /// it's coming from a channel that was originally created locally.
  var _nextId = 1;

  _MultiChannel(StreamChannel<dynamic> inner) : _inner = inner {
    // The default connection is a special case which has id 0 on both ends.
    // This allows it to begin connected without having to send over an id.
    _controllers[0] = _mainController;
    _mainController.local.stream.listen(
        (message) => _inner!.sink.add(<Object?>[0, message]),
        onDone: () => _closeChannel(0, 0));

    _innerStreamSubscription = _inner!.stream.cast<List>().listen((message) {
      var id = (message[0] as num).toInt();

      // If the channel was closed before an incoming message was processed,
      // ignore that message.
      if (_closedIds.contains(id)) return;

      var controller = _controllers.putIfAbsent(id, () {
        // If we receive a message for a controller that doesn't have a local
        // counterpart yet, create a controller for it to buffer incoming
        // messages for when a local connection is created.
        _pendingIds.add(id);
        return StreamChannelController(sync: true);
      });

      if (message.length > 1) {
        controller.local.sink.add(message[1] as T);
      } else {
        // A message without data indicates that the channel has been closed. We
        // can just close the sink here without doing any more cleanup, because
        // the sink closing will cause the stream to emit a done event which
        // will trigger more cleanup.
        controller.local.sink.close();
      }
    },
        onDone: _closeInnerChannel,
        onError: _mainController.local.sink.addError);
  }

  @override
  VirtualChannel<T> virtualChannel([int? id]) {
    int inputId;
    int outputId;
    if (id != null) {
      // Since the user is passing in an id, we're connected to a remote
      // VirtualChannel. This means messages they send over this channel will
      // have the original odd id, but our replies will have an even id.
      inputId = id;
      outputId = id + 1;
    } else {
      // Since we're generating an id, we originated this VirtualChannel. This
      // means messages we send over this channel will have the original odd id,
      // but the remote channel's replies will have an even id.
      inputId = _nextId + 1;
      outputId = _nextId;
      _nextId += 2;
    }

    // If the inner channel has already closed, create new virtual channels in a
    // closed state.
    if (_inner == null) {
      return VirtualChannel._(this, inputId, Stream.empty(), NullStreamSink());
    }

    late StreamChannelController<T> controller;
    if (_pendingIds.remove(inputId)) {
      // If we've already received messages for this channel, use the controller
      // where those messages are buffered.
      controller = _controllers[inputId]!;
    } else if (_controllers.containsKey(inputId) ||
        _closedIds.contains(inputId)) {
      throw ArgumentError('A virtual channel with id $id already exists.');
    } else {
      controller = StreamChannelController(sync: true);
      _controllers[inputId] = controller;
    }

    controller.local.stream.listen(
        (message) => _inner!.sink.add(<Object?>[outputId, message]),
        onDone: () => _closeChannel(inputId, outputId));
    return VirtualChannel._(
        this, outputId, controller.foreign.stream, controller.foreign.sink);
  }

  /// Closes the virtual channel for which incoming messages have [inputId] and
  /// outgoing messages have [outputId].
  void _closeChannel(int inputId, int outputId) {
    _closedIds.add(inputId);
    var controller = _controllers.remove(inputId)!;
    controller.local.sink.close();

    if (_inner == null) return;

    // A message without data indicates that the virtual channel has been
    // closed.
    _inner!.sink.add([outputId]);
    if (_controllers.isEmpty) _closeInnerChannel();
  }

  /// Closes the underlying communication channel.
  void _closeInnerChannel() {
    _inner!.sink.close();
    _innerStreamSubscription!.cancel();
    _inner = null;

    // Convert this to a list because the close is dispatched synchronously, and
    // that could conceivably remove a controller from [_controllers].
    for (var controller in List.from(_controllers.values)) {
      controller.local.sink.close();
    }
    _controllers.clear();
  }
}

/// A virtual channel created by [MultiChannel].
///
/// This implements [MultiChannel] for convenience.
/// [VirtualChannel.virtualChannel] is semantically identical to the parent's
/// [MultiChannel.virtualChannel].
class VirtualChannel<T> extends StreamChannelMixin<T>
    implements MultiChannel<T> {
  /// The [MultiChannel] that created this.
  final MultiChannel<T> _parent;

  /// The identifier for this channel.
  ///
  /// This can be sent across the [MultiChannel] to provide the remote endpoint
  /// a means to connect to this channel. Nothing about this is guaranteed
  /// except that it will be JSON-serializable.
  final int id;

  @override
  final Stream<T> stream;
  @override
  final StreamSink<T> sink;

  VirtualChannel._(this._parent, this.id, this.stream, this.sink);

  @override
  VirtualChannel<T> virtualChannel([id]) => _parent.virtualChannel(id);
}
