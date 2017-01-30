// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Widgets that handle interaction with asynchronous computations.

import 'package:flutter/widgets.dart';
import 'dart:async' show Future, Stream, StreamSubscription;

/// Snapshot of an asynchronous interaction.
class AsyncSnapshot<T> {
  /// Current state of connection to the asynchronous computation.
  final ConnectionState connectionState;

  /// Latest data received. Is null, if [error] is not.
  final T data;

  /// Latest error object received. Is null, if [data] is not.
  final dynamic error;

  AsyncSnapshot(this.connectionState, this.data, this.error);

  bool get hasError => error != null;
  bool get hasData => data != null;

  @override
  String toString() => 'AsyncSnapshot($connectionState, $data, $error)';

  @override
  bool operator ==(dynamic o) =>
      o == this ||
      o is AsyncSnapshot<T> &&
          connectionState == o.connectionState &&
          data == o.data &&
          error == o.error;

  @override
  int get hashCode => hashValues(connectionState, data, error);
}

/// The state of connection to an asynchronous computation.
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

/// Strategy for building a Widget based on asynchronous interaction.
typedef Widget AsyncWidgetBuilder<T>(
    BuildContext context, AsyncSnapshot<T> snapshot);

/// Widget that builds itself based on interaction with the specified [future].
///
/// The building strategy is defined by the given [builder].
///
/// Behaves identically to [StreamBuilder] configured with [future].asStream()
/// when [future] is non-null.
class FutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final AsyncWidgetBuilder<T> builder;

  FutureBuilder({Key key, this.future, this.builder}) : super(key: key);

  @override
  State<FutureBuilder<T>> createState() => new _FutureBuilderState<T>();
}

class _FutureBuilderState<T> extends State<FutureBuilder<T>> {
  Stream<T> _stream;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateConfig(FutureBuilder<T> oldConfig) {
    if (!identical(oldConfig.future, config.future)) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) =>
      new StreamBuilder<T>(stream: _stream, builder: config.builder);

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

/// Widget that builds itself based on the latest snapshot of interaction with
/// the specified [stream].
///
/// The building strategy is defined by the given [builder].
class StreamBuilder<T> extends StreamFold<T, AsyncSnapshot<T>> {
  final AsyncWidgetBuilder<T> builder;

  StreamBuilder({Key key, Stream<T> stream, this.builder})
      : super(key: key, stream: stream);

  @override
  AsyncSnapshot<T> initial() =>
      new AsyncSnapshot<T>(ConnectionState.none, null, null);

  @override
  AsyncSnapshot<T> onConnecting(AsyncSnapshot<T> current) =>
      new AsyncSnapshot<T>(
          ConnectionState.waiting, current.data, current.error);

  @override
  AsyncSnapshot<T> onData(AsyncSnapshot<T> current, T data) =>
      new AsyncSnapshot<T>(ConnectionState.active, data, null);

  @override
  AsyncSnapshot<T> onError(AsyncSnapshot<T> current, dynamic error) =>
      new AsyncSnapshot<T>(ConnectionState.active, null, error);

  @override
  AsyncSnapshot<T> onDone(AsyncSnapshot<T> current) =>
      new AsyncSnapshot<T>(ConnectionState.done, current.data, current.error);

  @override
  AsyncSnapshot<T> onDisconnecting(AsyncSnapshot<T> current) =>
      new AsyncSnapshot<T>(
          ConnectionState.none, current.data, current.error);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) =>
      builder(context, currentSummary);
}

/// Base class for Widgets that build themselves based on interaction with
/// a specified [stream].
///
/// The widget's state maintains a summary of the interaction so far. The
/// summary is defined by sub-classes.
///
/// [T] type of stream events.
/// [S] type of summary.
abstract class StreamFold<T, S> extends StatefulWidget {
  final Stream<T> stream;

  StreamFold({Key key, this.stream}) : super(key: key);

  /// Returns the initial summary.
  S initial();

  /// Returns an updated version of the [current] summary reflecting that we
  /// are now connected to a stream.
  ///
  /// The default implementation returns [current] as is.
  S onConnecting(S current) => current;

  /// Returns an updated version of the [current] summary following an event.
  S onData(S current, T data);

  /// Returns an updated version of the [current] summary following an error.
  ///
  /// The default implementation returns [current] as is.
  S onError(S current, dynamic error) => current;

  /// Returns an updated version of the [current] summary following stream
  /// termination.
  ///
  /// The default implementation returns [current] as is.
  S onDone(S current) => current;

  /// Returns an updated version of the [current] summary reflecting that we
  /// are no longer connected to a stream.
  ///
  /// The default implementation returns [current] as is.
  S onDisconnecting(S current) => current;

  /// Returns a Widget based on the [currentSummary].
  Widget build(BuildContext context, S currentSummary);

  @override
  State<StreamFold<T, S>> createState() => new _StreamFoldState<T, S>();
}

class _StreamFoldState<T, S> extends State<StreamFold<T, S>> {
  StreamSubscription<T> _subscription;
  S _summary;

  @override
  void initState() {
    super.initState();
    _summary = config.initial();
    _subscribe();
  }

  @override
  void didUpdateConfig(StreamFold<T, S> oldConfig) {
    if (!identical(oldConfig.stream, config.stream)) {
      _unsubscribe();
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
      _subscription = config.stream.listen((T event) {
        setState(() {
          _summary = config.onData(_summary, event);
        });
      }, onError: (dynamic e) {
        setState(() {
          _summary = config.onError(_summary, e);
        });
      }, onDone: () {
        setState(() {
          _summary = config.onDone(_summary);
        });
      });
      _summary = config.onConnecting(_summary);
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
      _summary = config.onDisconnecting(_summary);
    }
  }
}
