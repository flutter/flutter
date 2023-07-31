// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';

/// A collection of streams whose events are unified and sent through a central
/// stream.
///
/// Both errors and data events are forwarded through [stream]. The streams in
/// the group won't be listened to until [stream] has a listener. **Note that
/// this means that events emitted by broadcast streams will be dropped until
/// [stream] has a listener.**
///
/// If the `StreamGroup` is constructed using [StreamGroup.new], [stream] will
/// be single-subscription. In this case, if [stream] is paused or canceled, all
/// streams in the group will likewise be paused or canceled, respectively.
///
/// If the `StreamGroup` is constructed using [StreamGroup.broadcast],
/// [stream] will be a broadcast stream. In this case, the streams in the group
/// will never be paused and single-subscription streams in the group will never
/// be canceled. **Note that single-subscription streams in a broadcast group
/// may drop events if a listener is added and later removed.** Broadcast
/// streams in the group will be canceled once [stream] has no listeners, and
/// will be listened to again once [stream] has listeners.
///
/// [stream] won't close until [close] is called on the group *and* every stream
/// in the group closes.
class StreamGroup<T> implements Sink<Stream<T>> {
  /// The stream through which all events from streams in the group are emitted.
  Stream<T> get stream => _controller.stream;
  late StreamController<T> _controller;

  /// Whether the group is closed, meaning that no more streams may be added.
  bool get isClosed => _closed;

  var _closed = false;

  /// The current state of the group.
  ///
  /// See [_StreamGroupState] for detailed descriptions of each state.
  var _state = _StreamGroupState.dormant;

  /// Whether this group contains no streams.
  ///
  /// A [StreamGroup] is idle when it contains no streams, which is the case for
  /// a newly created group or one where all added streams have been emitted
  /// done events (or been [remove]d).
  ///
  /// If this is a single-subscription group, then cancelling the subscription
  /// to [stream] will also remove all streams.
  bool get isIdle => _subscriptions.isEmpty;

  /// A broadcast stream that emits an event whenever this group becomes idle.
  ///
  /// A [StreamGroup] is idle when it contains no streams, which is the case for
  /// a newly created group or one where all added streams have been emitted
  /// done events (or been [remove]d).
  ///
  /// This stream will close when either:
  ///
  /// * This group is idle *and* [close] has been called, or
  /// * [stream]'s subscription has been cancelled (if this is a
  ///   single-subscription group).
  ///
  /// Note that:
  ///
  /// * Events won't be emitted on this stream until [stream] has been listened
  ///   to.
  /// * Events are delivered asynchronously, so it's possible for the group to
  ///   become active again before the event is delivered.
  Stream<void> get onIdle =>
      (_onIdleController ??= StreamController.broadcast()).stream;

  StreamController<void>? _onIdleController;

  /// Streams that have been added to the group, and their subscriptions if they
  /// have been subscribed to.
  ///
  /// The subscriptions will be null until the group has a listener registered.
  /// If it's a broadcast group and it goes dormant again, broadcast stream
  /// subscriptions will be canceled and set to null again. Single-subscriber
  /// stream subscriptions will be left intact, since they can't be
  /// re-subscribed.
  final _subscriptions = <Stream<T>, StreamSubscription<T>?>{};

  /// Merges the events from [streams] into a single single-subscription stream.
  ///
  /// This is equivalent to adding [streams] to a group, closing that group, and
  /// returning its stream.
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) {
    var group = StreamGroup<T>();
    streams.forEach(group.add);
    group.close();
    return group.stream;
  }

  /// Merges the events from [streams] into a single broadcast stream.
  ///
  /// This is equivalent to adding [streams] to a broadcast group, closing that
  /// group, and returning its stream.
  static Stream<T> mergeBroadcast<T>(Iterable<Stream<T>> streams) {
    var group = StreamGroup<T>.broadcast();
    streams.forEach(group.add);
    group.close();
    return group.stream;
  }

  /// Creates a new stream group where [stream] is single-subscriber.
  StreamGroup() {
    _controller = StreamController<T>(
        onListen: _onListen,
        onPause: _onPause,
        onResume: _onResume,
        onCancel: _onCancel,
        sync: true);
  }

  /// Creates a new stream group where [stream] is a broadcast stream.
  StreamGroup.broadcast() {
    _controller = StreamController<T>.broadcast(
        onListen: _onListen, onCancel: _onCancelBroadcast, sync: true);
  }

  /// Adds [stream] as a member of this group.
  ///
  /// Any events from [stream] will be emitted through [this.stream]. If this
  /// group has a listener, [stream] will be listened to immediately; otherwise
  /// it will only be listened to once this group gets a listener.
  ///
  /// If this is a single-subscription group and its subscription has been
  /// canceled, [stream] will be canceled as soon as its added. If this returns
  /// a [Future], it will be returned from [add]. Otherwise, [add] returns
  /// `null`.
  ///
  /// Throws a [StateError] if this group is closed.
  @override
  Future<void>? add(Stream<T> stream) {
    if (_closed) {
      throw StateError("Can't add a Stream to a closed StreamGroup.");
    }

    if (_state == _StreamGroupState.dormant) {
      _subscriptions.putIfAbsent(stream, () => null);
    } else if (_state == _StreamGroupState.canceled) {
      // Listen to the stream and cancel it immediately so that no one else can
      // listen, for consistency. If the stream has an onCancel listener this
      // will also fire that, which may help it clean up resources.
      return stream.listen(null).cancel();
    } else {
      _subscriptions.putIfAbsent(stream, () => _listenToStream(stream));
    }

    return null;
  }

  /// Removes [stream] as a member of this group.
  ///
  /// No further events from [stream] will be emitted through this group. If
  /// [stream] has been listened to, its subscription will be canceled.
  ///
  /// If [stream] has been listened to, this *synchronously* cancels its
  /// subscription. This means that any events from [stream] that haven't yet
  /// been emitted through this group will not be.
  ///
  /// If [stream]'s subscription is canceled, this returns
  /// [StreamSubscription.cancel]'s return value. Otherwise, it returns `null`.
  Future<void>? remove(Stream<T> stream) {
    var subscription = _subscriptions.remove(stream);
    var future = subscription?.cancel();

    if (_subscriptions.isEmpty) {
      _onIdleController?.add(null);
      if (_closed) {
        _onIdleController?.close();
        scheduleMicrotask(_controller.close);
      }
    }

    return future;
  }

  /// A callback called when [stream] is listened to.
  ///
  /// This is called for both single-subscription and broadcast groups.
  void _onListen() {
    _state = _StreamGroupState.listening;

    for (var entry in [..._subscriptions.entries]) {
      // If this is a broadcast group and this isn't the first time it's been
      // listened to, there may still be some subscriptions to
      // single-subscription streams.
      if (entry.value != null) continue;

      var stream = entry.key;
      try {
        _subscriptions[stream] = _listenToStream(stream);
      } catch (error) {
        // If [Stream.listen] throws a synchronous error (for example because
        // the stream has already been listened to), cancel all subscriptions
        // and rethrow the error.
        _onCancel()?.catchError((_) {});
        rethrow;
      }
    }
  }

  /// A callback called when [stream] is paused.
  void _onPause() {
    _state = _StreamGroupState.paused;
    for (var subscription in _subscriptions.values) {
      subscription!.pause();
    }
  }

  /// A callback called when [stream] is resumed.
  void _onResume() {
    _state = _StreamGroupState.listening;
    for (var subscription in _subscriptions.values) {
      subscription!.resume();
    }
  }

  /// A callback called when [stream] is canceled.
  ///
  /// This is only called for single-subscription groups.
  Future<void>? _onCancel() {
    _state = _StreamGroupState.canceled;

    var futures = _subscriptions.entries
        .map((entry) {
          var subscription = entry.value;
          try {
            if (subscription != null) return subscription.cancel();
            return entry.key.listen(null).cancel();
          } catch (_) {
            return null;
          }
        })
        .whereNotNull()
        .toList();

    _subscriptions.clear();

    var onIdleController = _onIdleController;
    if (onIdleController != null && !onIdleController.isClosed) {
      onIdleController.add(null);
      onIdleController.close();
    }

    return futures.isEmpty ? null : Future.wait(futures);
  }

  /// A callback called when [stream]'s last listener is canceled.
  ///
  /// This is only called for broadcast groups.
  void _onCancelBroadcast() {
    _state = _StreamGroupState.dormant;

    _subscriptions.forEach((stream, subscription) {
      // Cancel the broadcast streams, since we can re-listen to those later,
      // but allow the single-subscription streams to keep firing. Their events
      // will still be added to [_controller], but then they'll be dropped since
      // it has no listeners.
      if (!stream.isBroadcast) return;
      subscription!.cancel();
      _subscriptions[stream] = null;
    });
  }

  /// Starts actively forwarding events from [stream] to [_controller].
  ///
  /// This will pause the resulting subscription if `this` is paused.
  StreamSubscription<T> _listenToStream(Stream<T> stream) {
    var subscription = stream.listen(_controller.add,
        onError: _controller.addError, onDone: () => remove(stream));
    if (_state == _StreamGroupState.paused) subscription.pause();
    return subscription;
  }

  /// Closes the group, indicating that no more streams will be added.
  ///
  /// If there are no streams in the group, [stream] is closed immediately.
  /// Otherwise, [stream] will close once all streams in the group close.
  ///
  /// Returns a [Future] that completes once [stream] has actually been closed.
  @override
  Future<void> close() {
    if (_closed) return _controller.done;

    _closed = true;
    if (_subscriptions.isEmpty) _controller.close();

    return _controller.done;
  }
}

/// An enum of possible states of a [StreamGroup].
class _StreamGroupState {
  /// The group has no listeners.
  ///
  /// New streams added to the group will be listened once the group has a
  /// listener.
  static const dormant = _StreamGroupState('dormant');

  /// The group has one or more listeners and is actively firing events.
  ///
  /// New streams added to the group will be immediately listeners.
  static const listening = _StreamGroupState('listening');

  /// The group is paused and no more events will be fired until it resumes.
  ///
  /// New streams added to the group will be listened to, but then paused. They
  /// will be resumed once the group itself is resumed.
  ///
  /// This state is only used by single-subscriber groups.
  static const paused = _StreamGroupState('paused');

  /// The group is canceled and no more events will be fired ever.
  ///
  /// New streams added to the group will be listened to, canceled, and
  /// discarded.
  ///
  /// This state is only used by single-subscriber groups.
  static const canceled = _StreamGroupState('canceled');

  /// The name of the state.
  ///
  /// Used for debugging.
  final String name;

  const _StreamGroupState(this.name);

  @override
  String toString() => name;
}
