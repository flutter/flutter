// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Widgets that handle interaction with asynchronous computations.
///
/// Asynchronous computations are represented by [Future]s and [Stream]s.

import 'dart:async' show Future, Stream, StreamSubscription;

import 'framework.dart';

// Examples can assume:
// dynamic _lot;
// Future<String> _calculation;

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
/// on change of stream by overriding [afterDisconnected] and [afterConnected].
///
/// `T` is the type of stream events.
///
/// `S` is the type of interaction summary.
///
/// See also:
///
///  * [StreamBuilder], which is specialized for the case where only the most
///    recent interaction is needed for widget building.
abstract class StreamBuilderBase<T, S> extends StatefulWidget {
  /// Creates a [StreamBuilderBase] connected to the specified [stream].
  const StreamBuilderBase({ Key key, this.stream }) : super(key: key);

  /// The asynchronous computation to which this builder is currently connected,
  /// possibly null. When changed, the current summary is updated using
  /// [afterDisconnected], if the previous stream was not null, followed by
  /// [afterConnected], if the new stream is not null.
  final Stream<T> stream;

  /// Returns the initial summary of stream interaction, typically representing
  /// the fact that no interaction has happened at all.
  ///
  /// Sub-classes must override this method to provide the initial value for
  /// the fold computation.
  @protected
  S initial();

  /// Returns an updated version of the [current] summary reflecting that we
  /// are now connected to a stream.
  ///
  /// The default implementation returns [current] as is.
  @protected
  S afterConnected(S current) => current;

  /// Returns an updated version of the [current] summary following a data event.
  ///
  /// Sub-classes must override this method to specify how the current summary
  /// is combined with the new data item in the fold computation.
  @protected
  S afterData(S current, T data);

  /// Returns an updated version of the [current] summary following an error.
  ///
  /// The default implementation returns [current] as is.
  @protected
  S afterError(S current, Object error) => current;

  /// Returns an updated version of the [current] summary following stream
  /// termination.
  ///
  /// The default implementation returns [current] as is.
  @protected
  S afterDone(S current) => current;

  /// Returns an updated version of the [current] summary reflecting that we
  /// are no longer connected to a stream.
  ///
  /// The default implementation returns [current] as is.
  @protected
  S afterDisconnected(S current) => current;

  /// Returns a Widget based on the [currentSummary].
  Widget build(BuildContext context, S currentSummary);

  @override
  State<StreamBuilderBase<T, S>> createState() => _StreamBuilderBaseState<T, S>();
}

/// State for [StreamBuilderBase].
class _StreamBuilderBaseState<T, S> extends State<StreamBuilderBase<T, S>> {
  StreamSubscription<T> _subscription;
  S _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.initial();
    _subscribe();
  }

  @override
  void didUpdateWidget(StreamBuilderBase<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      if (_subscription != null) {
        _unsubscribe();
        _summary = widget.afterDisconnected(_summary);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _summary);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.stream != null) {
      _subscription = widget.stream.listen((T data) {
        setState(() {
          _summary = widget.afterData(_summary, data);
        });
      }, onError: (Object error) {
        setState(() {
          _summary = widget.afterError(_summary, error);
        });
      }, onDone: () {
        setState(() {
          _summary = widget.afterDone(_summary);
        });
      });
      _summary = widget.afterConnected(_summary);
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
///  * [AsyncSnapshot], which augments a connection state with information
///    received from the asynchronous computation.
enum ConnectionState {
  /// Not currently connected to any asynchronous computation.
  ///
  /// For example, a [FutureBuilder] whose [FutureBuilder.future] is null.
  none,

  /// Connected to an asynchronous computation and awaiting interaction.
  waiting,

  /// Connected to an active asynchronous computation.
  ///
  /// For example, a [Stream] that has returned at least one value, but is not
  /// yet done.
  active,

  /// Connected to a terminated asynchronous computation.
  done,
}

/// Immutable representation of the most recent interaction with an asynchronous
/// computation.
///
/// `T` is the type of computation data.
///
/// See also:
///
///  * [StreamBuilder], which builds itself based on a snapshot from interacting
///    with a [Stream].
///  * [FutureBuilder], which builds itself based on a snapshot from interacting
///    with a [Future].
@immutable
class AsyncSnapshot<T> {
  /// Creates an [AsyncSnapshot] with the specified [connectionState] and
  /// [hasData], and optionally either [data] or [error] (but not both).
  ///
  /// It is legal for both [hasData] to be true and [data] to be null.
  const AsyncSnapshot._(this.connectionState, this.hasData, this._data, this.error)
    : assert(connectionState != null),
      assert(hasData != null),
      assert(hasData || _data == null),
      assert(!(hasData && error != null));

  /// Creates an [AsyncSnapshot] in the specified [state] and with neither
  /// [data] nor [error].
  const AsyncSnapshot.withoutData(ConnectionState state) : this._(state, false, null, null);

  /// Creates an [AsyncSnapshot] in the specified [state] and with the
  /// specified [data] (possibly null).
  const AsyncSnapshot.withData(ConnectionState state, T data) : this._(state, true, data, null);

  /// Creates an [AsyncSnapshot] in the specified `state` and with the
  /// specified [error].
  const AsyncSnapshot.withError(ConnectionState state, Object error) : this._(state, false, null, error);

  /// The current state of the connection to the asynchronous computation.
  ///
  /// This property exists independently of the [data] and [error] properties.
  /// In other words, a snapshot can exist with any combination of
  /// (`connectionState`/`data`) or (`connectionState`/`error`) tuples.
  ///
  /// This is guaranteed to be non-null.
  final ConnectionState connectionState;

  /// Whether this snapshot contains [data].
  ///
  /// This can be false even when the asynchronous computation has completed
  /// successfully ([connectionState] is [ConnectionState.done]), if the
  /// computation did not return a value. For example, a [Future<void>] will
  /// complete with no data even if it completes successfully.
  ///
  /// If this property is false, then attempting to access the [data] property
  /// will throw an exception.
  final bool hasData;

  /// The latest data received by the asynchronous computation, failing if
  /// there is no data.
  ///
  /// If [hasData] is true, accessing this property will not throw an error.
  ///
  /// If [error] is not null, attempting to access this property will throw
  /// [error]. See [hasError].
  ///
  /// If neither [hasData] nor [hasError] is true, then accessing this
  /// property will throw a [StateError].
  T get data {
    if (hasData)
      return _data;
    if (hasError) {
      // TODO(tvolkert): preserve the stack trace (https://github.com/dart-lang/sdk/issues/30741)
      throw error;
    }
    throw StateError('Snapshot has neither data nor error');
  }
  final T _data;

  /// The latest error object received by the asynchronous computation.
  ///
  /// If this is non-null, [hasError] will be true.
  ///
  /// If [data] is not null, this will be null.
  final Object error;

  /// Returns a snapshot like this one, but in the specified [state].
  ///
  /// The [hasData], [data], [hasError], and [error] fields persist unmodified,
  /// even if the new state is [ConnectionState.none].
  AsyncSnapshot<T> inState(ConnectionState state) => AsyncSnapshot<T>._(state, hasData, _data, error);

  /// Returns whether this snapshot contains a non-null [error] value.
  ///
  /// This is always true if the asynchronous computation's last result was
  /// failure.
  ///
  /// When this is true, [hasData] will always be false.
  bool get hasError => error != null;

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer()..write('$runtimeType')
        ..write('(')
        ..write('$connectionState');
    if (hasData)
      buffer.write(', data: $_data');
    else if (hasError)
      buffer.write(', error: $error');
    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final AsyncSnapshot<T> typedOther = other;
    return connectionState == typedOther.connectionState
        && hasData == typedOther.hasData
        && _data == typedOther._data
        && error == typedOther.error;
  }

  @override
  int get hashCode => hashValues(connectionState, hasData, _data, error);
}

/// Signature for strategies that build widgets based on asynchronous
/// interaction.
///
/// See also:
///
///  * [StreamBuilder], which delegates to an [AsyncWidgetBuilder] to build
///    itself based on a snapshot from interacting with a [Stream].
///  * [FutureBuilder], which delegates to an [AsyncWidgetBuilder] to build
///    itself based on a snapshot from interacting with a [Future].
typedef AsyncWidgetBuilder<T> = Widget Function(BuildContext context, AsyncSnapshot<T> snapshot);

/// Widget that builds itself based on the latest snapshot of interaction with
/// a [Stream].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=MkKEWHfy99Y}
///
/// Widget rebuilding is scheduled by each interaction, using [State.setState],
/// but is otherwise decoupled from the timing of the stream. The [builder]
/// is called at the discretion of the Flutter pipeline, and will thus receive a
/// timing-dependent sub-sequence of the snapshots that represent the
/// interaction with the stream.
///
/// As an example, when interacting with a stream producing the integers
/// 0 through 9, the [builder] may be called with any ordered sub-sequence
/// of the following snapshots that includes the last one (the one with
/// ConnectionState.done):
///
/// * `AsyncSnapshot<int>.withData(ConnectionState.waiting, null)`
/// * `AsyncSnapshot<int>.withData(ConnectionState.active, 0)`
/// * `AsyncSnapshot<int>.withData(ConnectionState.active, 1)`
/// * ...
/// * `AsyncSnapshot<int>.withData(ConnectionState.active, 9)`
/// * `AsyncSnapshot<int>.withData(ConnectionState.done, 9)`
///
/// The actual sequence of invocations of the [builder] depends on the relative
/// timing of events produced by the stream and the build rate of the Flutter
/// pipeline.
///
/// Changing the [StreamBuilder] configuration to another stream during event
/// generation introduces snapshot pairs of the form:
///
/// * `new AsyncSnapshot<int>.withData(ConnectionState.none, 5)`
/// * `new AsyncSnapshot<int>.withData(ConnectionState.waiting, 5)`
///
/// The latter will be produced only when the new stream is non-null, and the
/// former only when the old stream is non-null.
///
/// The stream may produce errors, resulting in snapshots of the form:
///
/// * `AsyncSnapshot<int>.withError(ConnectionState.active, 'some error')`
///
/// The data and error fields of snapshots produced are only changed when the
/// state is `ConnectionState.active`.
///
/// The initial snapshot data can be controlled by specifying [initialData].
/// This should be used to ensure that the first frame has the expected value,
/// as the builder will always be called before the stream listener has a chance
/// to be processed. In cases where callers wish to have no initial data, the
/// [new StreamBuilder.withoutInitialData] constructor may be used. Doing so
/// may cause the first frame to have a snapshot that contains no data.
///
/// ## Void StreamBuilders
///
/// The `StreamBuilder<void>` type will produce snapshots that contain no data.
/// An example stream of snapshots would be the following:
///
/// * `AsyncSnapshot<void>.withoutData(ConnectionState.waiting)`
/// * `AsyncSnapshot<void>.withoutData(ConnectionState.active)`
/// * ...
/// * `AsyncSnapshot<void>.withoutData(ConnectionState.active)`
/// * `AsyncSnapshot<void>.withoutData(ConnectionState.done)`
///
/// {@tool sample}
///
/// This sample shows a [StreamBuilder] configuring a text label to show the
/// latest bid received for a lot in an auction. Assume the `_lot` field is
/// set by a selector elsewhere in the UI.
///
/// ```dart
/// StreamBuilder<int>(
///   stream: _lot?.bids, // a Stream<int> or null
///   initialData: 100, // initial seed value
///   builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
///     if (snapshot.hasError)
///       return Text('Error: ${snapshot.error}');
///     switch (snapshot.connectionState) {
///       case ConnectionState.none: return Text('Select lot');
///       case ConnectionState.waiting: return Text('Awaiting bids...');
///       case ConnectionState.active: return Text('\$${snapshot.data}');
///       case ConnectionState.done: return Text('\$${snapshot.data} (closed)');
///     }
///     return null; // unreachable
///   },
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ValueListenableBuilder], which wraps a [ValueListenable] instead of a
///    [Stream].
///  * [StreamBuilderBase], which supports widget building based on a computation
///    that spans all interactions made with the stream.
// TODO(ianh): remove unreachable code above once https://github.com/dart-lang/linter/issues/1139 is fixed
class StreamBuilder<T> extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  /// Creates a new [StreamBuilder] that builds itself based on the latest
  /// snapshot of interaction with the specified `stream` and whose build
  /// strategy is given by [builder].
  ///
  /// The [initialData] argument is used to create the initial snapshot. For
  /// cases where there is no initial snapshot or the initial snapshot is not
  /// yet available, callers may construct a [StreamBuilder] without an initial
  /// snapshot using [new StreamBuilder.withoutInitialData].
  ///
  /// The [builder] must not be null.
  const StreamBuilder({
    Key key,
    @required T initialData,
    Stream<T> stream,
    @required this.builder,
  }) : assert(builder != null),
       hasInitialData = true,
       _initialData = initialData,
       super(key: key, stream: stream);

  /// Creates a new [StreamBuilder] that builds itself based on the latest
  /// snapshot of interaction with the specified `stream` and whose build
  /// strategy is given by [builder].
  ///
  /// The initial snapshot will contain no data.
  ///
  /// The [builder] must not be null.
  const StreamBuilder.withoutInitialData({
    Key key,
    Stream<T> stream,
    @required this.builder,
  }) : assert(builder != null),
       hasInitialData = false,
       _initialData = null,
       super(key: key, stream: stream);

  /// The build strategy currently used by this builder.
  final AsyncWidgetBuilder<T> builder;

  /// Whether this builder's initial snapshot contains data.
  ///
  /// If this is false, then attempting to access [initialData] will throw an
  /// error.
  ///
  /// See also:
  ///
  ///  * [AsyncSnapshot.hasData], the corresponding property that will be set
  ///    in the initial snapshot.
  final bool hasInitialData;

  /// The data that will be used to create the initial snapshot.
  ///
  /// Providing this value (presumably obtained synchronously somehow when the
  /// [Stream] was created) ensures that the first frame will show useful data.
  /// Otherwise, the first frame will be built with a snapshot that contains no
  /// data, regardless of whether a value is available on the stream: since
  /// streams are asynchronous, no events from the stream can be obtained
  /// before the initial build.
  ///
  /// Some builders intentionally have no data when first built. For those
  /// cases, callers can use the [new StreamBuilder.withoutInitialData]
  /// constructor. When a builder was constructed in this way, attempting to
  /// access the [initialData] property will throw a [StateError].
  T get initialData {
    if (!hasInitialData) {
      throw StateError(
        'StreamBuilder was created without initial data, yet the initialData '
        'property was accessed. If you wish your StreamBuilder to have initial '
        'data, create it using the default constructor.',
      );
    }
    return _initialData;
  }
  final T _initialData;

  @override
  AsyncSnapshot<T> initial() {
    return hasInitialData
        ? AsyncSnapshot<T>.withData(ConnectionState.none, initialData)
        : AsyncSnapshot<T>.withoutData(ConnectionState.none);
  }

  @override
  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) => current.inState(ConnectionState.waiting);

  @override
  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) {
    return _TypeLiteral.isVoidType(T)
        ? AsyncSnapshot<T>.withoutData(ConnectionState.active)
        : AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  @override
  AsyncSnapshot<T> afterError(AsyncSnapshot<T> current, Object error) {
    return AsyncSnapshot<T>.withError(ConnectionState.active, error);
  }

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
/// The [future] must have been obtained earlier, e.g. during [State.initState],
/// [State.didUpdateConfig], or [State.didChangeDependencies]. It must not be
/// created during the [State.build] or [StatelessWidget.build] method call when
/// constructing the [FutureBuilder]. If the [future] is created at the same
/// time as the [FutureBuilder], then every time the [FutureBuilder]'s parent is
/// rebuilt, the asynchronous task will be restarted.
///
/// A general guideline is to assume that every `build` method could get called
/// every frame, and to treat omitted calls as an optimization.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ek8ZPdWj4Qo}
///
/// ## Timing
///
/// Widget rebuilding is scheduled by the completion of the future, using
/// [State.setState], but is otherwise decoupled from the timing of the future.
/// The [builder] callback is called at the discretion of the Flutter pipeline, and
/// will thus receive a timing-dependent sub-sequence of the snapshots that
/// represent the interaction with the future.
///
/// A side-effect of this is that providing a new but already-completed future
/// to a [FutureBuilder] will result in a single frame in the
/// [ConnectionState.waiting] state. This is because there is no way to
/// synchronously determine that a [Future] has already completed.
///
/// ## Builder contract
///
/// For a future that completes successfully with data, the [builder] will be
/// called with either both or only the latter of the following snapshots:
///
/// * `AsyncSnapshot<String>.withoutData(ConnectionState.waiting)`
/// * `AsyncSnapshot<String>.withData(ConnectionState.done, 'some data')`
///
/// If that same future instead completed with an error, the [builder] would be
/// called with either both or only the latter of:
///
/// * `AsyncSnapshot<String>.withoutData(ConnectionState.waiting)`
/// * `AsyncSnapshot<String>.withError(ConnectionState.done, 'some error')`
///
/// The data and error fields of the snapshot change only as the connection
/// state field transitions from `waiting` to `done`, and they will be retained
/// when changing the [FutureBuilder] configuration to another future. If the
/// old future has already completed successfully with data as above, changing
/// configuration to a new future results in snapshot pairs of the form:
///
/// * `AsyncSnapshot<String>.withData(ConnectionState.none, 'data of first future')`
/// * `AsyncSnapshot<String>.withData(ConnectionState.waiting, 'data of second future')`
///
/// In general, the latter will be produced only when the new future is
/// non-null, and the former only when the old future is non-null.
///
/// A [FutureBuilder] behaves identically to a [StreamBuilder] configured with
/// `future?.asStream()`, except that snapshots with `ConnectionState.active`
/// may appear for the latter, depending on how the stream is implemented.
///
/// ## Void futures
///
/// The `FutureBuilder<void>` type will produce snapshots that contain no data:
///
/// * `AsyncSnapshot<String>.withoutData(ConnectionState.done)`
///
/// {@tool sample}
///
/// This sample shows a [FutureBuilder] configuring a text label to show the
/// state of an asynchronous calculation returning a string. Assume the
/// `_calculation` field is set by pressing a button elsewhere in the UI.
///
/// ```dart
/// FutureBuilder<String>(
///   // A previously-obtained `Future<String>` or null.
///   //
///   // This MUST NOT be created during the call to the `build()` method that
///   // creates the `FutureBuilder`. Doing so will cause a new future to be
///   // instantiated every time `build()` is called (potentially every frame).
///   future: _calculation,
///
///   builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
///     switch (snapshot.connectionState) {
///       case ConnectionState.none:
///         return Text('Press button to start.');
///       case ConnectionState.active:
///       case ConnectionState.waiting:
///         return Text('Awaiting result...');
///       case ConnectionState.done:
///         if (snapshot.hasError)
///           return Text('Error: ${snapshot.error}');
///         return Text('Result: ${snapshot.data}');
///     }
///     return null; // unreachable
///   },
/// )
/// ```
/// {@end-tool}
// TODO(ianh): remove unreachable code above once https://github.com/dart-lang/linter/issues/1141 is fixed
class FutureBuilder<T> extends StatefulWidget {
  /// Creates a widget that builds itself based on the latest snapshot of
  /// interaction with a [Future].
  ///
  /// The [future] argument must have been obtained earlier, e.g. during
  /// [State.initState], [State.didUpdateConfig], or
  /// [State.didChangeDependencies]. It must not be created during the
  /// [State.build] or [StatelessWidget.build] method call when constructing
  /// the [FutureBuilder]. If the [future] is created at the same time as the
  /// [FutureBuilder], then every time the [FutureBuilder]'s parent is rebuilt,
  /// the asynchronous task will be restarted.
  ///
  // ignore: deprecated_member_use_from_same_package
  /// The [initialData] argument specifies the data that will be used to create
  /// the snapshots provided to [builder] until a non-null [future] has
  /// completed. This argument is deprecated and will be removed in a future
  /// stable release because snapshots that are provided to the [builder]
  /// contain an [AsyncSnapshot.connectionState] property that indicates the
  /// state of the [future]. The builder can use that connection state to
  /// provide an "initial value" when the future has not yet completed.
  ///
  /// The [builder] argument must not be null.
  const FutureBuilder({
    Key key,
    this.future,
    @Deprecated(
      'Instead of providing initialData to FutureBuilder, consider checking '
      'for ConnectionState.none or ConnectionState.waiting in your build() '
      'method to know whether the future has completed or not.',
    )
    this.initialData,  // ignore: deprecated_member_use_from_same_package
    @required this.builder,
  }) : assert(builder != null),
       super(key: key);

  /// The asynchronous computation to which this builder is currently connected,
  /// possibly null.
  ///
  /// If no future has yet completed, including in the case where [future] is
  // ignore: deprecated_member_use_from_same_package
  /// null, the snapshot provided to the [builder] will contain [initialData]
  /// if this widget was created with initial data or will contain no data if
  /// this widget was created without initial data.
  final Future<T> future;

  /// The build strategy currently used by this builder.
  ///
  /// The builder is provided with an [AsyncSnapshot] object whose
  /// [AsyncSnapshot.connectionState] property will be one of the following
  /// values:
  ///
  ///  * [ConnectionState.none]: [future] is null.
  ///
  ///    If this widget was created with initial data (deprecated), then the
  ///    [AsyncSnapshot.data] will be set to [initialData], unless a future has
  ///    previously completed, in which case the previous result persists.
  ///
  ///    If this widget was created without initial data, then the
  ///    [AsyncSnapshot.data] will be unset, and attempts to access the data
  ///    will result in an exception.
  ///
  ///  * [ConnectionState.waiting]: [future] is not null but has not yet
  ///    completed.
  ///
  ///    If this widget was created with initial data (deprecated), then the
  ///    [AsyncSnapshot.data] will be set to [initialData], unless a future has
  ///    previously completed, in which case the previous result persists.
  ///
  ///    If this widget was created without initial data, then the
  ///    [AsyncSnapshot.data] will be unset, and attempts to access the data
  ///    will result in an exception.
  ///
  ///  * [ConnectionState.done]: [future] is not null, and has completed. If the
  ///    future completed successfully, the [AsyncSnapshot.data] will be set to
  ///    the value to which the future completed. If it completed with an error,
  ///    [AsyncSnapshot.hasError] will be true and [AsyncSnapshot.error] will be
  ///    set to the error object.
  ///
  ///    In the case of [future] being a [Future<void>], the snapshot will not
  ///    contain data even if the future completed successfully.
  final AsyncWidgetBuilder<T> builder;

  /// The data that will be used to create the snapshots provided until a
  /// non-null [future] has completed.
  ///
  /// If the future completes with an error, the [AsyncSnapshot] provided to
  /// the [builder] will contain no data, regardless of [initialData]. (The
  /// error itself will be available in [AsyncSnapshot.error], and
  /// [AsyncSnapshot.hasError] will be true.)
  ///
  /// This field is deprecated and will be removed in a future stable release
  /// because snapshots that are provided to the [builder] contain an
  /// [AsyncSnapshot.connectionState] property that indicates the state of the
  /// [future]. The builder can use that connection state to provide an
  /// "initial value" when the future has not yet completed.
  @Deprecated(
    'Instead of using FutureBuilder.initialData, consider checking '
    'for ConnectionState.none or ConnectionState.waiting in your build() '
    'ConnectionState.none or ConnectionState.waiting in your build() '
    'method to know whether the future has completed or not.',
  )
  final T initialData;

  @override
  State<FutureBuilder<T>> createState() => _FutureBuilderState<T>();
}

/// State for [FutureBuilder].
class _FutureBuilderState<T> extends State<FutureBuilder<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object _activeCallbackIdentity;
  AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    // ignore: deprecated_member_use_from_same_package
    _snapshot = widget.initialData == null
        ? AsyncSnapshot<T>.withoutData(ConnectionState.none)
        // ignore: deprecated_member_use_from_same_package
        : AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData);
    _subscribe();
  }

  @override
  void didUpdateWidget(FutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.future != null) {
      final Object callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      widget.future.then<void>((T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = _TypeLiteral.isVoidType(T)
                ? AsyncSnapshot<T>.withoutData(ConnectionState.done)
                : AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error);
          });
        }
      });
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }
}

/// Class that allows callers to reference instances of [Type] that would
/// otherwise not be valid expressions.
///
/// Generic types and the `void` type are not usable as Dart expressions, so
/// the following statements are not legal and all yield compile-time errors:
///
/// ```dart
/// if (type == List<int>) print('msg');
/// if (type == void) print('msg');
/// Type type = List<int>;
/// ```
///
/// This class allows callers to get handles on such types, like so:
///
/// ```dart
/// if (type == const _TypeLiteral<List<int>>().type) print('msg');
/// if (type == const _TypeLiteral<void>().type) print('msg');
/// Type type = const _TypeLiteral<List<int>>().type;
/// ```
class _TypeLiteral<T> {
  /// Creates a new [_TypeLiteral].
  const _TypeLiteral();

  /// Returns whether the specified type represents a "void" type.
  static bool isVoidType(Type type) => type == const _TypeLiteral<void>().type;

  /// The [Type] (`T`) represented by this [_TypeLiteral].
  Type get type => T;
}
