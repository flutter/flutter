// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Widgets that handle interaction with asynchronous computations.
///
/// Asynchronous computations are represented by [Future]s and [Stream]s.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show required;
import 'dart:async' show Future, Stream, StreamSubscription;

/// Base class for widgets that build themselves based on interaction with
/// a specified [Stream].
///
/// A [StreamBuilderBase] is stateful and maintains a summary of the interaction
/// so far. The type of the summary and how it is updated with each interaction
/// is defined by sub-classes.
///
/// Examples of summaries include:
///
/// * the running average of a stream of integers;
/// * the current direction and speed based on a stream of geolocation data;
/// * a graph displaying data points from a stream.
///
/// In general, the summary is the result of a fold computation over the data
/// items and errors received from the stream along with pseudo-events
/// representing termination or change of stream. The initial summary is
/// specified by sub-classes by overriding [initial]. The summary updates on
/// receipt of stream data and errors are specified by overriding [afterData] and
/// [afterError], respectively. If needed, the summary may be updated on stream
/// termination by overriding [afterDone]. Finally, the summary may be updated
/// on change of stream by overriding [afterConnected] and [afterConnected].
///
/// [T] is the type of stream events.
/// [S] is the type of interaction summary.
///
/// See also:
///
///  * [StreamBuilder], which is specialized to the case where only the most
///  recent interaction is needed for widget building.
abstract class StreamBuilderBase<T, S> extends StatefulWidget {
  /// Creates a [StreamBuilderBase] connected to the specified [stream].
  StreamBuilderBase({ Key key, this.stream }) : super(key: key);

  /// The asynchronous computation to which this builder is currently connected,
  /// possibly `null`. When changed, the current summary is updated using
  /// [afterDisconnecting], if the previous stream was not `null`, followed by
  /// [afterConnecting], if the new stream is not `null`.
  final Stream<T> stream;

  /// Returns the initial summary of stream interaction, typically representing
  /// the fact that no interaction has happened at all.
  ///
  /// Sub-classes must override this method to provide the initial value for
  /// the fold computation.
  S initial();

  /// Returns an updated version of the [current] summary reflecting that we
  /// are now connected to a stream.
  ///
  /// The default implementation returns [current] as is.
  S afterConnected(S current) => current;

  /// Returns an updated version of the [current] summary following a data event.
  ///
  /// Sub-classes must override this method to specify how the current summary
  /// is combined with the new data item in the fold computation.
  S afterData(S current, T data);

  /// Returns an updated version of the [current] summary following an error.
  ///
  /// The default implementation returns [current] as is.
  S afterError(S current, Object error) => current;

  /// Returns an updated version of the [current] summary following stream
  /// termination.
  ///
  /// The default implementation returns [current] as is.
  S afterDone(S current) => current;

  /// Returns an updated version of the [current] summary reflecting that we
  /// are no longer connected to a stream.
  ///
  /// The default implementation returns [current] as is.
  S afterDisconnected(S current) => current;

  /// Returns a Widget based on the [currentSummary].
  Widget build(BuildContext context, S currentSummary);

  @override
  State<StreamBuilderBase<T, S>> createState() => new _StreamBuilderBaseState<T, S>();
}

/// State for [StreamBuilderBase].
class _StreamBuilderBaseState<T, S> extends State<StreamBuilderBase<T, S>> {
  StreamSubscription<T> _subscription;
  S _summary;

  @override
  void initState() {
    super.initState();
    _summary = config.initial();
    _subscribe();
  }

  @override
  void didUpdateConfig(StreamBuilderBase<T, S> oldConfig) {
    if (oldConfig.stream != config.stream) {
      if (_subscription != null) {
        _unsubscribe();
        _summary = config.afterDisconnected(_summary);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => config.build(context, _summary);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (config.stream != null) {
      _subscription = config.stream.listen((T data) {
        setState(() {
          _summary = config.afterData(_summary, data);
        });
      }, onError: (Object error) {
        setState(() {
          _summary = config.afterError(_summary, error);
        });
      }, onDone: () {
        setState(() {
          _summary = config.afterDone(_summary);
        });
      });
      _summary = config.afterConnected(_summary);
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }
}

/// The state of connection to an asynchronous computation.
///
/// See also:
///
/// * [AsyncSnapshot]
enum ConnectionState {
  /// Not currently connected to any asynchronous computation.
  none,

  /// Connected to an asynchronous computation and awaiting interaction.
  waiting,

  /// Connected to an active asynchronous computation.
  active,

  /// Connected to a terminated asynchronous computation.
  done
}

/// Snapshot of an asynchronous interaction.
///
/// Used by widget builders that depend only on the most recent interaction with
/// an asynchronous computation.
///
/// See also:
///
/// * [StreamBuilder]
/// * [FutureBuilder]
class AsyncSnapshot<T> {
  /// Creates an [AsyncSnapshot] with the specified [connectionState],
  /// and optionally either [data] or [error] (but not both).
  AsyncSnapshot(this.connectionState, this.data, this.error) {
    assert(connectionState != null);
    assert(data == null || error == null);
  }

  /// Creates an [AsyncSnapshot] in [ConnectionState.none] with `null` data and
  /// `error`.
  factory AsyncSnapshot.nothing() => new AsyncSnapshot<T>(ConnectionState.none, null, null);

  /// Creates an [AsyncSnapshot] in [ConnectionState.active] with the specified
  /// [data].
  factory AsyncSnapshot.activeData(T data) => new AsyncSnapshot<T>(ConnectionState.active, data, null);

  /// Creates an [AsyncSnapshot] in [ConnectionState.active] with the specified
  /// [error].
  factory AsyncSnapshot.activeError(Object error) => new AsyncSnapshot<T>(ConnectionState.active, null, error);

  /// Current state of connection to the asynchronous computation.
  final ConnectionState connectionState;

  /// Latest data received. Is null, if [error] is not.
  final T data;

  /// Latest error object received. Is null, if [data] is not.
  final Object error;

  /// Returns a snapshot like this one, but in the specified [state].
  AsyncSnapshot<T> inState(ConnectionState state) => new AsyncSnapshot<T>(state, data, error);

  /// Returns whether this snapshot contains a non-null data value.
  bool get hasData => data != null;

  /// Returns whether this snapshot contains a non-null error value.
  bool get hasError => error != null;

  @override
  String toString() => 'AsyncSnapshot($connectionState, $data, $error)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! AsyncSnapshot<T>)
      return false;
    final AsyncSnapshot<T> typedOther = other;
    return connectionState == typedOther.connectionState &&
      data == typedOther.data &&
      error == typedOther.error;
  }

  @override
  int get hashCode => hashValues(connectionState, data, error);
}

/// Signature for strategies that build widgets based on asynchronous
/// interaction.
///
/// See also:
///
/// * [StreamBuilder]
/// * [FutureBuilder]
typedef Widget AsyncWidgetBuilder<T>(BuildContext context, AsyncSnapshot<T> snapshot);

/// Widget that builds itself based on the latest snapshot of interaction with
/// a [Stream].
///
/// Widget rebuilding is scheduled by each interaction, using [State.setState],
/// but is otherwise decoupled from the timing of the stream. The [build] method
/// is called at the discretion of the Flutter pipeline, and will thus receive a
/// timing-dependent sub-sequence of the snapshots that represent the
/// interaction with the stream
///
/// As an example, when interacting with a stream producing the integers
/// 0 through 9, the [build] method may be called with any ordered sub-sequence
/// of the following snapshots that includes the last one (the one with
/// ConnectionState.done):
///
/// * `new AsyncSnapshot<int>(ConnectionState.waiting, null, null)`
/// * `new AsyncSnapshot<int>(ConnectionState.active, 0, null)`
/// * `new AsyncSnapshot<int>(ConnectionState.active, 1, null)`
/// * ...
/// * `new AsyncSnapshot<int>(ConnectionState.active, 9, null)`
/// * `new AsyncSnapshot<int>(ConnectionState.done, 9, null)`
///
/// The actual sequence of invocations of [build] depends on the relative timing
/// of events produced by the stream and the build rate of the Flutter pipeline.
///
/// Changing the [StreamBuilder] configuration to another [Stream] during event
/// generation introduces snapshot pairs of the form
///
/// * `new AsyncSnapshot<int>(ConnectionState.none, 5, null)`
/// * `new AsyncSnapshot<int>(ConnectionState.waiting, 5, null)`
///
/// The latter will be produced only when the new stream is non-null. The former
/// only when the old stream is non-null.
///
/// The stream may produce errors, resulting in snapshots of the form
///
/// * `new AsyncSnapshot<int>(ConnectionState.active, null, 'some error')`
///
/// The data and error fields of snapshots produced are only changed when the
/// state is `ConnectionState.active`.
///
/// See also:
///
/// * [StreamBuilderBase], which supports widget building based on a computation
/// that spans all interactions made with the stream.
class StreamBuilder<T> extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  /// Creates a new [StreamBuilder] that builds itself based on the latest
  /// snapshot of interaction with the specified [stream] and whose build
  /// strategy is given by [builder].
  StreamBuilder({
    Key key,
    Stream<T> stream,
    @required this.builder
  }) : super(key: key, stream: stream) {
    assert(builder != null);
  }

  /// The build strategy currently used by this builder. Cannot be `null`.
  final AsyncWidgetBuilder<T> builder;

  @override
  AsyncSnapshot<T> initial() => new AsyncSnapshot<T>.nothing();

  @override
  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) => current.inState(ConnectionState.waiting);

  @override
  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) => new AsyncSnapshot<T>.activeData(data);

  @override
  AsyncSnapshot<T> afterError(AsyncSnapshot<T> current, Object error) => new AsyncSnapshot<T>.activeError(error);

  @override
  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) => current.inState(ConnectionState.done);

  @override
  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) => current.inState(ConnectionState.none);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) => builder(context, currentSummary);
}

/// Widget that builds itself based on the latest snapshot of interaction with
/// a [Future].
///
/// Behaves identically to [StreamBuilder] configured with `future?.asStream()`.
class FutureBuilder<T> extends StatefulWidget {
  FutureBuilder({
    Key key,
    this.future,
    @required this.builder
  }) : super(key: key) {
    assert(builder != null);
  }

  /// The asynchronous computation to which this builder is currently connected,
  /// possibly `null`.
  final Future<T> future;

  /// The build strategy currently used by this builder. Cannot be `null`.
  final AsyncWidgetBuilder<T> builder;

  @override
  State<FutureBuilder<T>> createState() => new _FutureBuilderState<T>();
}

/// State for [FutureBuilder].
class _FutureBuilderState<T> extends State<FutureBuilder<T>> {
  Stream<T> _stream;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateConfig(FutureBuilder<T> oldConfig) {
    if (oldConfig.future != config.future) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => new StreamBuilder<T>(stream: _stream, builder: config.builder);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _stream = config.future?.asStream();
  }

  void _unsubscribe() {
    _stream = null;
  }
}
