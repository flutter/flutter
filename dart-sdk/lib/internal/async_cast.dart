// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

// Casting wrappers for asynchronous classes.

class CastStream<S, T> extends Stream<T> {
  final Stream<S> _source;
  CastStream(this._source);
  bool get isBroadcast => _source.isBroadcast;

  StreamSubscription<T> listen(void Function(T data)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return new CastStreamSubscription<S, T>(
        _source.listen(null, onDone: onDone, cancelOnError: cancelOnError))
      ..onData(onData)
      ..onError(onError);
  }

  Stream<R> cast<R>() => new CastStream<S, R>(_source);
}

class CastStreamSubscription<S, T> implements StreamSubscription<T> {
  final StreamSubscription<S> _source;

  /// Zone where listen was called.
  final Zone _zone = Zone.current;

  /// User's data handler.
  void Function(T)? _handleData;

  /// Copy of _source's handleError so we can report errors in onData.
  Function? _handleError;

  CastStreamSubscription(this._source) {
    _source.onData(_onData);
  }

  Future cancel() => _source.cancel();

  void onData(void Function(T data)? handleData) {
    _handleData = handleData == null
        ? null
        : _zone.registerUnaryCallback<dynamic, T>(handleData);
  }

  void onError(Function? handleError) {
    _source.onError(handleError);
    if (handleError == null) {
      _handleError = null;
    } else if (handleError is void Function(Object, StackTrace)) {
      _handleError = _zone
          .registerBinaryCallback<dynamic, Object, StackTrace>(handleError);
    } else if (handleError is void Function(Object)) {
      _handleError = _zone.registerUnaryCallback<dynamic, Object>(handleError);
    } else {
      throw ArgumentError("handleError callback must take either an Object "
          "(the error), or both an Object (the error) and a StackTrace.");
    }
  }

  void onDone(void handleDone()?) {
    _source.onDone(handleDone);
  }

  void _onData(S data) {
    if (_handleData == null) return;
    T targetData;
    try {
      targetData = data as T;
    } catch (error, stack) {
      var handleError = _handleError;
      if (handleError == null) {
        _zone.handleUncaughtError(error, stack);
      } else if (handleError is void Function(Object, StackTrace)) {
        _zone.runBinaryGuarded<Object, StackTrace>(handleError, error, stack);
      } else {
        _zone.runUnaryGuarded<Object>(
            handleError as void Function(Object), error);
      }
      return;
    }
    _zone.runUnaryGuarded(_handleData!, targetData);
  }

  void pause([Future? resumeSignal]) {
    _source.pause(resumeSignal);
  }

  void resume() {
    _source.resume();
  }

  bool get isPaused => _source.isPaused;

  Future<E> asFuture<E>([E? futureValue]) => _source.asFuture<E>(futureValue);
}

class CastStreamTransformer<SS, ST, TS, TT>
    extends StreamTransformerBase<TS, TT> {
  final StreamTransformer<SS, ST> _source;
  CastStreamTransformer(this._source);

  StreamTransformer<RS, RT> cast<RS, RT>() =>
      new CastStreamTransformer<SS, ST, RS, RT>(_source);
  Stream<TT> bind(Stream<TS> stream) =>
      _source.bind(stream.cast<SS>()).cast<TT>();
}

class CastConverter<SS, ST, TS, TT> extends Converter<TS, TT> {
  final Converter<SS, ST> _source;
  CastConverter(this._source);

  TT convert(TS input) => _source.convert(input as SS) as TT;

  // cast is inherited from Converter.

  Stream<TT> bind(Stream<TS> stream) =>
      _source.bind(stream.cast<SS>()).cast<TT>();

  Converter<RS, RT> cast<RS, RT>() =>
      new CastConverter<SS, ST, RS, RT>(_source);
}
